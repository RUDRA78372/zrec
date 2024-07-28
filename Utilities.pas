unit Utilities;


interface

uses
  System.Classes, System.Math, WinAPI.Windows, System.SysUtils,
  System.AnsiStrings;




procedure WriteHeader(Header: string; Stream: TStream);
function CheckHeader(Header: string; Stream: TStream): Boolean;

type
  TConsoleWriter = class(TObject)
  private
    STDERR: THandle;
    Row: integer;
  public
    constructor Create;
    procedure Wrt(Text: string);
    procedure Nextln;
  end;


// Following functions are from Razor12911
function StreamToStream(hStream1, hStream2: TStream; BufferSize: integer;
  Size: Int64): Int64;
function ConvertKB2TB(Float: Int64): string;
function EndianSwap(A: single): single; overload;
function EndianSwap(A: double): double; overload;
function EndianSwap(A: Int64): Int64; overload;
function EndianSwap(A: UInt64): UInt64; overload;
function EndianSwap(A: Int32): Int32; overload;
function EndianSwap(A: UInt32): UInt32; overload;
function EndianSwap(A: Int16): Int16; overload;
function EndianSwap(A: UInt16): UInt16; overload;


    {
    TMappedFile from uFileMapping.pas
  Copyright (c) 2005-2006 by Davy Landman

  See the file COPYING.FPC, included in this distribution,
  for details about the copyright. Alternately, you may use this source under the provisions of MPL v1.x or later

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
}

type
  TMappedFile = class(TFilestream)
  private
    FContent: Pointer;
    FMapping, FHandle: THandle;
    FSize: Int64;
    procedure MapFile(const aFilename: WideString);
  public
    constructor Create(const aFilename: WideString);
    destructor Destroy; override;
    property Memory: Pointer read FContent;
    property Size: Int64 read FSize;
  end;
 function FileSize(const aFilename: string): Int64;



implementation


function FileSize(const aFilename: string): Int64;
var
  AttributeData: TWin32FileAttributeData;
begin
  if GetFileAttributesEx(PChar(aFilename), GetFileExInfoStandard, @AttributeData)
  then
  begin
    Int64Rec(Result).Lo := AttributeData.nFileSizeLow;
    Int64Rec(Result).Hi := AttributeData.nFileSizeHigh;
  end
  else
    Result := 0;
end;

function StreamToStream(hStream1, hStream2: TStream; BufferSize: integer;
  Size: Int64): Int64;
var
  i: integer;
  Buff: Pointer;
  SizeIn: Int64;
begin
  Result := 0;
  if Size = 0 then
    exit;
  SizeIn := 0;
  GetMem(Buff, BufferSize);
  if SizeIn + BufferSize > Size then
    i := hStream1.Read(Buff^, Size - SizeIn)
  else
    i := hStream1.Read(Buff^, BufferSize);
  while i > 0 do
  begin
    hStream2.WriteBuffer(Buff^, i);
    Inc(SizeIn, i);
    if SizeIn >= Size then
      break;
    if SizeIn + BufferSize > Size then
      i := hStream1.Read(Buff^, Size - SizeIn)
    else
      i := hStream1.Read(Buff^, BufferSize);
  end;
  FreeMem(Buff);
  Result := SizeIn;
end;


procedure WriteHeader(Header: string; Stream: TStream);
var
  Bytes: TBytes;
begin
  Setlength(Bytes, length(Header));
  Bytes := Bytesof(Header);
  Stream.WriteBuffer(Bytes[0], length(Bytes));
end;

function CheckHeader(Header: string; Stream: TStream): Boolean;
var
  Bytes: TBytes;
begin
  Setlength(Bytes, length(Header));
  Stream.ReadBuffer(Bytes[0], length(Bytes));
  if StringOf(Bytes) <> Header then
    Result := false
  else
    Result := True;
end;

function ConvertKB2TB(Float: Int64): string;
  function NumToStr(Float: single; DeciCount: integer): string;
  begin
    Result := Format('%.' + IntToStr(DeciCount) + 'n', [Float]);
    Result := ReplaceStr(Result, ',', '');
  end;

const
  MV = 1024;
var
  s, MB, GB, TB: string;
begin
  MB := 'MB';
  GB := 'GB';
  TB := 'TB';
  if Float < Power(1000, 2) then
  begin
    s := NumToStr(Float / Power(MV, 1), 2);
    if length(AnsiLeftStr(s, AnsiPos('.', s) - 1)) = 1 then
      Result := NumToStr(Float / Power(MV, 1), 2) + ' ' + MB;
    if length(AnsiLeftStr(s, AnsiPos('.', s) - 1)) = 2 then
      Result := NumToStr(Float / Power(MV, 1), 1) + ' ' + MB;
    if length(AnsiLeftStr(s, AnsiPos('.', s) - 1)) = 3 then
      Result := NumToStr(Float / Power(MV, 1), 0) + ' ' + MB;
  end
  else if Float < Power(1000, 3) then
  begin
    s := NumToStr(Float / Power(MV, 2), 2);
    if length(AnsiLeftStr(s, AnsiPos('.', s) - 1)) = 1 then
      Result := NumToStr(Float / Power(MV, 2), 2) + ' ' + GB;
    if length(AnsiLeftStr(s, AnsiPos('.', s) - 1)) = 2 then
      Result := NumToStr(Float / Power(MV, 2), 1) + ' ' + GB;
    if length(AnsiLeftStr(s, AnsiPos('.', s) - 1)) = 3 then
      Result := NumToStr(Float / Power(MV, 2), 0) + ' ' + GB;
  end
  else if Float < Power(1000, 4) then
  begin
    s := NumToStr(Float / Power(MV, 3), 2);
    if length(AnsiLeftStr(s, AnsiPos('.', s) - 1)) = 1 then
      Result := NumToStr(Float / Power(MV, 3), 2) + ' ' + TB;
    if length(AnsiLeftStr(s, AnsiPos('.', s) - 1)) = 2 then
      Result := NumToStr(Float / Power(MV, 3), 1) + ' ' + TB;
    if length(AnsiLeftStr(s, AnsiPos('.', s) - 1)) = 3 then
      Result := NumToStr(Float / Power(MV, 3), 0) + ' ' + TB;
  end;
end;

function EndianSwap(A: single): single;
var
  C: array [0 .. 3] of Byte absolute Result;
  d: array [0 .. 3] of Byte absolute A;
begin
  C[0] := d[3];
  C[1] := d[2];
  C[2] := d[1];
  C[3] := d[0];
end;

function EndianSwap(A: double): double;
var
  C: array [0 .. 7] of Byte absolute Result;
  d: array [0 .. 7] of Byte absolute A;
begin
  C[0] := d[7];
  C[1] := d[6];
  C[2] := d[5];
  C[3] := d[4];
  C[4] := d[3];
  C[5] := d[2];
  C[6] := d[1];
  C[7] := d[0];
end;

function EndianSwap(A: Int64): Int64;
var
  C: array [0 .. 7] of Byte absolute Result;
  d: array [0 .. 7] of Byte absolute A;
begin
  C[0] := d[7];
  C[1] := d[6];
  C[2] := d[5];
  C[3] := d[4];
  C[4] := d[3];
  C[5] := d[2];
  C[6] := d[1];
  C[7] := d[0];
end;

function EndianSwap(A: UInt64): UInt64;
var
  C: array [0 .. 7] of Byte absolute Result;
  d: array [0 .. 7] of Byte absolute A;
begin
  C[0] := d[7];
  C[1] := d[6];
  C[2] := d[5];
  C[3] := d[4];
  C[4] := d[3];
  C[5] := d[2];
  C[6] := d[1];
  C[7] := d[0];
end;

function EndianSwap(A: Int32): Int32;
var
  C: array [0 .. 3] of Byte absolute Result;
  d: array [0 .. 3] of Byte absolute A;
begin
  C[0] := d[3];
  C[1] := d[2];
  C[2] := d[1];
  C[3] := d[0];
end;

function EndianSwap(A: UInt32): UInt32;
var
  C: array [0 .. 3] of Byte absolute Result;
  d: array [0 .. 3] of Byte absolute A;
begin
  C[0] := d[3];
  C[1] := d[2];
  C[2] := d[1];
  C[3] := d[0];
end;

function EndianSwap(A: Int16): Int16;
var
  C: array [0 .. 1] of Byte absolute Result;
  d: array [0 .. 1] of Byte absolute A;
begin
  C[0] := d[1];
  C[1] := d[0];
end;

function EndianSwap(A: UInt16): UInt16;
var
  C: array [0 .. 1] of Byte absolute Result;
  d: array [0 .. 1] of Byte absolute A;
begin
  C[0] := d[1];
  C[1] := d[0];
end;

constructor TConsoleWriter.Create;
var
  SBInfo: TConsoleScreenBufferInfo;
begin
  STDERR := GetStdHandle(STD_ERROR_HANDLE);
  GetConsoleScreenBufferInfo(STDERR, SBInfo);
  Row := SBInfo.dwCursorPosition.Y;
  Inc(Row);
  inherited Create;
end;

procedure TConsoleWriter.Wrt(Text: string);
var
  ulLength: Cardinal;
  Coords: TCoord;
  i: integer;
begin
  //
  Coords.X := 0;
  Coords.Y := Row - 1;
  SetConsoleCursorPosition(STDERR, Coords);
  for i := 1 to 10 do
    Text := Text + ' ';
  WriteConsole(STDERR, PChar(Text + #10#13), length(Text + #10#13),
    ulLength, nil);
end;

procedure TConsoleWriter.Nextln;
begin
  Inc(Row);
end;

function FileExistsLongFileNames(const FileName: WideString): Boolean;
begin
  if length(FileName) < 2 then
  begin
    Result := false;
    exit;
  end;
  if CompareMem(@FileName[1], @WideString('\\')[1], 2) then
    Result := (GetFileAttributesW(PWideChar(FileName)) and
      FILE_ATTRIBUTE_DIRECTORY = 0)
  else
    Result := (GetFileAttributesW(PWideChar(WideString('\\?\' + FileName))) and
      FILE_ATTRIBUTE_DIRECTORY = 0)
end;

{ TMappedFile }

constructor TMappedFile.Create(const aFilename: WideString);
begin
  if FileExistsLongFileNames(aFilename) then
  begin
    MapFile(aFilename);
    inherited Create(FHandle);
  end
  else
    raise Exception.Create('File "' + aFilename + '" does not exists.');
end;

destructor TMappedFile.Destroy;
begin
  if Assigned(FContent) then
  begin
    UnmapViewOfFile(FContent);
    CloseHandle(FMapping);
    // CloseHandle(FHandle);
  end;
  inherited Destroy;
end;

procedure TMappedFile.MapFile(const aFilename: WideString);
begin
  if CompareMem(@(aFilename[1]), @('\\'[1]), 2) then
    { Allready an UNC path }
    FHandle := CreateFileW(PWideChar(aFilename), GENERIC_READ,
      FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING,
      FILE_ATTRIBUTE_NORMAL, 0)
  else
    FHandle := CreateFileW(PWideChar(WideString('\\?\' + aFilename)),
      GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING,
      FILE_ATTRIBUTE_NORMAL, 0);
  FSize := FileSize(aFilename);
  if FSize <> 0 then
  begin
    FMapping := CreateFileMappingW(FHandle, nil, PAGE_READONLY, 0, 0, nil);
    // Win32Check(FMapping <> 0);
  end;
  if FSize = 0 then
    FContent := nil
  else
    FContent := MapViewOfFile(FMapping, FILE_MAP_READ, 0, 0, 0);
  // Win32Check(FContent <> nil);
end;

end.
