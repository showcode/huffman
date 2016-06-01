object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Haffman Archiver'
  ClientHeight = 242
  ClientWidth = 385
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 45
    Height = 13
    Caption = 'Input File'
  end
  object Label2: TLabel
    Left = 8
    Top = 48
    Width = 45
    Height = 13
    Caption = 'Input File'
  end
  object Label3: TLabel
    Left = 8
    Top = 120
    Width = 45
    Height = 13
    Caption = 'Input File'
  end
  object Label4: TLabel
    Left = 8
    Top = 160
    Width = 45
    Height = 13
    Caption = 'Input File'
  end
  object SpeedButton1: TSpeedButton
    Left = 354
    Top = 23
    Width = 23
    Height = 22
    Caption = '...'
    OnClick = SpeedButton1Click
  end
  object SpeedButton2: TSpeedButton
    Left = 354
    Top = 63
    Width = 23
    Height = 22
    Caption = '...'
    OnClick = SpeedButton2Click
  end
  object SpeedButton3: TSpeedButton
    Left = 354
    Top = 135
    Width = 23
    Height = 22
    Caption = '...'
    OnClick = SpeedButton3Click
  end
  object SpeedButton4: TSpeedButton
    Left = 354
    Top = 175
    Width = 23
    Height = 22
    Caption = '...'
    OnClick = SpeedButton4Click
  end
  object btnEncode: TButton
    Left = 294
    Top = 91
    Width = 75
    Height = 25
    Caption = 'Encode'
    TabOrder = 0
    OnClick = btnEncodeClick
  end
  object btnDecode: TButton
    Left = 294
    Top = 203
    Width = 75
    Height = 25
    Caption = 'Decode'
    TabOrder = 1
    OnClick = btnDecodeClick
  end
  object edtFile: TEdit
    Left = 8
    Top = 24
    Width = 345
    Height = 21
    TabOrder = 2
    Text = 'c:\testnumbers.txt'
  end
  object edtEncoded: TEdit
    Left = 8
    Top = 64
    Width = 345
    Height = 21
    TabOrder = 3
    Text = 'c:\result.txt'
  end
  object edtArchiv: TEdit
    Left = 8
    Top = 136
    Width = 345
    Height = 21
    TabOrder = 4
    Text = 'c:\result.txt'
  end
  object edtDecoded: TEdit
    Left = 8
    Top = 176
    Width = 345
    Height = 21
    TabOrder = 5
    Text = 'c:\decoded.txt'
  end
  object OpenDialog1: TOpenDialog
    Left = 72
    Top = 208
  end
  object SaveDialog1: TSaveDialog
    Left = 152
    Top = 208
  end
end
