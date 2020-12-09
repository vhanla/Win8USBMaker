object Form1: TForm1
  Left = 320
  Top = 198
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Windows 8 USB Installer Maker '
  ClientHeight = 249
  ClientWidth = 450
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 10
    Width = 88
    Height = 13
    Caption = 'Select a USB Drive'
  end
  object Label2: TLabel
    Left = 8
    Top = 34
    Width = 55
    Height = 13
    Caption = 'FileSystem:'
  end
  object ComboBox1: TComboBox
    Left = 102
    Top = 8
    Width = 51
    Height = 21
    Style = csDropDownList
    TabOrder = 0
    OnChange = ComboBox1Change
  end
  object Memo1: TMemo
    Left = 8
    Top = 143
    Width = 431
    Height = 99
    Lines.Strings = (
      'Win8USB - Windows 8 USB Installer Maker written by vhanla'
      
        '----------------------------------------------------------------' +
        '--------')
    ScrollBars = ssBoth
    TabOrder = 1
  end
  object Edit1: TEdit
    Left = 8
    Top = 53
    Width = 362
    Height = 21
    TabOrder = 2
  end
  object Button1: TButton
    Left = 376
    Top = 49
    Width = 63
    Height = 25
    Caption = 'Search ISO'
    TabOrder = 3
    OnClick = Button1Click
  end
  object CheckBox1: TCheckBox
    Left = 204
    Top = 80
    Width = 85
    Height = 17
    Hint = 
      'If your USB drive is formatted to FAT32, you need to activate th' +
      'is option because it is required a NTFS filesystem'
    Caption = 'Format drive'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 4
  end
  object Button2: TButton
    Left = 295
    Top = 80
    Width = 75
    Height = 25
    Caption = 'Create'
    ElevationRequired = True
    TabOrder = 5
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 376
    Top = 80
    Width = 63
    Height = 25
    Caption = 'Exit'
    TabOrder = 6
    OnClick = Button3Click
  end
  object ProgressBar1: TProgressBar
    Left = 8
    Top = 120
    Width = 433
    Height = 17
    TabOrder = 7
  end
  object Button4: TButton
    Left = 8
    Top = 80
    Width = 88
    Height = 25
    Hint = 
      'Re applies USB boot entry , it is already applied with Create bu' +
      'tton, and this is only if it fails for some reason.'
    Caption = 'Fix USB boot'
    ElevationRequired = True
    ParentShowHint = False
    ShowHint = True
    TabOrder = 8
    OnClick = Button4Click
  end
  object CheckBox2: TCheckBox
    Left = 104
    Top = 80
    Width = 94
    Height = 17
    Hint = 
      'Shows the copying process, it uses 7zg.exe in boot folder, might' +
      ' be slower, it depends on your USB drive speed.'
    Caption = 'Show copying'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 9
  end
  object OpenDialog1: TOpenDialog
    Left = 256
    Top = 8
  end
end
