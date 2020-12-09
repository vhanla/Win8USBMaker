program Win8USB;


uses
  Forms,
  win8usb_Src in 'win8usb_Src.pas' {Form1},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;

  TStyleManager.TrySetStyle('Metro Blue');
  Application.Title := 'Windows 8 USB Installer Maker';

  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
