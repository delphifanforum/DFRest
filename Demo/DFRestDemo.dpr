program DFRestDemo;

uses
  Vcl.Forms,
  Demo.Main in 'Demo.Main.pas' {FormMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'DFRest Demo';
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
