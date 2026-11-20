object FormMain: TFormMain
  Left = 0
  Top = 0
  ActiveControl = EdgeBrowser1
  Caption = 'MDviu'
  ClientHeight = 700
  ClientWidth = 900
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object PanelTop: TPanel
    Left = 0
    Top = 0
    Width = 900
    Height = 32
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object LblStyle: TLabel
      Left = 8
      Top = 7
      Width = 28
      Height = 15
      Caption = 'Estilo'
    end
    object LblWrap: TLabel
      Left = 722
      Top = 9
      Width = 40
      Height = 13
      Cursor = crHandPoint
      Hint = 'Quebra as linhas longas dentro dos blocos de codigo, em vez de rolar para o lado.'
      Caption = 'Quebra'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      OnClick = LblCheckClick
    end
    object LblNewWindow: TLabel
      Left = 798
      Top = 9
      Width = 34
      Height = 13
      Cursor = crHandPoint
      Hint = 'Abre os links deste arquivo numa janela nova do MDviu, em vez de navegar nesta.'
      Caption = 'Janela'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      OnClick = LblCheckClick
    end
    object LblHtml: TLabel
      Left = 868
      Top = 9
      Width = 28
      Height = 13
      Cursor = crHandPoint
      Hint = 'Permite HTML bruto neste arquivo; desliga sozinha ao abrir outro, por seguranca.'
      Caption = 'HTML'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      OnClick = LblCheckClick
    end
    object BtnOpen: TSpeedButton
      Left = 224
      Top = 4
      Width = 72
      Height = 24
      Hint = 'Abre outro arquivo (Ctrl+O).'
      Caption = 'Abrir...'
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      StyleElements = [seClient, seBorder]
      OnClick = ActOpenExecute
    end
    object BtnBack: TSpeedButton
      Left = 302
      Top = 4
      Width = 72
      Height = 24
      Hint = 'Volta ao arquivo anterior, na mesma posicao de rolagem (Alt+Backspace).'
      Caption = 'Voltar'
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      StyleElements = [seClient, seBorder]
      OnClick = ActBackExecute
    end
    object BtnScrollTop: TSpeedButton
      Left = 380
      Top = 4
      Width = 72
      Height = 24
      Hint = 'Rola ate o topo do arquivo atual.'
      Caption = 'Topo'
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      StyleElements = [seClient, seBorder]
      OnClick = ActScrollTopExecute
    end
    object BtnReload: TSpeedButton
      Left = 458
      Top = 4
      Width = 72
      Height = 24
      Hint = 'Recarrega o arquivo atual do disco (F5).'
      Caption = 'Atualizar'
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      StyleElements = [seClient, seBorder]
      OnClick = ActReloadExecute
    end
    object BtnPrint: TSpeedButton
      Left = 536
      Top = 4
      Width = 72
      Height = 24
      Hint = 'Abre a impressao nativa do WebView2 (Ctrl+P).'
      Caption = 'Imprimir'
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      StyleElements = [seClient, seBorder]
      OnClick = ActPrintExecute
    end
    object BtnExportPdf: TSpeedButton
      Left = 614
      Top = 4
      Width = 72
      Height = 24
      Hint = 'Salva o arquivo atual como PDF, avisando antes de substituir (Ctrl+Shift+P).'
      Caption = 'Salvar PDF'
      Flat = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      StyleElements = [seClient, seBorder]
      OnClick = ActExportPdfExecute
    end
    object ComboStyles: TComboBox
      Left = 41
      Top = 5
      Width = 160
      Height = 23
      Hint = 'Escolhe o estilo visual da pagina: cores, largura e espacamento.'
      Style = csDropDownList
      ParentShowHint = False
      ShowHint = True
      TabOrder = 0
      OnChange = ComboStylesChange
    end
    object ChkWrap: TCheckBox
      Left = 702
      Top = 9
      Width = 17
      Height = 17
      Hint = 'Quebra as linhas longas dentro dos blocos de codigo, em vez de rolar para o lado.'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 1
      OnClick = ChkWrapClick
    end
    object ChkNewWindow: TCheckBox
      Left = 778
      Top = 9
      Width = 17
      Height = 17
      Hint = 'Abre os links deste arquivo numa janela nova do MDviu, em vez de navegar nesta.'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 2
    end
    object ChkHtml: TCheckBox
      Left = 848
      Top = 9
      Width = 17
      Height = 17
      Hint = 'Permite HTML bruto neste arquivo; desliga sozinha ao abrir outro, por seguranca.'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 3
      OnClick = ChkHtmlClick
    end
  end
  object EdgeBrowser1: TEdgeBrowser
    Left = 0
    Top = 32
    Width = 900
    Height = 668
    Align = alClient
    TabOrder = 1
    AllowSingleSignOnUsingOSPrimaryAccount = False
    TargetCompatibleBrowserVersion = '137.0.3296.44'
    UserDataFolder = '%LOCALAPPDATA%\MDviu.exe.WebView2'
    OnCreateWebViewCompleted = EdgeBrowser1CreateWebViewCompleted
    OnNavigationCompleted = EdgeBrowser1NavigationCompleted
    OnNewWindowRequested = EdgeBrowser1NewWindowRequested
    OnPrintToPDFCompleted = EdgeBrowser1PrintToPDFCompleted
    OnWebMessageReceived = EdgeBrowser1WebMessageReceived
  end
  object ActionList1: TActionList
    Left = 40
    Top = 72
    object ActOpen: TAction
      Caption = 'Abrir...'
      ShortCut = 16463
      OnExecute = ActOpenExecute
    end
    object ActBack: TAction
      Caption = 'Voltar'
      ShortCut = 32776
      OnExecute = ActBackExecute
    end
    object ActScrollTop: TAction
      Caption = 'Topo'
      OnExecute = ActScrollTopExecute
    end
    object ActReload: TAction
      Caption = 'Atualizar'
      ShortCut = 116
      OnExecute = ActReloadExecute
    end
    object ActPrint: TAction
      Caption = 'Imprimir'
      ShortCut = 16464
      OnExecute = ActPrintExecute
    end
    object ActExportPdf: TAction
      Caption = 'Salvar PDF'
      ShortCut = 24656
      OnExecute = ActExportPdfExecute
    end
  end
  object OpenDialog1: TOpenDialog
    Filter = 
      'Arquivos Markdown|*.md|Codigo-fonte e texto|*.pas;*.dpr;*.dfm;*.' +
      'dpk;*.inc;*.html;*.htm;*.js;*.ts;*.css;*.php;*.asp;*.json;*.xml;' +
      '*.dproj;*.groupproj;*.config;*.manifest;*.svg;*.xsd;*.xsl;*.yml;' +
      '*.yaml;*.ini;*.toml;*.sql;*.bat;*.cmd;*.ps1;*.sh;*.py;*.pyw;*.vb' +
      's;*.vb;*.cs;*.java;*.cpp;*.h;*.txt;*.log;*.csv;*.diff;*.patch|To' +
      'dos os arquivos|*.*'
    Title = 'Abrir arquivo Markdown'
    Left = 120
    Top = 72
  end
end
