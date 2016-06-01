//
// https://github.com/showcode
//

unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons;

type
  TMainForm = class(TForm)
    btnEncode: TButton;
    btnDecode: TButton;
    edtFile: TEdit;
    Label1: TLabel;
    edtEncoded: TEdit;
    Label2: TLabel;
    edtArchiv: TEdit;
    Label3: TLabel;
    edtDecoded: TEdit;
    Label4: TLabel;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    SpeedButton4: TSpeedButton;
    procedure btnEncodeClick(Sender: TObject);
    procedure btnDecodeClick(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton3Click(Sender: TObject);
    procedure SpeedButton4Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses
  huffman;

procedure TMainForm.btnEncodeClick(Sender: TObject);
var
  Encoded, Arc: TFileStream;
  Huff: THuffArc;
begin
  Encoded := TFileStream.Create(edtFile.Text, fmOpenRead);
  try
    Arc := TFileStream.Create(edtEncoded.Text, fmCreate);
    try

      Huff := THuffArc.Create;
      try
        Huff.Encode(Encoded, Arc);
      finally
        Huff.Free;
      end;

    finally
      Arc.Free;
    end;
  finally
    Encoded.Free;
  end;
end;

procedure TMainForm.btnDecodeClick(Sender: TObject);
var
  Arc, Recover: TFileStream;
  Huff: THuffArc;
begin
  Arc := TFileStream.Create(edtArchiv.Text, fmOpenRead);
  try
    Recover := TFileStream.Create(edtDecoded.Text, fmCreate);
    try

      Huff := THuffArc.Create;
      try
        Huff.Decode(Arc, Recover);
      finally
        Huff.Free;
      end;

    finally
      Recover.Free;
    end;
  finally
    Arc.Free;
  end;
end;

procedure TMainForm.SpeedButton1Click(Sender: TObject);
begin
  if OpenDialog1.Execute then
    edtFile.Text := OpenDialog1.FileName;
end;

procedure TMainForm.SpeedButton2Click(Sender: TObject);
begin
  if SaveDialog1.Execute then
    edtEncoded.Text := SaveDialog1.FileName;
end;

procedure TMainForm.SpeedButton3Click(Sender: TObject);
begin
  if OpenDialog1.Execute then
    edtArchiv.Text := OpenDialog1.FileName;
end;

procedure TMainForm.SpeedButton4Click(Sender: TObject);
begin
  if SaveDialog1.Execute then
    edtDecoded.Text := SaveDialog1.FileName;
end;

end.
