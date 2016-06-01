//
// https://github.com/showcode
//

program huffarc;

uses
  Forms,
  main in 'main.pas' {MainForm},
  huffman in 'huffman.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
