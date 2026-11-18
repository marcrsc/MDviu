unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.Edge, Winapi.WebView2, System.IOUtils, System.JSON, Vcl.ActnList,
  Vcl.Menus, System.Actions, Vcl.StdCtrls, Vcl.ExtCtrls, System.Generics.Collections,
  System.StrUtils, Winapi.ShellAPI, Vcl.Buttons,
  System.NetEncoding, System.RegularExpressions, Vcl.Clipbrd, Winapi.ActiveX,
  Winapi.DwmApi;

const
  // Sufixo que marca qual arquivo de web\styles\*.css e o default (selecionado
  // ao abrir, antes de voce escolher outro na combo). So um arquivo deve ter
  // o sufixo por vez — para trocar o default, renomeie o arquivo.
  DEFAULT_STYLE_SUFFIX = '_DEF';

type
  TFormMain = class(TForm)
    PanelTop: TPanel;
    LblStyle: TLabel;
    ComboStyles: TComboBox;
    BtnOpen: TSpeedButton;
    BtnBack: TSpeedButton;
    BtnScrollTop: TSpeedButton;
    BtnReload: TSpeedButton;
    BtnPrint: TSpeedButton;
    BtnExportPdf: TSpeedButton;
    ChkNewWindow: TCheckBox;
    ChkHtml: TCheckBox;
    LblNewWindow: TLabel;
    LblHtml: TLabel;
    EdgeBrowser1: TEdgeBrowser;
    ActionList1: TActionList;
    ActOpen: TAction;
    ActBack: TAction;
    ActScrollTop: TAction;
    ActReload: TAction;
    ActPrint: TAction;
    ActExportPdf: TAction;
    OpenDialog1: TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ComboStylesChange(Sender: TObject);
    procedure ChkHtmlClick(Sender: TObject);
    procedure LblCheckClick(Sender: TObject);
    procedure EdgeBrowser1CreateWebViewCompleted(Sender: TCustomEdgeBrowser; AResult: HResult);
    procedure EdgeBrowser1NavigationCompleted(Sender: TCustomEdgeBrowser; IsSuccess: Boolean;
      WebErrorStatus: COREWEBVIEW2_WEB_ERROR_STATUS);
    procedure EdgeBrowser1PrintToPDFCompleted(Sender: TCustomEdgeBrowser; ErrorCode: HResult;
      IsSuccessful: Boolean);
    procedure EdgeBrowser1NewWindowRequested(Sender: TCustomEdgeBrowser;
      Args: TNewWindowRequestedEventArgs);
    procedure EdgeBrowser1WebMessageReceived(Sender: TCustomEdgeBrowser;
      Args: TWebMessageReceivedEventArgs);
    procedure ActOpenExecute(Sender: TObject);
    procedure ActBackExecute(Sender: TObject);
    procedure ActScrollTopExecute(Sender: TObject);
    procedure ActReloadExecute(Sender: TObject);
    procedure ActPrintExecute(Sender: TObject);
    procedure ActExportPdfExecute(Sender: TObject);
  private
    FCurrentMDPath: string;    // caminho do .md atualmente aberto
    FPendingAnchor: string;    // id de titulo pra rolar ate depois do proximo render (link "arquivo.md#secao")
    FHistory: TStringList;     // pilha de arquivos visitados, pro botao "Voltar"
    FWebFolder: string;        // pasta do .exe (lib\, styles\ moram direto nela)
    FStylesFolder: string;     // styles\ — cada arquivo .css de dentro vira uma opcao
    FCurrentStyleName: string; // nome do ARQUIVO do estilo selecionado (sem ".css", com "_DEF" se tiver)
    FPdfPath: string;          // PDF sendo gerado pelo "Salvar PDF" (pra mensagem de conclusao)
    FWindowRevealed: Boolean;  // janela ja revelada (ver CreateWnd) — se o VCL recriar a janela depois, nao encobre de novo
    FStyleFileNames: TStringList; // nome de arquivo de cada item da combo, na mesma ordem/indice —
                                   // a combo mostra o nome sem "_DEF" (so estetica), o arquivo no disco mantem o sufixo

    procedure PopulateStyles;
    procedure BuildShellAndNavigate;
    procedure RenderCurrentFile(AIsBack: Boolean = False);
    function InlineLocalImages(const AMdText: string): string;
    function ImageToDataUri(const AImgPath: string): string;
    function ImageMatchEvaluator(const AMatch: TMatch): string;
    function ReadWebFile(const AFileName: string): string;
    procedure LaunchNewMDviuWindow(const AFilePath: string);
    procedure OpenRelatedMdFile(const AHref: string);
    procedure OpenFile(const APath: string);
    procedure ApplyPageColors;
    function DroppedFilePath(Args: TWebMessageReceivedEventArgs): string;
    procedure WMRevealWindow(var Msg: TMessage); message WM_APP + 1;
  protected
    procedure CreateWnd; override;
    procedure DoShow; override;
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

// Extensao (com ponto, ex. ".pas") -> nome de linguagem que o highlight.js
// reconhece (ver lib\highlight.min.js e MDviu.md). Vazio = nao e arquivo de
// codigo-fonte reconhecido, continua tratado como Markdown (comportamento
// de sempre). Usado tanto no botao "Abrir..." quanto em link local clicado
// dentro de um .md (ambos passam por RenderCurrentFile).
// Ao incluir extensao aqui, incluir tambem no filtro "Codigo-fonte e texto"
// do OpenDialog1 (uMain.dfm) e na tabela de MDviu.md.
function LanguageForExtension(const AExt: string): string;
const
  // Pares (extensao, linguagem do highlight.js).
  ExtLang: array[0..41, 0..1] of string = (
    // Delphi
    ('.pas', 'delphi'), ('.dpr', 'delphi'), ('.dfm', 'delphi'), ('.dpk', 'delphi'),
    ('.inc', 'delphi'),
    // Web
    ('.html', 'html'), ('.htm', 'html'), ('.js', 'javascript'), ('.ts', 'typescript'),
    ('.css', 'css'), ('.php', 'php'), ('.asp', 'vbscript-html'),
    // Dados e configuracao
    ('.json', 'json'), ('.xml', 'xml'), ('.dproj', 'xml'), ('.groupproj', 'xml'),
    ('.config', 'xml'), ('.manifest', 'xml'), ('.svg', 'xml'), ('.xsd', 'xml'),
    ('.xsl', 'xml'), ('.yml', 'yaml'), ('.yaml', 'yaml'), ('.ini', 'ini'),
    ('.toml', 'ini'), ('.sql', 'sql'),
    // Scripts
    ('.bat', 'dos'), ('.cmd', 'dos'), ('.ps1', 'powershell'), ('.sh', 'bash'),
    ('.py', 'python'), ('.vbs', 'vbscript'),
    // Outras linguagens
    ('.vb', 'vbnet'), ('.cs', 'csharp'), ('.java', 'java'), ('.cpp', 'cpp'),
    ('.h', 'cpp'),
    // Texto sem cor (abre como bloco de codigo, nao como Markdown)
    ('.txt', 'plaintext'), ('.log', 'plaintext'), ('.csv', 'plaintext'),
    ('.diff', 'diff'), ('.patch', 'diff'));
var
  I: Integer;
begin
  Result := '';
  for I := Low(ExtLang) to High(ExtLang) do
    if ExtLang[I, 0] = AExt then
      Exit(ExtLang[I, 1]);
end;

// Le do CSS do estilo se ele e escuro (--mdviu-theme: dark) e a cor de fundo
// do body (background/background-color em #rgb ou #rrggbb). Sem cor
// declarada, usa branco ou #1e1e1e conforme o tema. Serve pra pintar o fundo
// da janela e do WebView2 com a cor do documento enquanto ele carrega (sem a
// "piscada" cinza/branca/preta na abertura).
procedure StylePageColors(const ACss: string; out AIsDark: Boolean; out AColor: TColor);
var
  M: TMatch;
  Hex: string;
begin
  AIsDark := TRegEx.IsMatch(ACss, '--mdviu-theme\s*:\s*dark', [roIgnoreCase]);
  if AIsDark then
    AColor := RGB($1E, $1E, $1E)
  else
    AColor := clWhite;

  M := TRegEx.Match(ACss,
    'body\s*\{[^}]*?background(?:-color)?\s*:\s*#([0-9a-f]{6}|[0-9a-f]{3})\b', [roIgnoreCase]);
  if not M.Success then
    Exit;
  Hex := M.Groups[1].Value;
  if Length(Hex) = 3 then
    Hex := Hex[1] + Hex[1] + Hex[2] + Hex[2] + Hex[3] + Hex[3];
  AColor := RGB(StrToInt('$' + Copy(Hex, 1, 2)), StrToInt('$' + Copy(Hex, 3, 2)),
    StrToInt('$' + Copy(Hex, 5, 2)));
end;

// Primeiro quadro sem "piscada" branca: no Windows 11 o compositor (DWM)
// mostra a janela nova em BRANCO ate o programa desenhar o primeiro quadro
// (a cor de fundo da classe da janela nao e usada nesse instante). Tecnica
// documentada pra isso: criar a janela "encoberta" (DWMWA_CLOAK) e so
// revelar depois de desenhada. CreateWnd encobre; DoShow agenda a revelacao
// (mensagem postada, processada depois do Show); WMRevealWindow forca o
// desenho da janela inteira e revela.
procedure TFormMain.CreateWnd;
var
  Cloak: BOOL;
begin
  inherited;
  if FWindowRevealed then
    Exit;
  Cloak := True;
  DwmSetWindowAttribute(Handle, DWMWA_CLOAK, @Cloak, SizeOf(Cloak));
end;

procedure TFormMain.DoShow;
begin
  inherited;
  if not FWindowRevealed then
    PostMessage(Handle, WM_APP + 1, 0, 0);
end;

procedure TFormMain.WMRevealWindow(var Msg: TMessage);
var
  Cloak: BOOL;
begin
  RedrawWindow(Handle, nil, 0, RDW_INVALIDATE or RDW_ERASE or RDW_FRAME or
    RDW_ALLCHILDREN or RDW_UPDATENOW);
  Cloak := False;
  DwmSetWindowAttribute(Handle, DWMWA_CLOAK, @Cloak, SizeOf(Cloak));
  FWindowRevealed := True;
end;

// Os componentes visuais estao todos no uMain.dfm. Estilo VCL e icone vem do
// projeto (MDviu.dproj, aplicados no MDviu.dpr/recurso), nao de arquivo solto.
procedure TFormMain.FormCreate(Sender: TObject);
var
  IsDark: Boolean;
  PageColor: TColor;
begin
  FHistory := TStringList.Create;
  FStyleFileNames := TStringList.Create;

  FWebFolder := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  FStylesFolder := FWebFolder + 'styles\';

  if ParamCount >= 1 then
    FCurrentMDPath := ParamStr(1)
  else
    FCurrentMDPath := '';
  FPendingAnchor := ExtractAnchor(FCurrentMDPath);

  // Atalhos (F5, Ctrl+P, Ctrl+Shift+P, Ctrl+O, Alt+Backspace) ficam nas
  // TAction do ActionList1, no .dfm: reconhecidos pelo formulario
  // (Form.IsShortCut), o Vcl.Edge avisa o WebView2 que a tecla foi tratada.
  PopulateStyles;

  // Abertura sem "piscada": ate o documento aparecer, tudo fica na cor de
  // fundo do estilo escolhido. (1) O TEdgeBrowser pinta o fundo com a Color
  // herdada do form (ParentColor) enquanto o WebView2 inicia; (2) a variavel
  // WEBVIEW2_DEFAULT_BACKGROUND_COLOR (AARRGGBB, lida pelo WebView2 ao ser
  // criado) evita o quadro branco inicial. O resto (cor depois de criado e
  // esquema claro/escuro) fica em ApplyPageColors.
  StylePageColors(ReadWebFile('styles\' + FCurrentStyleName + '.css'), IsDark, PageColor);
  Color := PageColor;
  SetEnvironmentVariable('WEBVIEW2_DEFAULT_BACKGROUND_COLOR',
    PChar(Format('FF%.2x%.2x%.2x', [GetRValue(PageColor), GetGValue(PageColor), GetBValue(PageColor)])));

  EdgeBrowser1.CreateWebView;
end;

// Cor de fundo do WebView2 (mostrada antes de a pagina pintar), conforme o
// estilo atual, e esquema de cor fixo em claro. Sem isso, com o Windows em
// tema escuro o Chromium mostra um fundo preto (#121212) antes do documento.
procedure TFormMain.ApplyPageColors;
var
  IsDark: Boolean;
  PageColor: TColor;
  Controller2: ICoreWebView2Controller2;
  WebView13: ICoreWebView2_13;
  Profile: ICoreWebView2Profile;
  BgColor: COREWEBVIEW2_COLOR;
begin
  StylePageColors(ReadWebFile('styles\' + FCurrentStyleName + '.css'), IsDark, PageColor);
  Color := PageColor;

  if Supports(EdgeBrowser1.ControllerInterface, ICoreWebView2Controller2, Controller2) then
  begin
    BgColor.A := 255;
    BgColor.R := GetRValue(PageColor);
    BgColor.G := GetGValue(PageColor);
    BgColor.B := GetBValue(PageColor);
    Controller2.Set_DefaultBackgroundColor(BgColor);
  end;

  // Esquema sempre CLARO, mesmo em estilo escuro: no esquema escuro o
  // Chromium pinta a pagina em branco inicial (about:blank) com o #121212
  // dele, ignorando o DefaultBackgroundColor; no claro ela fica sem fundo
  // e aparece a cor acima. As cores do documento vem do CSS do estilo
  // (nenhum usa prefers-color-scheme), entao o estilo escuro continua escuro.
  if Supports(EdgeBrowser1.DefaultInterface, ICoreWebView2_13, WebView13) and
    (WebView13.Get_Profile(Profile) = S_OK) and (Profile <> nil) then
    Profile.Set_PreferredColorScheme(COREWEBVIEW2_PREFERRED_COLOR_SCHEME_LIGHT);
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  FStyleFileNames.Free;
  FHistory.Free;
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
  ApplyPageColors;
  RenderCurrentFile;
end;

procedure TFormMain.ChkHtmlClick(Sender: TObject);
begin
  RenderCurrentFile; // so re-renderiza o arquivo atual com o novo estado do HTML cru
end;

// Os checkboxes da barra sao so a caixinha; o texto e um TLabel ao lado (com
// fonte menor, o texto do proprio TCheckBox desalinhava da caixa). Clicar no
// texto marca/desmarca a caixa, como no checkbox comum (o OnClick dela roda).
procedure TFormMain.LblCheckClick(Sender: TObject);
begin
  if Sender = LblNewWindow then
    ChkNewWindow.Checked := not ChkNewWindow.Checked
  else if Sender = LblHtml then
    ChkHtml.Checked := not ChkHtml.Checked;
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
  MarkdownItJs, HljsJs, ScriptJs, Shell: string;
  HljsLightCss, HljsDarkCss, UserCss: string;
begin
  // Protecao: um "</script" literal dentro do JS embutido fecharia a tag mais cedo.
  MarkdownItJs := StringReplace(ReadWebFile('lib\markdown-it.min.js'), '</script',
    '<\/script', [rfReplaceAll, rfIgnoreCase]);
  HljsJs := StringReplace(ReadWebFile('lib\highlight.min.js'), '</script',
    '<\/script', [rfReplaceAll, rfIgnoreCase]);
  ScriptJs := StringReplace(ReadWebFile('lib\script.js'), '</script', '<\/script',
    [rfReplaceAll, rfIgnoreCase]);
  // Mesma protecao, so que pra "</style" (tema de highlight.js, ver script.js/setStyle).
  HljsLightCss := StringReplace(ReadWebFile('lib\highlight-light.min.css'), '</style',
    '<\/style', [rfReplaceAll, rfIgnoreCase]);
  HljsDarkCss := StringReplace(ReadWebFile('lib\highlight-dark.min.css'), '</style',
    '<\/style', [rfReplaceAll, rfIgnoreCase]);
  // CSS do estilo atual ja na pagina inicial: a primeira pintura sai com o
  // fundo certo (setStyle() depois so substitui pelo mesmo conteudo).
  UserCss := StringReplace(ReadWebFile('styles\' + FCurrentStyleName + '.css'), '</style',
    '<\/style', [rfReplaceAll, rfIgnoreCase]);

  Shell :=
    '<!DOCTYPE html>' +
    '<html lang="pt-BR"><head><meta charset="UTF-8"><title>MDviu</title>' +
    '<style id="user-style">' + UserCss + '</style>' +
    '<style id="hljs-light-theme">' + HljsLightCss + '</style>' +
    '<style id="hljs-dark-theme">' + HljsDarkCss + '</style>' +
    '</head><body>' +
    '<div id="content"></div>' +
    '<script>' + MarkdownItJs + '</script>' +
    '<script>' + HljsJs + '</script>' +
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
  MdText, FileName, Css, Lang: string;
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
    FileName := ExtractFileName(FCurrentMDPath);
    // Extensao reconhecida (ver LanguageForExtension) e diferente de .md —
    // trata o arquivo inteiro como codigo-fonte (highlight.js), nao Markdown.
    // Cobre tanto o botao "Abrir..." quanto clicar num link local pra esse
    // arquivo dentro de um .md ja aberto (os dois caem aqui).
    Lang := LanguageForExtension(LowerCase(ExtractFileExt(FCurrentMDPath)));

    if Lang <> '' then
      EdgeBrowser1.ExecuteScript('renderSource(' + JsStringLiteral(MdText) + ', ' +
        JsStringLiteral(FileName) + ', ' + JsStringLiteral(FCurrentMDPath) + ', ' +
        IfThen(AIsBack, 'true', 'false') + ', ' + JsStringLiteral(Lang) + ');')
    else
    begin
      MdText := InlineLocalImages(MdText);
      EdgeBrowser1.ExecuteScript('renderMD(' + JsStringLiteral(MdText) + ', ' +
        JsStringLiteral(FileName) + ', ' + IfThen(ChkHtml.Checked, 'true', 'false') + ', ' +
        JsStringLiteral(FCurrentMDPath) + ', ' + IfThen(AIsBack, 'true', 'false') + ');');
    end;

    // Link tipo "outro.md#secao": depois de renderizar o arquivo novo (que ja
    // rolou pro topo), rola ate o titulo com esse id — igual a ancora #secao
    // faz na mesma pagina, so que cruzando arquivo.
    if FPendingAnchor <> '' then
    begin
      EdgeBrowser1.ExecuteScript('var __el = document.getElementById(' +
        JsStringLiteral(FPendingAnchor) + '); if (__el) __el.scrollIntoView();');
      FPendingAnchor := '';
    end;

    // Nome do programa e caminho completo do arquivo aberto.
    Caption := 'MDviu - ' + FCurrentMDPath;

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
  begin
    ApplyPageColors;
    BuildShellAndNavigate;
  end
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

// Mensagens vindas do script.js (window.chrome.webview.postMessage): clique
// num link interno pra outro arquivo ("href"), pedido de copiar um bloco
// de codigo pra area de transferencia ("copyText" — fallback de
// copyCodeBlock() quando navigator.clipboard falha nessa origem "opaca" do
// NavigateToString, ver comentario em lib\script.js) ou arquivo arrastado
// pra janela ("dropFile" — o arquivo vem junto como objeto adicional, ver
// DroppedFilePath).
procedure TFormMain.EdgeBrowser1WebMessageReceived(Sender: TCustomEdgeBrowser;
  Args: TWebMessageReceivedEventArgs);
var
  MsgPtr: PWideChar;
  JsonVal: TJSONValue;
  Href, CopyText, DroppedPath: string;
  IsDrop: Boolean;
begin
  if Args.ArgsInterface.TryGetWebMessageAsString(MsgPtr) <> S_OK then
    Exit;

  JsonVal := TJSONObject.ParseJSONValue(string(MsgPtr));
  if JsonVal = nil then
    Exit;
  try
    if not (JsonVal is TJSONObject) then
      Exit;
    if TJSONObject(JsonVal).TryGetValue<string>('href', Href) then
      OpenRelatedMdFile(Href)
    else if TJSONObject(JsonVal).TryGetValue<string>('copyText', CopyText) then
      Clipboard.AsText := CopyText
    else if TJSONObject(JsonVal).TryGetValue<Boolean>('dropFile', IsDrop) and IsDrop then
    begin
      DroppedPath := DroppedFilePath(Args);
      if DroppedPath <> '' then
        OpenFile(DroppedPath);
    end;
  finally
    JsonVal.Free;
  end;
end;

// Caminho completo do arquivo arrastado pra janela. O JS nao enxerga o
// caminho (so nome/conteudo), mas o WebView2 entrega o File mandado por
// postMessageWithAdditionalObjects como ICoreWebView2File, que tem o Path.
// Vazio se o runtime do WebView2 for antigo demais pra isso ou nao vier arquivo.
function TFormMain.DroppedFilePath(Args: TWebMessageReceivedEventArgs): string;
var
  Args2: ICoreWebView2WebMessageReceivedEventArgs2;
  Objects: ICoreWebView2ObjectCollectionView;
  Count: SYSUINT;
  Obj: IUnknown;
  WebFile: ICoreWebView2File;
  PathPtr: PWideChar;
begin
  Result := '';
  if not Supports(Args.ArgsInterface, ICoreWebView2WebMessageReceivedEventArgs2, Args2) then
    Exit;
  if (Args2.Get_additionalObjects(Objects) <> S_OK) or (Objects = nil) then
    Exit;
  if (Objects.Get_Count(Count) <> S_OK) or (Count = 0) then
    Exit;
  if Objects.GetValueAtIndex(0, Obj) <> S_OK then
    Exit;
  if not Supports(Obj, ICoreWebView2File, WebFile) then
    Exit;
  if WebFile.Get_Path(PathPtr) = S_OK then
  begin
    Result := PathPtr;
    CoTaskMemFree(PathPtr);
  end;
end;

// Abre um arquivo na janela atual, empilhando o anterior pro "Voltar" — usado
// pelo botao "Abrir..." e pelo arrastar-e-soltar.
procedure TFormMain.OpenFile(const APath: string);
begin
  if FCurrentMDPath <> '' then
    FHistory.Add(FCurrentMDPath);
  FCurrentMDPath := APath;
  FPendingAnchor := '';
  ChkHtml.Checked := False; // HTML cru reseta a cada arquivo novo (seguranca)
  RenderCurrentFile;
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
    ShowMessage('PDF salvo em: ' + FPdfPath)
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

  // Sem dialogo de "Salvar como" (de proposito, um clique so); so pergunta
  // se o PDF ja existe: Sim substitui, Nao cancela sem gerar nada. Caixa
  // nativa do Windows (botoes no idioma do sistema — o MessageDlg do VCL
  // sai em ingles), com "Nao" como padrao.
  PdfPath := ChangeFileExt(FCurrentMDPath, '.pdf');
  if TFile.Exists(PdfPath) and
    (Application.MessageBox(PChar(ExtractFileName(PdfPath) + ' ja existe. Substituir?'),
      'Salvar PDF', MB_YESNO or MB_ICONQUESTION or MB_DEFBUTTON2) <> IDYES) then
    Exit;

  FPdfPath := PdfPath; // a mensagem de conclusao usa este, nao o arquivo aberto na hora
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

  OpenFile(OpenDialog1.FileName);
end;

end.
