object FormMain: TFormMain
  Left = 0
  Top = 0
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
      Top = 9
      Width = 36
      Height = 15
      Caption = 'Estilo:'
    end
    object BtnOpen: TSpeedButton
      Left = 224
      Top = 4
      Width = 72
      Height = 24
      Caption = 'Abrir...'
      Flat = True
      OnClick = ActOpenExecute
    end
    object BtnBack: TSpeedButton
      Left = 302
      Top = 4
      Width = 72
      Height = 24
      Caption = 'Voltar'
      Flat = True
      OnClick = ActBackExecute
    end
    object BtnScrollTop: TSpeedButton
      Left = 380
      Top = 4
      Width = 72
      Height = 24
      Caption = 'Topo'
      Flat = True
      OnClick = ActScrollTopExecute
    end
    object BtnReload: TSpeedButton
      Left = 458
      Top = 4
      Width = 72
      Height = 24
      Caption = 'Atualizar'
      Flat = True
      OnClick = ActReloadExecute
    end
    object BtnPrint: TSpeedButton
      Left = 536
      Top = 4
      Width = 72
      Height = 24
      Caption = 'Imprimir'
      Flat = True
      OnClick = ActPrintExecute
    end
    object BtnExportPdf: TSpeedButton
      Left = 614
      Top = 4
      Width = 72
      Height = 24
      Caption = 'Salvar PDF'
      Flat = True
      OnClick = ActExportPdfExecute
    end
    object ComboStyles: TComboBox
      Left = 50
      Top = 5
      Width = 160
      Height = 23
      Style = csDropDownList
      TabOrder = 0
      OnChange = ComboStylesChange
    end
    object ChkNewWindow: TCheckBox
      Left = 704
      Top = 8
      Width = 95
      Height = 17
      Caption = 'Nova janela'
      TabOrder = 1
    end
    object ChkHtml: TCheckBox
      Left = 805
      Top = 8
      Width = 60
      Height = 17
      Caption = 'HTML'
      TabOrder = 2
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
      'Arquivos Markdown (*.md)|*.md|Linguagens (*.pas;*.dpr;*.dfm;*.py;*.' +
      'html;*.htm;*.js;*.ts;*.css;*.php;*.sql;*.ini;*.asp;*.vbs;*.vb;*.txt)' +
      '|*.pas;*.dpr;*.dfm;*.py;*.html;*.htm;*.js;*.ts;*.css;*.php;*.sql;*.' +
      'ini;*.asp;*.vbs;*.vb;*.txt|Todos os arquivos (*.*)|*.*'
    Title = 'Abrir arquivo Markdown'
    Left = 120
    Top = 72
  end
end
