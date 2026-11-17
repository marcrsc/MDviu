program MDviu;

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {FormMain},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Onyx Blue');
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
