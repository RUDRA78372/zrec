unit zlibdll;

//unit by Razor12911
interface

uses
  WinAPI.Windows,
  System.SysUtils, System.Classes, System.Zlib;

const
  Z_NO_FLUSH = 0;
  Z_PARTIAL_FLUSH = 1;
  Z_SYNC_FLUSH = 2;
  Z_FULL_FLUSH = 3;
  Z_FINISH = 4;
  Z_BLOCK = 5;
  Z_TREES = 6;
  Z_OK = 0;
  Z_STREAM_END = 1;
  Z_NEED_DICT = 2;
  Z_ERRNO = (-1);
  Z_STREAM_ERROR = (-2);
  Z_DATA_ERROR = (-3);
  Z_MEM_ERROR = (-4);
  Z_BUF_ERROR = (-5);
  Z_VERSION_ERROR = (-6);
  Z_FILTERED = 1;
  Z_HUFFMAN_ONLY = 2;
  Z_RLE = 3;
  Z_FIXED = 4;
  Z_DEFAULT_STRATEGY = 0;
  Z_DEFLATED = 8;

type
  internal_state = record
  end;

  Pinternal_state = ^internal_state;
  alloc_func = function(opaque: Pointer; Items, Size: Cardinal): Pointer; cdecl;
  free_func = procedure(opaque, address: Pointer); cdecl;

 (* z_stream = record
    next_in: PByte;
    avail_in: Cardinal;
    total_in: LongWord;
    next_out: PByte;
    avail_out: Cardinal;
    total_out: LongWord;
    msg: MarshaledAString;
    state: Pinternal_state;
    zalloc: alloc_func;
    zfree: free_func;
    opaque: Pointer;
    data_type: Integer;
    adler: LongWord;
    reserved: LongWord;
  end;         *)

  z_stream = System.ZLib.z_stream;
  TZStreamrec = z_stream;

var
  _zlibVersion: function: MarshaledAString; stdcall;
  s_deflateInit2_: function(var strm: z_stream;
    level, method, windowBits, memLevel, strategy: Integer;
    version: MarshaledAString; stream_size: Integer): Integer stdcall;
  s_deflate: function(var strm: z_stream; flush: Integer): Integer stdcall;
  s_deflateEnd: function(var strm: z_stream): Integer stdcall;
  s_inflateInit2_: function(var strm: z_stream; windowBits: Integer;
    version: MarshaledAString; stream_size: Integer): Integer stdcall;
  s_inflate: function(var strm: z_stream; flush: Integer): Integer stdcall;
  s_inflateEnd: function(var strm: z_stream): Integer stdcall;
  s_inflateReset: function(var strm: z_stream): Integer stdcall;
  s_adler32: function(adler: LongWord; buf: PByte; len: Cardinal)
    : LongWord; stdcall;
   s_deflateTune: function(var strm: z_stream;
  good_length, max_lazy, nice_length, max_chain: Integer): Integer; stdcall;
  c_deflateInit2_: function(var strm: z_stream;
    level, method, windowBits, memLevel, strategy: Integer;
    version: MarshaledAString; stream_size: Integer): Integer cdecl;
  c_deflate: function(var strm: z_stream; flush: Integer): Integer cdecl;
  c_deflateEnd: function(var strm: z_stream): Integer cdecl;
  c_inflateInit2_: function(var strm: z_stream; windowBits: Integer;
    version: MarshaledAString; stream_size: Integer): Integer cdecl;
  c_inflate: function(var strm: z_stream; flush: Integer): Integer cdecl;
  c_inflateEnd: function(var strm: z_stream): Integer cdecl;
  c_inflateReset: function(var strm: z_stream): Integer cdecl;
  c_adler32: function(adler: LongWord; buf: PByte; len: Cardinal)
    : LongWord; cdecl;
    c_deflateTune: function(var strm: z_stream;
  good_length, max_lazy, nice_length, max_chain: Integer): Integer; cdecl;
  DLLLoaded: Boolean = False;

function deflateInit2(var strm: z_stream; level: Integer;
  method: Integer = Z_DEFLATED; windowBits: Integer = 15; memLevel: Integer = 8;
  strategy: Integer = Z_DEFAULT_STRATEGY): Integer;
function deflate(var strm: z_stream; flush: Integer): Integer;
function deflateEnd(var strm: z_stream): Integer;
function inflateInit2(var strm: z_stream; windowBits: Integer = 15): Integer;
function inflate(var strm: z_stream; flush: Integer): Integer;
function inflateEnd(var strm: z_stream): Integer;
function inflateReset(var strm: z_stream): Integer;
function adler32(adler: LongWord; buf: PByte; len: Cardinal): LongWord;

implementation

var
  SaveExit: Pointer;
  DLLHandle1, DLLHandle2: THandle;
  ErrorMode: Integer;
  WinAPIDLL: Boolean;

procedure NewExit; far;
begin
  ExitProc := SaveExit;
  if WinAPIDLL then
    FreeLibrary(DLLHandle1)
  else
    FreeLibrary(DLLHandle2);
end;

procedure LoadDLL;
begin
  if DLLLoaded then
    Exit;
  ErrorMode := SetErrorMode($8000);
  DLLHandle1 := 0;
  DLLHandle1 := LoadLibrary('zlibwapi.dll');
  DLLHandle2 := 0;
  DLLHandle2 := LoadLibrary('zlib1.dll');
  if not(DLLHandle1 >= 32) then
  begin
    CloseHandle(DLLHandle1);
    DLLHandle1 := 0;
    DLLHandle1 := LoadLibrary('zlib.dll');
  end;
  WinAPIDLL := DLLHandle1 >= 32;
  if (DLLHandle1 >= 32) or (DLLHandle2 >= 32) then
  begin
    DLLLoaded := True;
    SaveExit := ExitProc;
    ExitProc := @NewExit;
    if WinAPIDLL then
    begin
      @_zlibVersion := GetProcAddress(DLLHandle1, 'zlibVersion');
      Assert(@_zlibVersion <> nil);
      @s_deflateInit2_ := GetProcAddress(DLLHandle1, 'deflateInit2_');
      Assert(@s_deflateInit2_ <> nil);
      @s_deflate := GetProcAddress(DLLHandle1, 'deflate');
      Assert(@s_deflate <> nil);
      @s_deflateEnd := GetProcAddress(DLLHandle1, 'deflateEnd');
      Assert(@s_deflateEnd <> nil);
      @s_inflateInit2_ := GetProcAddress(DLLHandle1, 'inflateInit2_');
      Assert(@s_inflateInit2_ <> nil);
      @s_inflate := GetProcAddress(DLLHandle1, 'inflate');
      Assert(@s_inflate <> nil);
      @s_inflateEnd := GetProcAddress(DLLHandle1, 'inflateEnd');
      Assert(@s_inflateEnd <> nil);
      @s_inflateReset := GetProcAddress(DLLHandle1, 'inflateReset');
      Assert(@s_inflateReset <> nil);
      @s_adler32 := GetProcAddress(DLLHandle1, 'adler32');
      Assert(@s_adler32 <> nil);
      @s_deflateTune:=GetProcAddress(DLLHandle1,'deflateTune');
      Assert(@s_deflateTune<>nil);
    end
    else
    begin
      @_zlibVersion := GetProcAddress(DLLHandle2, 'zlibVersion');
      Assert(@_zlibVersion <> nil);
      @c_deflateInit2_ := GetProcAddress(DLLHandle2, 'deflateInit2_');
      Assert(@c_deflateInit2_ <> nil);
      @c_deflate := GetProcAddress(DLLHandle2, 'deflate');
      Assert(@c_deflate <> nil);
      @c_deflateEnd := GetProcAddress(DLLHandle2, 'deflateEnd');
      Assert(@c_deflateEnd <> nil);
      @c_inflateInit2_ := GetProcAddress(DLLHandle2, 'inflateInit2_');
      Assert(@c_inflateInit2_ <> nil);
      @c_inflate := GetProcAddress(DLLHandle2, 'inflate');
      Assert(@c_inflate <> nil);
      @c_inflateEnd := GetProcAddress(DLLHandle2, 'inflateEnd');
      Assert(@c_inflateEnd <> nil);
      @c_inflateReset := GetProcAddress(DLLHandle2, 'inflateReset');
      Assert(@c_inflateReset <> nil);
      @c_adler32 := GetProcAddress(DLLHandle2, 'adler32');
      Assert(@c_adler32 <> nil);
      @c_deflateTune:=GetProcAddress(DLLHandle2,'deflateTune');
      Assert(@c_deflateTune<>nil);
    end;
  end
  else
    DLLLoaded := False;
  SetErrorMode(ErrorMode);
end;

function deflateInit2(var strm: z_stream; level: Integer;
  method: Integer = Z_DEFLATED; windowBits: Integer = 15; memLevel: Integer = 8;
  strategy: Integer = Z_DEFAULT_STRATEGY): Integer;
begin
  if not DLLLoaded then
    Result := System.Zlib.deflateInit2_(strm, level, method, windowBits,
      memLevel, strategy, System.Zlib.ZLIB_VERSION, SizeOf(z_stream))
  else
  begin
    if WinAPIDLL then
      Result := s_deflateInit2_(strm, level, method, windowBits, memLevel,
        strategy, _zlibVersion, SizeOf(z_stream))
    else
      Result := c_deflateInit2_(strm, level, method, windowBits, memLevel,
        strategy, _zlibVersion, SizeOf(z_stream));
  end;
end;

function deflate(var strm: z_stream; flush: Integer): Integer;
begin
  if not DLLLoaded then
    Result := System.Zlib.deflate(strm, flush)
  else
  begin
    if WinAPIDLL then
      Result := s_deflate(strm, flush)
    else
      Result := c_deflate(strm, flush);
  end;
end;

function deflateEnd(var strm: z_stream): Integer;
begin
  if not DLLLoaded then
    Result := System.Zlib.deflateEnd(strm)
  else
  begin
    if WinAPIDLL then
      Result := s_deflateEnd(strm)
    else
      Result := c_deflateEnd(strm);
  end;
end;

function inflateInit2(var strm: z_stream; windowBits: Integer = 15): Integer;
begin
  if not DLLLoaded then
    Result := System.Zlib.inflateInit2_(strm, windowBits,
      System.Zlib.ZLIB_VERSION, SizeOf(z_stream))
  else
  begin
    if WinAPIDLL then
      Result := s_inflateInit2_(strm, windowBits, _zlibVersion,
        SizeOf(z_stream))
    else
      Result := c_inflateInit2_(strm, windowBits, _zlibVersion,
        SizeOf(z_stream));
  end;
end;

function inflate(var strm: z_stream; flush: Integer): Integer;
begin
  if not DLLLoaded then
    Result := System.Zlib.inflate(strm, flush)
  else
  begin
    if WinAPIDLL then
      Result := s_inflate(strm, flush)
    else
      Result := c_inflate(strm, flush);
  end;
end;

function inflateEnd(var strm: z_stream): Integer;
begin
  if not DLLLoaded then
    Result := System.Zlib.inflateEnd(strm)
  else
  begin
    if WinAPIDLL then
      Result := s_inflateEnd(strm)
    else
      Result := c_inflateEnd(strm);
  end;
end;

function inflateReset(var strm: z_stream): Integer;
begin
  if not DLLLoaded then
    Result := System.Zlib.inflateReset(strm)
  else
  begin
    if WinAPIDLL then
      Result := s_inflateReset(strm)
    else
      Result := c_inflateReset(strm);
  end;
end;

function adler32(adler: LongWord; buf: PByte; len: Cardinal): LongWord;
begin
  if not DLLLoaded then
    Result := System.Zlib.adler32(adler, buf, len)
  else
  begin
    if WinAPIDLL then
      Result := s_adler32(adler, buf, len)
    else
      Result := c_adler32(adler, buf, len);
  end;
end;

function deflateTune(var strm: z_stream;
  good_length, max_lazy, nice_length, max_chain: Integer): Integer;
  begin
    if not DLLLoaded then
     Result:=System.Zlib.deflateTune(strm,good_length,max_lazy,nice_length,max_chain)
     else
     begin
       if WinAPIDLL then
          Result:= s_deflateTune(strm,good_length,max_lazy,nice_length,max_chain)
          else
          Result:=c_deflateTune(strm,good_length,max_lazy,nice_length,max_chain);
     end;
  end;

begin
  LoadDLL;

end.

