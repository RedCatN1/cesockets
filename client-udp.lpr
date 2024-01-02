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
  CEUDPSocket:TCEUDPSocket=nil;
  res:Integer;

begin
  CEUDPSocket:=TCEUDPSocket.Create(True,res);
  if (res = -1) then
  begin
    Writeln('Socket Error');
    ReadLn;
    Halt;
  end
  else
    writeln('Socket created - OK');
  if (CEUDPSocket.Bind(7667,'192.168.8.3') = -1) then
  begin
    Writeln('Socket binding Error');
    ReadLn;
    Halt;
  end
  else
    writeln('Socket binded - OK');
  Key_ := True;
  CEUDPSocket.SetBroadcast(True);
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
  WriteLn('Connect - OK');
  while Key_ do
  begin
      if (CEUDPSocket.Send(buf,12,7667,'192.168.8.3')>0) then
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
  CEUDPSocket.Send(buf,2,7667,'192.168.8.3');
  FreeMemAndNil(buf);
  FreeAndNil(CEUDPSocket);
end.
