program client;

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$ifdef windows}
   Windows, winsock,
  {$endif}
  ctypes,
  Sockets,
  Classes,
  SysUtils,CESockets;

var
  buf: PChar;
  Key_: boolean;
  PacketsCount: integer = 50;
  SendedPacketsCount: integer = 0;
  CETCPSocket:TCETCPSocket=nil;
  res:Integer;

begin
  CETCPSocket:=TCETCPSocket.Create(True,res);
  if (res = -1) then
  begin
    Writeln('Socket Error');
    ReadLn;
    Halt;
  end
  else
    writeln('Socket created - OK');
  if (CETCPSocket.Bind(7667,'192.168.8.3',False) = -1) then
  begin
    Writeln('Socket binding Error');
    ReadLn;
    Halt;
  end
  else
    writeln('Socket binded - OK');
  Key_ := True;
  GetMem(buf,12);
  buf[0] := 'T';
  buf[1] := 'e';
  buf[2] := 's';
  buf[3] := 't';
  buf[4] := 'T';
  buf[5] := 'e';
  buf[6] := 's';
  buf[7] := 't';
  buf[8] := 'T';
  buf[9] := 'e';
  buf[10] := 's';
  buf[11] := 't';
  if CETCPSocket.Connect(7667,'192.168.8.146')<>-1 then
  WriteLn('Connect - OK')
  else
  begin
    WriteLn('Connect - NOT OK');
    FreeMemAndNil(buf);
    FreeAndNil(CETCPSocket);
    halt;
  end;
  while Key_ do
  begin
      if (CETCPSocket.Send(buf,12)>0) then
      begin
        Inc(SendedPacketsCount,1);
        WriteLn('Send - OK');
        if SendedPacketsCount=PacketsCount then
        begin
          FreeMemAndNil(buf);
          Key_ := False;
        end;
      end;
    Sleep(1);
  end;
  GetMem(buf,2);
  buf[0] := #13;
  buf[1] := #10;
  CETCPSocket.Send(buf,2);
  FreeMemAndNil(buf);
  FreeAndNil(CETCPSocket);
end.
