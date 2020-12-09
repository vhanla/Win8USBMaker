{
Dec 26-12-12
Fixinf bugs
-----------
  - It works with no application crashing now, so it is better to handle
    user interaction after this.
    Ideas: add an animated progress bar and using windows 7 taskbar animation

Dec 25-12-12
Fixing bugs
-----
  - Addded "FormatSettings." to magsub... unit since DXe3 deprecated TimeSeparator, etc (global variables)
  - :-/ no sirve

}
unit win8usb_Src;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, ComCtrls;

const
  WM_SYNC_ARCHIVE_PROGRESS = WM_USER+153;

type
  TForm1 = class(TForm)
    ComboBox1: TComboBox;
    Label1: TLabel;
    Memo1: TMemo;
    Label2: TLabel;
    OpenDialog1: TOpenDialog;
    Edit1: TEdit;
    Button1: TButton;
    CheckBox1: TCheckBox;
    Button2: TButton;
    Button3: TButton;
    ProgressBar1: TProgressBar;
    Button4: TButton;
    CheckBox2: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button4Click(Sender: TObject);

  private
    { Private declarations }
    procedure LockControls(const value: Boolean = True);
    procedure ProgressEvent(Percent: integer; var cancel: boolean);
    procedure InfoEvent(Info: string; var cancel: boolean);
    procedure WmSyncArchiveProgress(var Message:TMessage); message  WM_SYNC_ARCHIVE_PROGRESS;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;


// Related to USB
{$MINENUMSIZE 4}
const
  IOCTL_STORAGE_QUERY_PROPERTY =  $002D1400;

type
  STORAGE_QUERY_TYPE = (PropertyStandardQuery = 0, PropertyExistsQuery, PropertyMaskQuery, PropertyQueryMaxDefined);
  TStorageQueryType = STORAGE_QUERY_TYPE;

  STORAGE_PROPERTY_ID = (StorageDeviceProperty = 0, StorageAdapterProperty);
  TStoragePropertyID = STORAGE_PROPERTY_ID;

  STORAGE_PROPERTY_QUERY = packed record
    PropertyId: STORAGE_PROPERTY_ID;
    QueryType: STORAGE_QUERY_TYPE;
    AdditionalParameters: array [0..9] of AnsiChar;
  end;
  TStoragePropertyQuery = STORAGE_PROPERTY_QUERY;

  STORAGE_BUS_TYPE = (BusTypeUnknown = 0, BusTypeScsi, BusTypeAtapi, BusTypeAta, BusType1394, BusTypeSsa, BusTypeFibre,
    BusTypeUsb, BusTypeRAID, BusTypeiScsi, BusTypeSas, BusTypeSata, BusTypeMaxReserved = $7F);
  TStorageBusType = STORAGE_BUS_TYPE;

  STORAGE_DEVICE_DESCRIPTOR = packed record
    Version: DWORD;
    Size: DWORD;
    DeviceType: Byte;
    DeviceTypeModifier: Byte;
    RemovableMedia: Boolean;
    CommandQueueing: Boolean;
    VendorIdOffset: DWORD;
    ProductIdOffset: DWORD;
    ProductRevisionOffset: DWORD;
    SerialNumberOffset: DWORD;
    BusType: STORAGE_BUS_TYPE;
    RawPropertiesLength: DWORD;
    RawDeviceProperties: array [0..0] of AnsiChar;
  end;
  TStorageDeviceDescriptor = STORAGE_DEVICE_DESCRIPTOR;
implementation

{$R *.dfm}
uses sevenzip, magfmtdisk, magsubs1;
var
totaldisk, freedisk: longint;
MagFmtChkDsk: TMagFmtChkDsk;

function GetBusType(Drive: AnsiChar): TStorageBusType;
var
  H: THandle;
  Query: TStoragePropertyQuery;
  dwBytesReturned: DWORD;
  Buffer: array [0..1023] of Byte;
  sdd: TStorageDeviceDescriptor absolute Buffer;
  OldMode: UINT;
begin
  Result := BusTypeUnknown;

  OldMode := SetErrorMode(SEM_FAILCRITICALERRORS);
  try
    H := CreateFile(PChar(Format('\\.\%s:', [AnsiLowerCase(Drive)])), 0, FILE_SHARE_READ or FILE_SHARE_WRITE, nil,
      OPEN_EXISTING, 0, 0);
    if H <> INVALID_HANDLE_VALUE then
    begin
      try
        dwBytesReturned := 0;
        FillChar(Query, SizeOf(Query), 0);
        FillChar(Buffer, SizeOf(Buffer), 0);
        sdd.Size := SizeOf(Buffer);
        Query.PropertyId := StorageDeviceProperty;
        Query.QueryType := PropertyStandardQuery;
        if DeviceIoControl(H, IOCTL_STORAGE_QUERY_PROPERTY, @Query, SizeOf(Query), @Buffer, SizeOf(Buffer), dwBytesReturned, nil) then
          Result := sdd.BusType;
      finally
        CloseHandle(H);
      end;
    end;
  finally
    SetErrorMode(OldMode);
  end;
end;


procedure GetUsbDrives(List: TStrings);
var
  DriveBits: set of 0..25;
  I: Integer;
  Drive: Char;
begin
  List.BeginUpdate;
  try
    Cardinal(DriveBits) := GetLogicalDrives;

    for I := 0 to 25 do
      if I in DriveBits then
      begin
        Drive := Chr(Ord('A') + I);
        if GetBusType(AnsiChar(Drive)) = BusTypeUsb then
          List.Add(Drive);
      end;
  finally
    List.EndUpdate;
  end;
end;

function GetHardDiskPartitionType(const DriveLetter: Char): string;
var
  NotUsed: DWORD;
  VolumeFlags: DWORD;
  VolumeInfo: array[0..MAX_PATH] of Char;
  VolumeSerialNumber: DWORD;
  PartitionType: array[0..32] of Char;
begin
  GetVolumeInformation(PChar(DriveLetter + ':\'),
    nil, SizeOf(VolumeInfo), @VolumeSerialNumber, NotUsed,
    VolumeFlags, PartitionType, 32);
  Result := PartitionType;
end;

procedure RunDosInMemo(Que:String;EnMemo:TMemo);
  const
     CUANTOBUFFER = 2000;
  var
    Seguridades         : TSecurityAttributes;
    PaLeer,PaEscribir   : THandle;
    start               : TStartUpInfo;
    ProcessInfo         : TProcessInformation;
    Buffer              : Pansichar;
    BytesRead           : DWord;
    CuandoSale          : DWord;
  begin
    with Seguridades do
    begin
      nlength              := SizeOf(TSecurityAttributes);
      binherithandle       := true;
      lpsecuritydescriptor := nil;
    end;
    {Creamos el pipe...}
    if Createpipe (PaLeer, PaEscribir, @Seguridades, 0) then
    begin
      Buffer  := AllocMem(CUANTOBUFFER + 1);
      FillChar(Start,Sizeof(Start),#0);
      start.cb          := SizeOf(start);
      start.hStdOutput  := PaEscribir;
      start.hStdInput   := PaLeer;
      start.dwFlags     := STARTF_USESTDHANDLES +
                           STARTF_USESHOWWINDOW;
      start.wShowWindow := SW_HIDE;

      if CreateProcess(nil,
         PChar(Que),
         @Seguridades,
         @Seguridades,
         true,
         NORMAL_PRIORITY_CLASS,
         nil,
         nil,
         start,
         ProcessInfo)
      then
        begin
          {Espera a que termine la ejecucion}
          repeat
            CuandoSale := WaitForSingleObject( ProcessInfo.hProcess,100);
            Application.ProcessMessages;
          until (CuandoSale <> WAIT_TIMEOUT);
          {Leemos la Pipe}
          repeat
            BytesRead := 0;
            {Llenamos un troncho de la pipe, igual a nuestro buffer}
            ReadFile(PaLeer,Buffer[0],CUANTOBUFFER,BytesRead,nil);
            {La convertimos en una string terminada en cero}
            Buffer[BytesRead]:= #0;
            {Convertimos caracteres DOS a ANSI}
            OemToAnsi(Buffer,Buffer);
            EnMemo.Text := EnMemo.text + String(Buffer);
          until (BytesRead < CUANTOBUFFER);
        end;
      FreeMem(Buffer);
      CloseHandle(ProcessInfo.hProcess);
      CloseHandle(ProcessInfo.hThread);
      CloseHandle(PaLeer);
      CloseHandle(PaEscribir);
    end;
  end;

procedure TForm1.LockControls(const value:Boolean = True);
begin
  ComboBox1.Enabled:=not value;
  Button1.Enabled:=not value;
  Button2.Enabled:=not value;
  Button3.Enabled:=not value;
  Button4.Enabled:=not value;
  Edit1.Enabled:=not value;
  CheckBox1.Enabled:=not value;
  CheckBox2.Enabled:=not value;
end;



procedure TForm1.ProgressEvent(Percent: Integer; var cancel: Boolean);
begin
  ProgressBar1.Position:= Percent;
  Application.ProcessMessages;
//  cancel:=cancelflag;
end;


procedure TForm1.InfoEvent(Info: string; var cancel: Boolean);
begin
  memo1.Lines.Add(Info);
  Application.ProcessMessages;
  //Cancel:= cancelflag;
end;

procedure TForm1.WmSyncArchiveProgress(var Message: TMessage);
begin
  if Message.WParam = 1
  then
  begin
    try
    Form1.ProgressBar1.Max:=Message.LParam
    except
    end;
  end
  else
  begin
    try
    Form1.ProgressBar1.Position:=Message.LParam;
    except

    end;
  end;
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  OpenDialog1.Filter:='Image Files|*.iso|Any file|*.*';
  if OpenDialog1.Execute then
  begin
      Edit1.Text:=OpenDialog1.FileName;
  end;
end;

function ProgressCallback(sender: Pointer; total: boolean; value: int64): HRESULT; stdcall;
 begin
   if total then
     form1.ProgressBar1.Max := value
   else
     form1.ProgressBar1.Position := value;
   //Application.ProcessMessages;
   Result := S_OK;
 end;
{function ExecAndWait(sExe, sCommandLine: string): Boolean;
var
  dwExitCode: DWORD;
  tpiProcess: TProcessInformation;
  tsiStartup: TStartupInfo;
begin
  Result := False;
  FillChar(tsiStartup, SizeOf(TStartupInfo), 0);
  tsiStartup.cb := SizeOf(TStartupInfo);
  if CreateProcess(PChar(sExe), PChar(sCommandLine), nil, nil, False, 0,
    nil, nil, tsiStartup, tpiProcess) then
  begin
    if WAIT_OBJECT_0 = WaitForSingleObject(tpiProcess.hProcess, INFINITE) then
    begin
      if GetExitCodeProcess(tpiProcess.hProcess, dwExitCode) then
      begin
        if dwExitCode = 0 then
          Result := True
        else
          SetLastError(dwExitCode + $2000);
      end;
    end;
    dwExitCode := GetLastError;
    CloseHandle(tpiProcess.hProcess);
    CloseHandle(tpiProcess.hThread);
    SetLastError(dwExitCode);
  end;
end;}

function WinExecAndWait32(FileName: string; Visibility: Integer): dWord;
var
  zAppName: array[0..512] of Char;
  zCurDir: array[0..255] of Char;
  WorkDir: string;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
begin
  StrPCopy(zAppName, FileName);
  GetDir(0, WorkDir);
  StrPCopy(zCurDir, WorkDir);
  FillChar(StartupInfo, Sizeof(StartupInfo), #0);
  StartupInfo.cb := Sizeof(StartupInfo);

  StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
  StartupInfo.wShowWindow := Visibility;
  if not CreateProcess(nil,
           zAppName, { pointer to command line string }
           nil, { pointer to process security attributes }
           nil, { pointer to thread security attributes }
           false, { handle inheritance flag }
           CREATE_NEW_CONSOLE or { creation flags }
           NORMAL_PRIORITY_CLASS,
           nil, { pointer to new environment block }
           nil, { pointer to current directory name }
           StartupInfo, { pointer to STARTUPINFO }
           ProcessInfo) then
           begin
    Result := $FFFFFFFF; { pointer to PROCESS_INF }
           end
  else
  begin
    WaitforSingleObject(ProcessInfo.hProcess, INFINITE);
    GetExitCodeProcess(ProcessInfo.hProcess, Result);
    CloseHandle(ProcessInfo.hProcess);
    CloseHandle(ProcessInfo.hThread);
  end;
end;

function ProgressCallback2(Sender:Pointer; total: Boolean; Value:Int64):HRESULT;stdcall;
const
  BoolTo01: array[False..True] of integer = (0,1);
begin
  PostMessage(HWND(Sender), WM_SYNC_ARCHIVE_PROGRESS, BoolTo01[total], Value);
  Application.ProcessMessages;
  Result := S_OK;
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  MediaType: TMediaType;
  Error: Boolean;
begin
  Error:=false;

  //let's lock controls to forbid user to change anything
  LockControls;

//let's see if disk is selected
// ShowMessage(IntToStrAnsi(ComboBox1.ItemIndex)); -1 if not selected
  if ComboBox1.ItemIndex = -1 then
  begin
    memo1.Lines.Add('Choose your USB drive!');
    LockControls(False);
    exit;
  end;
//let's see if disk has enough disk space
  if totaldisk < 3000 then
  begin
    memo1.Lines.Add('Your USB drive doesn''t have minimum disk size, at least 3GB!');
    LockControls(False);
    exit;
  end;
  if (freedisk < 3000) and (not CheckBox1.Checked) then
  begin
    memo1.Lines.Add('You need more disk space on your USB drive!');
    LockControls(False);
    exit;
  end;
  //extracting ISO files to usb disk
  if not FileExists(Edit1.Text) then
  begin
    memo1.Lines.Add('ISO file not loaded');
    LockControls(False);
    exit;
  end;
//first format the drive if required
  if CheckBox1.Checked then
  begin
    try
//      RunDosInMemo(PChar('cmd.exe /c format '+ComboBox1.text+': /Q /V:WIN8 /FS:NTFS /Y'),memo1);
// rundosinmemo es lentisimo

    //lets format using mag
    ProgressBar1.Position:=0;
    memo1.Lines.Add('Starting Format USB Drive '+ComboBox1.Text+':');

    MediaType:= mtHardDisk;
    //NTFS = 0
    if not  MagFmtChkDsk.FormatDisk(ComboBox1.Text+':\',MediaType,
      TFileSystem(0),'WIN8USB',False,0) then
      begin
        memo1.Lines.Add('Format USB Failed');
        Error:=true;
      end;
      ProgressBar1.Position:=0;
    except
      on E:Exception do memo1.Lines.Add('Error: '+e.Message);
    end;
    if Error then
    begin
      LockControls(False);
      exit;
    end;

  end;

  if CheckBox2.Checked then
  begin
  ///  WinExec(pansichar(ParamStr(0)+'\boot\7zG.exe -x "'+Edit1.Text+'" -o "'+ComboBox1.Text+':\" -y'),SW_SHOWNORMAL);
    Memo1.Lines.Add('Copying files to USB, this will take long...');
    Memo1.Lines.Add('THIS APPLICATION MIGHT APPEAR UNRESPONSIVE, IT''S NORMAL!!!');
    Memo1.Lines.Add('SEE YOUR PENDRIVE ACTIVITY');
    Memo1.Lines.Add(ExtractFilePath(ParamStr(0))+'boot\7zG.exe x "'+Edit1.Text+'" -o"'+ComboBox1.Text+':\" -y');
  ///  ExecAndWait(ExtractFilePath(ParamStr(0))+'\boot\7zG.exe','-x "'+Edit1.Text+'" -o "'+ComboBox1.Text+':\" -y');
    Hide;
    WinExecAndWait32((ExtractFilePath(ParamStr(0))+'boot\7zG.exe x "'+Edit1.Text+'" -o"'+ComboBox1.Text+':\" -y'),SW_SHOWNORMAL);
    Show;
  end
  else
  begin
      Memo1.Lines.Add('Copying files to USB, this will take long...');
      Memo1.Lines.Add('THIS APPLICATION MIGHT APPEAR UNRESPONSIVE, IT''S NORMAL!!!');
      Memo1.Lines.Add('SEE YOUR PENDRIVE ACTIVITY');
      Memo1.Lines.Add('Copying files in background, please wait!');

      SetWindowLong(ProgressBar1.Handle,GWL_STYLE,(GetWindowLong(ProgressBar1.Handle, GWL_STYLE) or (WM_USER + 10)));
      SendMessage(ProgressBar1.Handle,(WM_User +10), 1, 100);

      with CreateInArchive(CLSID_CFormatUdf) do
      begin
        OpenFile(Edit1.Text);
        SetProgressCallback(Pointer(Handle),ProgressCallback2);
        ExtractTo(ComboBox1.Text+':\');
      end;

  end;
  //make usb drive bootable
  Memo1.Lines.Add('Making USB drive bootable...');
//  RunDosInMemo(PChar(ComboBox1.Text+':\boot\bootsect /nt60 '+ComboBox1.Text+':'),memo1);
  RunDosInMemo(PChar(ExtractFilePath(ParamStr(0))+'boot\bootsect /nt60 '+ComboBox1.Text+':'),memo1);
  //finished everything
  Showmessage('Task completed, be sure to review the log text!');
  LockControls(False);
  SendMessage(ProgressBar1.Handle,(WM_User +10), 1, 100);
end;

procedure TForm1.ComboBox1Change(Sender: TObject);

begin
try
  totaldisk:=DiskSize(ord(ComboBox1.Text[1])-ord('A')+1) div 1024 div 1024 ;
  freedisk:=DiskFree(ord(ComboBox1.Text[1])-ord('A')+1) div 1024 div 1024;
  label2.Caption:='FileSystem: '+ (GetHardDiskPartitionType(ComboBox1.Text[1]))
  +' Total: '+IntToStrAnsi(totaldisk)+' MB'
  +' Free: '+IntToStrAnsi(freedisk)+' MB'  ;
except
  label2.Caption:='FileSystem: unknown';
end;

end;

procedure TForm1.FormCreate(Sender: TObject);
begin

GetUsbDrives(ComboBox1.Items);

MagFmtChkDsk:= TMagFmtChkDsk.Create(self);
MagFmtChkDsk.onProgressEvent:= ProgressEvent;
MagFmtChkDsk.onInfoEvent:= InfoEvent;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
FreeAndNil(MagFmtChkDsk);
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
close
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  if ComboBox1.ItemIndex = -1 then
  begin
    ShowMessage('Choose your USB drive!');
    exit;
  end;
  Memo1.Lines.Add('Making USB drive bootable...');
  RunDosInMemo(PChar(ExtractFilePath(ParamStr(0))+'boot\bootsect /nt60 '+ComboBox1.Text+':'),memo1);
  Memo1.Lines.Add('Completed!');
end;

end.
