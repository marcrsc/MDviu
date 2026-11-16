unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.Edge, Winapi.WebView2, System.IOUtils, System.JSON, Vcl.ActnList,
  Vcl.Menus, System.Actions, Vcl.StdCtrls, Vcl.ExtCtrls, System.Generics.Collections,
  Vcl.Themes, Vcl.Styles, System.StrUtils, Winapi.ShellAPI, Vcl.Buttons,
  System.NetEncoding, System.RegularExpressions;

const
  // Sufixo que marca qual arquivo de web\styles\*.css e o default (selecionado
  // ao abrir, antes de voce escolher outro na combo). So um arquivo deve ter
  // o sufixo por vez — para trocar o default, renomeie o arquivo.
  DEFAULT_STYLE_SUFFIX = '_DEF';

  // Visual dos botoes da barra superior (flat, fundo azul escuro)
  BTN_WIDTH = 72;
  BTN_GAP = 6;
  BTN_COLOR: TColor = $502814; // azul escuro (BGR), mesmo tom do icone/tema

type
  // TSpeedButton herda Color como protected — republica como public pra poder
  // pintar o fundo do botao.
  TColoredSpeedButton = class(TSpeedButton)
  public
    property Color;
  end;

  TFormMain = class(TForm)
    procedure FormCreate(Sender: TObject);
  private
    EdgeBrowser1: TEdgeBrowser;
    ActionList1: TActionList;
    ActReload: TAction;
    ActPrint: TAction;
    ActExportPdf: TAction;
    ActOpen: TAction;
    ActScrollTop: TAction;
    ActBack: TAction;
    PanelTop: TPanel;
    LblStyle: TLabel;
    ComboStyles: TComboBox;
    BtnOpen: TColoredSpeedButton;
    BtnBack: TColoredSpeedButton;
    BtnReload: TColoredSpeedButton;
    BtnScrollTop: TColoredSpeedButton;
    BtnPrint: TColoredSpeedButton;
    BtnExportPdf: TColoredSpeedButton;
    ChkNewWindow: TCheckBox;
    ChkHtml: TCheckBox;
    OpenDialog1: TOpenDialog;

    FCurrentMDPath: string;    // caminho do .md atualmente aberto
    FPendingAnchor: string;    // id de titulo pra rolar ate depois do proximo render (link "arquivo.md#secao")
    FHistory: TStringList;     // pilha de arquivos visitados, pro botao "Voltar"
    FWebFolder: string;        // pasta do .exe (lib\, styles\ moram direto nela)
    FStylesFolder: string;     // styles\ — cada arquivo .css de dentro vira uma opcao
    FCurrentStyleName: string; // nome do ARQUIVO do estilo selecionado (sem ".css", com "_DEF" se tiver)
    FStyleFileNames: TStringList; // nome de arquivo de cada item da combo, na mesma ordem/indice —
                                   // a combo mostra o nome sem "_DEF" (so estetica), o arquivo no disco mantem o sufixo

    procedure PopulateStyles;
    procedure BuildShellAndNavigate;
    procedure RenderCurrentFile(AIsBack: Boolean = False);
    function InlineLocalImages(const AMdText: string): string;
    function ImageToDataUri(const AImgPath: string): string;
    function ImageMatchEvaluator(const AMatch: TMatch): string;
    function ReadWebFile(const AFileName: string): string;
    procedure ComboStylesChange(Sender: TObject);
    procedure ChkHtmlClick(Sender: TObject);
    procedure LaunchNewMDviuWindow(const AFilePath: string);
    procedure OpenRelatedMdFile(const AHref: string);

    procedure EdgeBrowser1CreateWebViewCompleted(Sender: TCustomEdgeBrowser; AResult: HResult);
    procedure EdgeBrowser1NavigationCompleted(Sender: TCustomEdgeBrowser; IsSuccess: Boolean;
      WebErrorStatus: COREWEBVIEW2_WEB_ERROR_STATUS);
    procedure EdgeBrowser1PrintToPDFCompleted(Sender: TCustomEdgeBrowser; ErrorCode: HResult;
      IsSuccessful: Boolean);
    procedure EdgeBrowser1NewWindowRequested(Sender: TCustomEdgeBrowser;
      Args: TNewWindowRequestedEventArgs);
    procedure EdgeBrowser1WebMessageReceived(Sender: TCustomEdgeBrowser;
      Args: TWebMessageReceivedEventArgs);

    procedure ActReloadExecute(Sender: TObject);
    procedure ActPrintExecute(Sender: TObject);
    procedure ActExportPdfExecute(Sender: TObject);
    procedure ActOpenExecute(Sender: TObject);
    procedure ActScrollTopExecute(Sender: TObject);
    procedure ActBackExecute(Sender: TObject);
  public
  end;

var
  FormMain: TFormMain;

implementation

{$R *.dfm}

// Converte uma string Pascal num literal de string JS/JSON corretamente escapado
// (aspas, barras invertidas, quebras de linha, etc.) para uso dentro de ExecuteScript.
function JsStringLiteral(const S: string): string;
var
  J: TJSONString;
begin
  J := TJSONString.Create(S);
  try
    Result := J.ToJSON;
  finally
    J.Free;
  end;
end;

// Separa "arquivo.md#ancora" em "arquivo.md" (fica em APath) e "ancora" (retorno,
// sem o "#"). Sem "#" no caminho, retorna '' e deixa APath intacto. Precisa disso
// pra link tipo "[texto](outro.md#secao)" nao tentar abrir um arquivo chamado
// literalmente "outro.md#secao" (que nao existe).
function ExtractAnchor(var APath: string): string;
var
  HashPos: Integer;
begin
  HashPos := Pos('#', APath);
  if HashPos = 0 then
    Exit('');
  Result := Copy(APath, HashPos + 1, MaxInt);
  APath := Copy(APath, 1, HashPos - 1);
end;

// Cria e posiciona um botao flat da barra superior, avancando ALeft pro proximo.
procedure SetupToolbarButton(ABtn: TColoredSpeedButton; AParent: TWinControl; var ALeft: Integer;
  const ACaption: string; AClick: TNotifyEvent);
begin
  ABtn.Parent := AParent;
  ABtn.Caption := ACaption;
  ABtn.Left := ALeft;
  ABtn.Top := 4;
  ABtn.Width := BTN_WIDTH;
  ABtn.Height := 24;
  ABtn.Flat := True;
  ABtn.Color := BTN_COLOR;
  ABtn.Font.Color := clWhite;
  ABtn.StyleElements := [];
  ABtn.OnClick := AClick;
  Inc(ALeft, BTN_WIDTH + BTN_GAP);
end;

// Carrega o estilo visual VCL (OnyxBlue.vsf, ao lado do .exe) e o aplica ao
// programa inteiro. Se o arquivo nao existir ou algo falhar, segue com o
// visual padrao do Windows — nunca trava o app por causa disso.
procedure LoadAppStyle;
var
  VsfPath, StyleName: string;
begin
  VsfPath := ExtractFilePath(ParamStr(0)) + 'OnyxBlue.vsf';
  if not TFile.Exists(VsfPath) then
    Exit;
  try
    TStyleManager.LoadFromFile(VsfPath);
    for StyleName in TStyleManager.StyleNames do
      if ContainsText(StyleName, 'Onyx') then
      begin
        TStyleManager.TrySetStyle(StyleName);
        Break;
      end;
  except
    // visual e cosmetico — uma falha aqui nao pode impedir o programa de abrir
  end;
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
  LoadAppStyle;
  Caption := 'MDviu';
  FHistory := TStringList.Create;
  FStyleFileNames := TStringList.Create;

  var IconPath := ExtractFilePath(ParamStr(0)) + 'mdviu.ico';
  if TFile.Exists(IconPath) then
    Icon.LoadFromFile(IconPath);

  FWebFolder := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  FStylesFolder := FWebFolder + 'styles\';

  if ParamCount >= 1 then
    FCurrentMDPath := ParamStr(1)
  else
    FCurrentMDPath := '';
  FPendingAnchor := ExtractAnchor(FCurrentMDPath);

  // Barra superior com o seletor de estilo
  PanelTop := TPanel.Create(Self);
  PanelTop.Parent := Self;
  PanelTop.Align := alTop;
  PanelTop.Height := 32;
  PanelTop.BevelOuter := bvNone;
  PanelTop.Color := clBtnFace;

  LblStyle := TLabel.Create(Self);
  LblStyle.Parent := PanelTop;
  LblStyle.Caption := 'Estilo:';
  LblStyle.Left := 8;
  LblStyle.Top := 9;

  ComboStyles := TComboBox.Create(Self);
  ComboStyles.Parent := PanelTop;
  ComboStyles.Style := csDropDownList;
  ComboStyles.Left := 50;
  ComboStyles.Top := 5;
  ComboStyles.Width := 160;

  // 6 botoes, mesma largura, visual flat com fundo azul (TSpeedButton, por fora
  // do tema VCL — StyleElements:=[] evita que o tema repinte por cima da cor).
  var BtnLeft := 224;

  BtnOpen := TColoredSpeedButton.Create(Self);
  SetupToolbarButton(BtnOpen, PanelTop, BtnLeft, 'Abrir...', ActOpenExecute);

  BtnBack := TColoredSpeedButton.Create(Self);
  SetupToolbarButton(BtnBack, PanelTop, BtnLeft, 'Voltar', ActBackExecute);

  BtnScrollTop := TColoredSpeedButton.Create(Self);
  SetupToolbarButton(BtnScrollTop, PanelTop, BtnLeft, 'Topo', ActScrollTopExecute);

  BtnReload := TColoredSpeedButton.Create(Self);
  SetupToolbarButton(BtnReload, PanelTop, BtnLeft, 'Atualizar', ActReloadExecute);

  BtnPrint := TColoredSpeedButton.Create(Self);
  SetupToolbarButton(BtnPrint, PanelTop, BtnLeft, 'Imprimir', ActPrintExecute);

  BtnExportPdf := TColoredSpeedButton.Create(Self);
  SetupToolbarButton(BtnExportPdf, PanelTop, BtnLeft, 'Salvar PDF', ActExportPdfExecute);

  ChkNewWindow := TCheckBox.Create(Self);
  ChkNewWindow.Parent := PanelTop;
  ChkNewWindow.Caption := 'Nova janela';
  ChkNewWindow.Left := BtnLeft + 12;
  ChkNewWindow.Top := 8;
  ChkNewWindow.Width := 95;
  ChkNewWindow.Checked := False; // link p/ outro .md navega na mesma janela por padrao (use "Voltar")

  ChkHtml := TCheckBox.Create(Self);
  ChkHtml.Parent := PanelTop;
  ChkHtml.Caption := 'HTML';
  ChkHtml.Left := ChkNewWindow.Left + ChkNewWindow.Width + 6;
  ChkHtml.Top := 8;
  ChkHtml.Width := 60;
  ChkHtml.Checked := False; // HTML cru no .md desligado por padrao (seguranca); reseta a cada arquivo novo
  ChkHtml.OnClick := ChkHtmlClick;

  OpenDialog1 := TOpenDialog.Create(Self);
  OpenDialog1.Filter := 'Arquivos Markdown (*.md)|*.md|Todos os arquivos (*.*)|*.*';
  OpenDialog1.Title := 'Abrir arquivo Markdown';

  EdgeBrowser1 := TEdgeBrowser.Create(Self);
  EdgeBrowser1.Parent := Self;
  EdgeBrowser1.Align := alClient;
  EdgeBrowser1.OnCreateWebViewCompleted := EdgeBrowser1CreateWebViewCompleted;
  EdgeBrowser1.OnNavigationCompleted := EdgeBrowser1NavigationCompleted;
  EdgeBrowser1.OnPrintToPDFCompleted := EdgeBrowser1PrintToPDFCompleted;
  EdgeBrowser1.OnNewWindowRequested := EdgeBrowser1NewWindowRequested;
  EdgeBrowser1.OnWebMessageReceived := EdgeBrowser1WebMessageReceived;

  PopulateStyles;
  ComboStyles.OnChange := ComboStylesChange; // so depois de definir o ItemIndex inicial

  // Atalhos de teclado: reconhecidos pelo formulario (Form.IsShortCut), o que faz o
  // Vcl.Edge avisar o WebView2 que a tecla foi tratada por nos (em vez do navegador).
  ActionList1 := TActionList.Create(Self);

  ActReload := TAction.Create(Self);
  ActReload.ActionList := ActionList1;
  ActReload.ShortCut := VK_F5;
  ActReload.OnExecute := ActReloadExecute;

  ActPrint := TAction.Create(Self);
  ActPrint.ActionList := ActionList1;
  ActPrint.ShortCut := Vcl.Menus.ShortCut(Ord('P'), [ssCtrl]);
  ActPrint.OnExecute := ActPrintExecute;

  ActExportPdf := TAction.Create(Self);
  ActExportPdf.ActionList := ActionList1;
  ActExportPdf.ShortCut := Vcl.Menus.ShortCut(Ord('P'), [ssCtrl, ssShift]);
  ActExportPdf.OnExecute := ActExportPdfExecute;

  ActOpen := TAction.Create(Self);
  ActOpen.ActionList := ActionList1;
  ActOpen.ShortCut := Vcl.Menus.ShortCut(Ord('O'), [ssCtrl]);
  ActOpen.OnExecute := ActOpenExecute;

  ActScrollTop := TAction.Create(Self);
  ActScrollTop.ActionList := ActionList1;
  ActScrollTop.OnExecute := ActScrollTopExecute;

  ActBack := TAction.Create(Self);
  ActBack.ActionList := ActionList1;
  ActBack.ShortCut := Vcl.Menus.ShortCut(VK_BACK, [ssAlt]); // Alt+Backspace, como em navegadores
  ActBack.OnExecute := ActBackExecute;

  EdgeBrowser1.CreateWebView;
end;

// Le web\styles\*.css e preenche a combo. Cada arquivo novo colocado nessa
// pasta vira uma opcao automaticamente, sem precisar recompilar.
procedure TFormMain.PopulateStyles;
var
  Files: TArray<string>;
  FileName, ActualName, DisplayName: string;
  DefaultIndex: Integer;
begin
  ComboStyles.Items.BeginUpdate;
  try
    ComboStyles.Items.Clear;
    FStyleFileNames.Clear;
    if TDirectory.Exists(FStylesFolder) then
    begin
      Files := TDirectory.GetFiles(FStylesFolder, '*.css');
      TArray.Sort<string>(Files);
      for FileName in Files do
      begin
        ActualName := TPath.GetFileNameWithoutExtension(FileName);
        DisplayName := ActualName;
        if EndsText(DEFAULT_STYLE_SUFFIX, ActualName) then
          DisplayName := Copy(ActualName, 1, Length(ActualName) - Length(DEFAULT_STYLE_SUFFIX));

        ComboStyles.Items.Add(DisplayName);
        FStyleFileNames.Add(ActualName);
      end;
    end;
  finally
    ComboStyles.Items.EndUpdate;
  end;

  // O default e quem tem o sufixo "_DEF" no nome do ARQUIVO (ex.: "Claro_DEF"),
  // mesmo a combo ja nao mostrando mais o sufixo.
  DefaultIndex := -1;
  for var I := 0 to FStyleFileNames.Count - 1 do
    if EndsText(DEFAULT_STYLE_SUFFIX, FStyleFileNames[I]) then
    begin
      DefaultIndex := I;
      Break;
    end;
  if (DefaultIndex < 0) and (FStyleFileNames.Count > 0) then
    DefaultIndex := 0;

  if DefaultIndex >= 0 then
  begin
    ComboStyles.ItemIndex := DefaultIndex;
    FCurrentStyleName := FStyleFileNames[DefaultIndex];
  end;
end;

procedure TFormMain.ComboStylesChange(Sender: TObject);
begin
  if ComboStyles.ItemIndex < 0 then
    Exit;
  FCurrentStyleName := FStyleFileNames[ComboStyles.ItemIndex];
  RenderCurrentFile;
end;

procedure TFormMain.ChkHtmlClick(Sender: TObject);
begin
  RenderCurrentFile; // so re-renderiza o arquivo atual com o novo estado do HTML cru
end;

function TFormMain.ReadWebFile(const AFileName: string): string;
var
  FullPath: string;
begin
  FullPath := FWebFolder + AFileName;
  if TFile.Exists(FullPath) then
    Result := TFile.ReadAllText(FullPath)
  else
    Result := '';
end;

procedure TFormMain.BuildShellAndNavigate;
var
  MarkdownItJs, ScriptJs, Shell: string;
begin
  // Protecao: um "</script" literal dentro do JS embutido fecharia a tag mais cedo.
  MarkdownItJs := StringReplace(ReadWebFile('lib\markdown-it.min.js'), '</script',
    '<\/script', [rfReplaceAll, rfIgnoreCase]);
  ScriptJs := StringReplace(ReadWebFile('lib\script.js'), '</script', '<\/script',
    [rfReplaceAll, rfIgnoreCase]);

  Shell :=
    '<!DOCTYPE html>' +
    '<html lang="pt-BR"><head><meta charset="UTF-8"><title>MDviu</title>' +
    '<style id="user-style"></style>' +
    '</head><body>' +
    '<div id="content"></div>' +
    '<script>' + MarkdownItJs + '</script>' +
    '<script>' + ScriptJs + '</script>' +
    '</body></html>';

  EdgeBrowser1.NavigateToString(Shell);
end;

// Imagem com caminho relativo (![alt](foo.jpg)) nao carrega sozinha depois de
// NavigateToString — o WebView2 nao tem "pasta atual" de disco pra resolver
// contra (tentativa anterior com host virtual esbarrou na origem opaca que
// NavigateToString da a pagina, que bloqueia os pedidos de rede do host
// mapeado). Solucao mais simples e robusta: o proprio Delphi le a imagem do
// disco e embute como data: URI (base64) direto no texto do .md antes de
// mandar pro JS — nao depende de rede, CORS ou origem nenhuma.
function TFormMain.ImageToDataUri(const AImgPath: string): string;
const
  MimeExts: array[0..6] of string = ('.jpg', '.jpeg', '.png', '.gif', '.svg', '.webp', '.bmp');
  MimeTypes: array[0..6] of string = ('image/jpeg', 'image/jpeg', 'image/png', 'image/gif',
    'image/svg+xml', 'image/webp', 'image/bmp');
var
  Decoded, FullPath, Ext, Mime: string;
  Bytes: TBytes;
  I, MimeIndex: Integer;
  Encoder: TBase64Encoding;
begin
  Result := '';
  Decoded := TNetEncoding.URL.Decode(AImgPath);

  if TPath.IsPathRooted(Decoded) then
    FullPath := Decoded
  else
    FullPath := TPath.GetFullPath(TPath.Combine(ExtractFilePath(FCurrentMDPath), Decoded));

  if not TFile.Exists(FullPath) then
    Exit;

  Ext := LowerCase(ExtractFileExt(FullPath));
  MimeIndex := -1;
  for I := Low(MimeExts) to High(MimeExts) do
    if MimeExts[I] = Ext then
    begin
      MimeIndex := I;
      Break;
    end;
  if MimeIndex < 0 then
    Exit; // extensao desconhecida — deixa o <img> como estava (vai so nao carregar)

  Mime := MimeTypes[MimeIndex];
  Bytes := TFile.ReadAllBytes(FullPath);

  // TNetEncoding.Base64 default quebra linha a cada 76 chars (estilo MIME) —
  // isso dentro de "data:...;base64,XXX" quebraria a sintaxe do markdown-it
  // (destino de link/imagem nao pode ter quebra de linha). CharsPerLine=0 = sem quebra.
  Encoder := TBase64Encoding.Create(0);
  try
    Result := 'data:' + Mime + ';base64,' + Encoder.EncodeBytesToString(Bytes);
  finally
    Encoder.Free;
  end;
end;

function TFormMain.ImageMatchEvaluator(const AMatch: TMatch): string;
var
  UrlPart, DataUri: string;
begin
  UrlPart := AMatch.Groups[2].Value;
  // ja e absoluto (http(s)://, data:, etc.) — nao mexe
  if TRegEx.IsMatch(UrlPart, '^[a-zA-Z][a-zA-Z0-9+.-]*:') or UrlPart.StartsWith('//') then
    Exit(AMatch.Value);

  DataUri := ImageToDataUri(UrlPart);
  if DataUri = '' then
    Exit(AMatch.Value); // arquivo nao encontrado ou extensao desconhecida

  Result := AMatch.Groups[1].Value + DataUri + AMatch.Groups[3].Value;
end;

function TFormMain.InlineLocalImages(const AMdText: string): string;
begin
  Result := TRegEx.Replace(AMdText, '(!\[[^\]]*\]\()([^)\s]+)(\))', ImageMatchEvaluator);
end;

procedure TFormMain.RenderCurrentFile(AIsBack: Boolean);
var
  MdText, FileName, Css: string;
begin
  try
    // Tem que capturar a posicao de rolagem ANTES de trocar o CSS — setStyle
    // muda tamanhos/espacamentos na hora, no conteudo ainda antigo; capturar
    // depois mediria o conteudo errado (CSS novo com texto velho).
    EdgeBrowser1.ExecuteScript('prepareScrollAnchor(' + JsStringLiteral(FCurrentMDPath) + ');');

    if FCurrentStyleName <> '' then
      Css := ReadWebFile('styles\' + FCurrentStyleName + '.css')
    else
      Css := '';
    EdgeBrowser1.ExecuteScript('setStyle(' + JsStringLiteral(Css) + ');');

    if FCurrentMDPath = '' then
      Exit;

    if not TFile.Exists(FCurrentMDPath) then
    begin
      ShowMessage('Arquivo nao encontrado: ' + FCurrentMDPath);
      Exit;
    end;

    MdText := TFile.ReadAllText(FCurrentMDPath);
    MdText := InlineLocalImages(MdText);
    FileName := ExtractFileName(FCurrentMDPath);

    EdgeBrowser1.ExecuteScript('renderMD(' + JsStringLiteral(MdText) + ', ' +
      JsStringLiteral(FileName) + ', ' + IfThen(ChkHtml.Checked, 'true', 'false') + ', ' +
      JsStringLiteral(FCurrentMDPath) + ', ' + IfThen(AIsBack, 'true', 'false') + ');');

    // Link tipo "outro.md#secao": depois de renderizar o arquivo novo (que ja
    // rolou pro topo), rola ate o titulo com esse id — igual a ancora #secao
    // faz na mesma pagina, so que cruzando arquivo.
    if FPendingAnchor <> '' then
    begin
      EdgeBrowser1.ExecuteScript('var __el = document.getElementById(' +
        JsStringLiteral(FPendingAnchor) + '); if (__el) __el.scrollIntoView();');
      FPendingAnchor := '';
    end;

    Caption := 'MDviu - ' + FileName;

    // Sem isso o foco fica no ultimo controle da toolbar (ex.: combo de
    // estilo, primeiro TabStop criado) em vez do conteudo exibido.
    EdgeBrowser1.SetFocus;
  except
    on E: Exception do
      ShowMessage('Erro ao exibir o arquivo: ' + E.Message);
  end;
end;

procedure TFormMain.EdgeBrowser1CreateWebViewCompleted(Sender: TCustomEdgeBrowser;
  AResult: HResult);
begin
  if Succeeded(AResult) then
    BuildShellAndNavigate
  else
    ShowMessage('Nao foi possivel iniciar o WebView2 (erro ' + IntToHex(AResult, 8) + ').');
end;

procedure TFormMain.EdgeBrowser1NavigationCompleted(Sender: TCustomEdgeBrowser;
  IsSuccess: Boolean; WebErrorStatus: COREWEBVIEW2_WEB_ERROR_STATUS);
begin
  if IsSuccess then
    RenderCurrentFile;
end;

// Link externo (http/https, marcado com target=_blank pelo script.js) — sempre
// abre no navegador padrao do Windows, nunca dentro do MDviu.
procedure TFormMain.EdgeBrowser1NewWindowRequested(Sender: TCustomEdgeBrowser;
  Args: TNewWindowRequestedEventArgs);
var
  UriPtr: PWideChar;
  Uri: string;
begin
  Args.ArgsInterface.Get_uri(UriPtr);
  Uri := UriPtr;
  Args.ArgsInterface.Set_Handled(1);
  ShellExecute(0, 'open', PChar(Uri), nil, nil, SW_SHOWNORMAL);
end;

// Mensagens vindas do script.js (window.chrome.webview.postMessage), disparadas
// ao clicar num link interno que aponta pra OUTRO arquivo .md (nao uma ancora
// #... da mesma pagina, essa o proprio navegador ja resolve sozinho).
procedure TFormMain.EdgeBrowser1WebMessageReceived(Sender: TCustomEdgeBrowser;
  Args: TWebMessageReceivedEventArgs);
var
  MsgPtr: PWideChar;
  JsonVal: TJSONValue;
  Href: string;
begin
  if Args.ArgsInterface.TryGetWebMessageAsString(MsgPtr) <> S_OK then
    Exit;

  JsonVal := TJSONObject.ParseJSONValue(string(MsgPtr));
  if JsonVal = nil then
    Exit;
  try
    if (JsonVal is TJSONObject) and TJSONObject(JsonVal).TryGetValue<string>('href', Href) then
      OpenRelatedMdFile(Href);
  finally
    JsonVal.Free;
  end;
end;

// Resolve um link relativo pra outro .md (relativo a pasta do arquivo atual) e
// abre — na mesma janela (empilhando o atual pro "Voltar") ou numa nova janela,
// conforme a caixinha "Nova janela".
procedure TFormMain.OpenRelatedMdFile(const AHref: string);
var
  DecodedHref, TargetPath, Anchor: string;
begin
  // O markdown-it codifica a URL do link (ex.: "\" vira "%5C") — decodifica
  // antes de resolver o caminho, senao "..\arquivo.md" nao seria encontrado.
  DecodedHref := TNetEncoding.URL.Decode(AHref);

  // "outro.md#secao": a ancora tem que sair ANTES de resolver/checar o
  // arquivo, senao tenta abrir um arquivo chamado literalmente "outro.md#secao".
  Anchor := ExtractAnchor(DecodedHref);

  if FCurrentMDPath <> '' then
    TargetPath := TPath.GetFullPath(TPath.Combine(ExtractFilePath(FCurrentMDPath), DecodedHref))
  else
    TargetPath := DecodedHref;

  if not TFile.Exists(TargetPath) then
  begin
    ShowMessage('Arquivo nao encontrado: ' + TargetPath);
    Exit;
  end;

  if ChkNewWindow.Checked then
  begin
    if Anchor <> '' then
      LaunchNewMDviuWindow(TargetPath + '#' + Anchor)
    else
      LaunchNewMDviuWindow(TargetPath);
    Exit;
  end;

  FPendingAnchor := Anchor;

  if FCurrentMDPath <> '' then
    FHistory.Add(FCurrentMDPath);
  FCurrentMDPath := TargetPath;
  ChkHtml.Checked := False; // HTML cru reseta a cada arquivo novo (seguranca)
  RenderCurrentFile;
end;

// Abre outra janela do MDviu (outro processo do mesmo .exe) com o arquivo indicado.
procedure TFormMain.LaunchNewMDviuWindow(const AFilePath: string);
begin
  ShellExecute(0, 'open', PChar(ParamStr(0)), PChar('"' + AFilePath + '"'), nil, SW_SHOWNORMAL);
end;

procedure TFormMain.EdgeBrowser1PrintToPDFCompleted(Sender: TCustomEdgeBrowser;
  ErrorCode: HResult; IsSuccessful: Boolean);
begin
  if IsSuccessful then
    ShowMessage('PDF salvo em: ' + ChangeFileExt(FCurrentMDPath, '.pdf'))
  else
    ShowMessage('Falha ao gerar o PDF.');
end;

// F5 / botao "Atualizar" — rele o .md e o style.css direto do disco e manda
// tudo de novo pro WebView2 (sem recarregar a pagina: so reinjeta o conteudo).
procedure TFormMain.ActReloadExecute(Sender: TObject);
begin
  RenderCurrentFile;
end;

// Ctrl+P — abre a tela de impressao nativa do navegador (com preview), onde
// "Microsoft Print to PDF" ja aparece como impressora padrao do Windows.
procedure TFormMain.ActPrintExecute(Sender: TObject);
begin
  EdgeBrowser1.ShowPrintUI(TEdgeBrowser.TPrintUIDialogKind.Browser);
end;

// Ctrl+Shift+P — exporta direto pra PDF, sem dialogo, salvando ao lado do .md
// com o mesmo nome (so troca a extensao), mantendo cores de fundo do CSS.
procedure TFormMain.ActExportPdfExecute(Sender: TObject);
var
  Settings: ICoreWebView2PrintSettings;
  PdfPath: string;
begin
  if FCurrentMDPath = '' then
  begin
    ShowMessage('Nenhum arquivo .md aberto.');
    Exit;
  end;

  Settings := EdgeBrowser1.CreatePrintSettings;
  if Settings = nil then
  begin
    ShowMessage('Nao foi possivel criar as configuracoes de impressao.');
    Exit;
  end;

  Settings.Set_ShouldPrintBackgrounds(1);

  PdfPath := ChangeFileExt(FCurrentMDPath, '.pdf');
  EdgeBrowser1.PrintToPDF(PdfPath, Settings);
end;

// Botao "Topo" — rola o conteudo de volta pro inicio (util em arquivos com
// indice/sumario no comeco e muitas secoes).
procedure TFormMain.ActScrollTopExecute(Sender: TObject);
begin
  // behavior "smooth" depende da config de animacao do Windows (Chromium
  // respeita "reduzir movimento"/"mostrar animacoes") — sem "behavior" fica
  // sempre instantaneo, igual em qualquer maquina.
  EdgeBrowser1.ExecuteScript('window.scrollTo(0, 0);');
end;

// Botao "Voltar" / Alt+Backspace — reabre o arquivo imediatamente anterior
// (como o "voltar" de um navegador), util navegando entre varios .md ligados
// por link na mesma janela.
procedure TFormMain.ActBackExecute(Sender: TObject);
begin
  if FHistory.Count = 0 then
    Exit;
  FCurrentMDPath := FHistory[FHistory.Count - 1];
  FHistory.Delete(FHistory.Count - 1);
  ChkHtml.Checked := False; // HTML cru reseta a cada arquivo novo (seguranca)
  RenderCurrentFile(True); // "Voltar" restaura a posicao de rolagem de onde estava
end;

// Botao/Ctrl+O — abre o seletor de arquivo nativo do Windows, alternativa ao
// duplo clique (ex.: quando o MDviu ja esta aberto e voce quer trocar de arquivo).
procedure TFormMain.ActOpenExecute(Sender: TObject);
begin
  if not OpenDialog1.Execute(Handle) then
    Exit;

  if FCurrentMDPath <> '' then
    FHistory.Add(FCurrentMDPath);
  FCurrentMDPath := OpenDialog1.FileName;
  ChkHtml.Checked := False; // HTML cru reseta a cada arquivo novo (seguranca)
  RenderCurrentFile;
end;

end.
