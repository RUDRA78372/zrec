program zrec;

{$APPTYPE CONSOLE}
{$R *.res}
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

uses
  System.SysUtils,
  WinAPI.Windows,
  System.Classes,
  zlibdll in 'zlibdll.pas',
  Utilities in 'Utilities.pas';

{$SETPEFLAGS IMAGE_FILE_RELOCS_STRIPPED}
procedure ShowHelp;
begin
  Writeln('ZREC - A Zlib recompressor by 78372');
  Writeln('');
  Writeln('Usage:');
  Writeln('  zrec e/d Input Output');
  Writeln('  e/d represents encode/decode');
  Writeln('  input/output can be specified as "-" for stdin/stdout');
  Writeln('  stdin is not supported while encoding');
  (* Writeln('');
    Writeln('Options:');
    Writeln('  -f: represents fast mode. For most of the cases this mode should be enough');
    Writeln('  -x: represents extreme mode. Slower and not recommended unless you have a "special" case');
    Writeln('');
    Writeln('Example:');
    Writeln('  zrec e -f testinput.file testoutput.zrec');
    Writeln('  zrec d - - <testoutput.zrec>testinput.file.res '); *)
end;


procedure ZCompress(inMemory: Pointer; outStream: TStream;
  level, InSize, Windowsize, Memlevel: integer);
const
  BufferSize = 65536;
var
  zstream: TZStreamRec;
  outBuffer: array [0 .. BufferSize - 1] of Byte;
  OutSize: integer;
begin
  FillChar(zstream, SizeOf(TZStreamRec), 0);
  zstream.next_in := inMemory;
  zstream.avail_in := InSize;
  DeflateInit2(zstream, level, Z_DEFLATED, Windowsize, Memlevel,
    Z_DEFAULT_STRATEGY);
  zstream.next_out := @outBuffer[0];
  zstream.avail_out := BufferSize;

  while deflate(zstream, Z_FINISH) <> Z_STREAM_END do
  begin
    OutSize := BufferSize - zstream.avail_out;
    outStream.WriteBuffer(outBuffer, OutSize);
    zstream.next_out := @outBuffer[0];
    zstream.avail_out := BufferSize;
  end;
  OutSize := BufferSize - zstream.avail_out;
  outStream.WriteBuffer(outBuffer, OutSize);
  deflateEnd(zstream);
end;


type
  TZInformation = record
    level, Windowsize, Memlevel: shortint;
  end;



var
  MapFile: TMappedfile;
  Bytes: TBytes;
  MS1, MS2: TMemorystream;
  InSize, OutSize, searchpos, Headerpos, Lastpos, size1, Bytesread,Byteswritten: int64;
  ZValid, leveltest: Boolean;
  Inp, Outp: TStream;
  CRC: Cardinal;
  zstream: TZStreamRec;
  outbuff: Pointer;
  Info: TZInformation;
  ZPrec, i, l, Flevel, Zresult: integer;
  CWrite:TConsoleWriter;
begin
  try
    if Paramstr(1) = 'e' then
    begin
    CWrite:=TConsolewriter.Create;
      if Paramstr(paramcount) = '-' then
        Outp := THandleStream.Create(GetStdHandle(STD_OUTPUT_HANDLE))
      else
        Outp := TFileStream.Create(Paramstr(paramcount), fmCreate);
     if ExtractFileDir(Paramstr(paramcount - 1)) = '' then
        MapFile := TMappedFile.Create(Includetrailingbackslash(GetCurrentdir) +
          Paramstr(paramcount - 1))
      else
        MapFile := TMappedFile.Create(Paramstr(paramcount - 1));
     //   Mapfile:=TMemorystream.Create;
       // mapfile.LoadFromFile(Paramstr(paramcount - 1));
      MS1 := TMemorystream.Create;
      MS2 := TMemorystream.Create;
      Writeheader('ZREC-RUDRA', Outp);
      searchpos := 0;
      Lastpos := 0;
      FillChar(zstream, SizeOf(TZStreamRec), 0);
      inflateInit2(zstream);
      GetMem(outbuff, 65536);
      ZPrec := 0;
      Byteswritten:=0;
      // ZCount:=0;
      Cwrite.Wrt('ZREC - A Zlib recompressor by 78372');
      Cwrite.Nextln;
      while searchpos < MapFile.Size - 1 do
      begin
        // ZHeader := PWord(PByte(MapFile.Memory) + searchpos)^;
        if ((PByte(MapFile.Memory) + searchpos)^ and $F = 8) and
          ((PByte(MapFile.Memory) + searchpos + 1)^ and $20 = 0) and
          (Endianswap(PWord(PByte(MapFile.Memory) + searchpos)^) mod $1F = 0)
          and ((((PByte(MapFile.Memory) + searchpos)^ shr 4) + 8) in [9 .. 15])
        then
        begin
          Info.Windowsize := ((PByte(MapFile.Memory) + searchpos)^ shr 4) + 8;
          Flevel := ((PByte(MapFile.Memory) + searchpos + 1)^ shr $6);
          ZValid := True;
          Headerpos := searchpos;
          MapFile.Position := Headerpos;
          zstream.next_in := PByte(MapFile.Memory) + searchpos;
          zstream.avail_in := 64;
          zstream.next_out := outbuff;
          zstream.avail_out := 4096;
          inflatereset(zstream);
          Zresult := inflate(zstream, Z_SYNC_FLUSH);
          if (Zresult in [0, 1]) then
          begin
            MapFile.Position := Headerpos;
            // inflatereset(zstream);
            MS1.Position := 0;
            zstream.next_in := PByte(MapFile.Memory) + searchpos +
              zstream.total_in;
            zstream.avail_in := MapFile.Size - searchpos-zstream.total_in;
            zstream.next_out := outbuff;
            zstream.avail_out := 65536;
            // zresult := inflate(zstream, Z_SYNC_FLUSH);
            OutSize := zstream.total_out;
            MS1.WriteBuffer(outbuff^, OutSize);
            // Insize:=64;
            // if zresult<>Z_STREAM_END then
            while Zresult <> Z_STREAM_END do
            begin
              if (Zresult < Z_OK) or (Zresult = Z_NEED_DICT) then
              begin
                ZValid := False;
                break;
              end;
              zstream.next_out := outbuff;
              zstream.avail_out := 65536;
              Zresult := inflate(zstream, Z_BLOCK);
              OutSize := zstream.total_out - MS1.Position;
              MS1.WriteBuffer(outbuff^, OutSize);
            end;
            InSize := zstream.total_in;
            OutSize := zstream.total_out;
          //  if InSize > OutSize then
            //  ZValid := False;
            if ZValid then
            begin
              leveltest := False;
              CRC := adler32(0, (PByte(MapFile.Memory) + searchpos), InSize);
              // Inc(ZCount);
              if Flevel = 0 then
              begin
                MS2.Position := 0;
                ZCompress(MS1.Memory, MS2, 1, OutSize, Info.Windowsize, 8);
                if MS2.Position = InSize then
                  if adler32(0, MS2.Memory, InSize) = CRC then
                  begin
                    leveltest := True;
                    Info.level := 1;
                    Info.Memlevel := 8;
                  end;
                if (* (Paramstr(2) = '-x') and *) not leveltest then
                begin
                  for l := 9 downto 1 do
                  begin
                  if l = 8 then
                    continue;
                    MS2.Position := 0;
                    ZCompress(MS1.Memory, MS2, 1, OutSize, Info.Windowsize, l);
                    if MS2.Position = InSize then
                      if adler32(0, MS2.Memory, InSize) = CRC then
                      begin
                        leveltest := True;
                        Info.level := 1;
                        Info.Memlevel := l;
                        break;
                      end;
                  end;
                end;
              end;
              if Flevel = 1 then
              begin
                for i := 5 downto 2 do
                begin
                  MS2.Position := 0;
                  ZCompress(MS1.Memory, MS2, i, OutSize, Info.Windowsize, 8);

                  if adler32(0, MS2.Memory, InSize) = CRC then
                  begin
                    leveltest := True;
                    Info.level := i;
                    Info.Memlevel := 8;
                    break;
                  end;
                end;
                if (* (Paramstr(2) = '-x') and *) not leveltest then
                begin
                  for i := 5 downto 2 do
                  begin
                    for l := 9 downto 1 do
                    begin
                    if l = 8 then
                    continue;
                      MS2.Position := 0;
                      ZCompress(MS1.Memory, MS2, i, OutSize,
                        Info.Windowsize, l);
                      if MS2.Position = InSize then
                        if adler32(0, MS2.Memory, InSize) = CRC then
                        begin
                          leveltest := True;
                          Info.level := i;
                          Info.Memlevel := l;
                          break;
                        end;
                    end;
                    if leveltest then
                      break;
                  end;
                end;
              end;
              if Flevel = 2 then
              begin
                MS2.Position := 0;
                ZCompress(MS1.Memory, MS2, 6, OutSize, Info.Windowsize, 8);
                if MS2.Position = InSize then
                  if adler32(0, MS2.Memory, InSize) = CRC then
                  begin
                    leveltest := True;
                    Info.level := 6;
                    Info.Memlevel := 8;
                  end;
                if (* (Paramstr(2) = '-x') and *) not leveltest then
                begin
                  for l := 9 downto 1 do
                  begin
                  if l = 8 then
                    continue;
                    MS2.Position := 0;
                    ZCompress(MS1.Memory, MS2, 6, OutSize, Info.Windowsize, l);
                    if MS2.Position = InSize then
                      if adler32(0, MS2.Memory, InSize) = CRC then
                      begin
                        leveltest := True;
                        Info.level := 6;
                        Info.Memlevel := l;
                        break;
                      end;
                  end;
                end;
              end;
              if Flevel = 3 then
              begin
                for i := 9 downto 7 do
                begin
                  MS2.Position := 0;
                  ZCompress(MS1.Memory, MS2, i, OutSize, Info.Windowsize, 8);
                  if MS2.Position = InSize then
                    if adler32(0, MS2.Memory, InSize) = CRC then
                    begin
                      leveltest := True;
                      Info.level := i;
                      Info.Memlevel := 8;
                      break;
                    end;
                end;
                if (* (Paramstr(2) = '-x') and *) not leveltest then
                begin
                  for i := 9 downto 7 do
                  begin
                    for l := 9 downto 1 do
                    begin
                    if l = 8 then
                    continue;
                      MS2.Position := 0;
                      ZCompress(MS1.Memory, MS2, i, OutSize,
                        Info.Windowsize, l);
                      if MS2.Position = InSize then
                        if adler32(0, MS2.Memory, InSize) = CRC then
                        begin
                          leveltest := True;
                          Info.level := i;
                          Info.Memlevel := l;
                          break;
                        end;
                    end;
                    if leveltest then
                      break;
                  end;
                end;
              end;
              MS2.Position := 0;
              if leveltest then
              begin
                if Headerpos > Lastpos then
                begin
                  MapFile.Position := Lastpos;
                  Writeheader('zrn', Outp);
                  size1 := Headerpos - Lastpos;
                  Outp.WriteBuffer(size1, SizeOf(size1));
                  StreamToStream(MapFile, Outp, 65536, size1);
                  Inc(Lastpos, size1);
                  Inc(byteswritten,size1+SizeOf(size1)+3);
                end;
                Inc(ZPrec);
                Writeheader('zry', Outp);
                Outp.WriteBuffer(Info, SizeOf(Info));
                Outp.WriteBuffer(OutSize, SizeOf(OutSize));
                MS1.Position := 0;
                StreamToStream(MS1, Outp, 65536, OutSize);
                Inc(Lastpos, InSize);
                // MapFile.Position := Lastpos;
                searchpos := Lastpos;
                dec(searchpos);
                Inc(byteswritten,outsize+SizeOf(outsize)+SizeOf(Info)+3);
                (* Setconsoletitle
                  (PWideChar(ConvertKB2TB(MapFile.Position div 1024) + '/' +
                  ConvertKB2TB(MapFile.Size div 1024))); *)
                // SetConsoleTitle(PWideChar(inttostr(ZPrec) + '/'+inttostr(ZCount)));
                CWrite.Wrt(ConvertKB2TB(searchpos div 1024)+ '/' +
                  ConvertKB2TB(MapFile.Size div 1024) + ' >> '+  ConvertKB2TB(Byteswritten div 1024) );
              end;
            end;
            MS1.Position := 0;
          end;
        end;
        Inc(searchpos);
      end;

    //  SetConsoleTitle(PWideChar('Finalizing...'));
      if Lastpos <> MapFile.Size then
      begin
        MapFile.Position := Lastpos;
        Writeheader('zrn', Outp);
        size1 := MapFile.Size - Lastpos;
        Outp.WriteBuffer(size1, SizeOf(size1));
        StreamToStream(MapFile, Outp, 65536, size1);
        inc(byteswritten,size1+ SizeOf(size1)+3);
      end;
      (* Setconsoletitle(PWideChar(ConvertKB2TB(MapFile.Position div 1024) + '/' +
        ConvertKB2TB(MapFile.Size div 1024))); *)

      Writeheader('zre', Outp);
      inc(byteswritten,3);
      CWrite.Wrt(ConvertKB2TB(searchpos div 1024)+ '/' +
                  ConvertKB2TB(MapFile.Size div 1024) + ' >> '+  ConvertKB2TB(Byteswritten div 1024) );
      CWrite.NextLn;
      CWrite.Wrt(inttostr(ZPrec) + ' restorable streams');
      Cwrite.Free;
      freemem(outbuff);
      InflateEnd(zstream);
      MapFile.Free;
      Outp.Free;
      MS1.Free;
      MS2.Free;

    end
    else if Paramstr(1) = 'd' then
    begin
      if Paramstr(paramcount - 1) = '-' then
        Inp := THandleStream.Create(GetStdHandle(STD_INPUT_HANDLE))
      else
        Inp := TFileStream.Create(Paramstr(paramcount - 1), fmOpenRead);
      if Paramstr(paramcount) = '-' then
        Outp := THandleStream.Create(GetStdHandle(STD_OUTPUT_HANDLE))
      else if (Paramstr(paramcount) = '') and (Paramstr(paramcount - 1) = '-')
      then
        Outp := THandleStream.Create(GetStdHandle(STD_OUTPUT_HANDLE))
      else
        Outp := TFileStream.Create(Paramstr(paramcount), fmCreate);
      if not CheckHeader('ZREC-RUDRA', Inp) then
        raise Exception.Create('Invalid input');
      MS1 := TMemorystream.Create;
      Bytesread := 0;
      Setlength(Bytes, 3);
      CWrite:=TConsolewriter.Create;
      Cwrite.Wrt('ZREC - A Zlib recompressor by 78372');
      Cwrite.Nextln;
      // ZPrec:=0;
      // ZCount:=0;
      while True do
      begin
        Inp.ReadBuffer(Bytes[0], 3);
        if StringOf(Bytes) = 'zre' then
          break
        else if StringOf(Bytes) = 'zrn' then
        begin
          Inp.ReadBuffer(size1, SizeOf(size1));
          Inc(Bytesread,size1+SizeOf(size1) + 3);
          StreamToStream(Inp, Outp, 65536, size1);
           Cwrite.wrt(ConvertKB2TB(Bytesread div 1024));
        end
        else if StringOf(Bytes) = 'zry' then
        begin
          MS1.Position := 0;
          Inp.ReadBuffer(Info, SizeOf(Info));
          Inp.ReadBuffer(size1, SizeOf(size1));
          Inc(bytesread,size1+sizeof(size1)+sizeof(info));
          StreamToStream(Inp, MS1, 65536, size1);
          ZCompress(MS1.Memory, Outp, Info.level, size1, Info.Windowsize,
            Info.Memlevel);
          Cwrite.wrt(ConvertKB2TB(Bytesread div 1024));
        end
        else
          raise Exception.Create('Invalid stream');

      end;
      Inp.Free;
      Outp.Free;
      MS1.Free;
      Cwrite.Free;
      // Setconsoletitle(PWideChar(ConvertKB2TB(Bytesread div 1024)));
    end
    else
      ShowHelp;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
