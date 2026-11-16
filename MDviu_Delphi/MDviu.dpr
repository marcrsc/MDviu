program MDviu;

// *.res: icone (Project Options > Application > Icon, Icon_MainIcon no
// .dproj). *.dres: OnyxBlue.vsf como RCDATA (Project > Resources and
// Images...). Containers diferentes, os dois precisam estar aqui — a IDE
// as vezes regenera so um dos dois ao salvar, conferir se nao sumiu de novo.
{$R *.res}
{$R *.dres}

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {FormMain};

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
