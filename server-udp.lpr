program server;

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Sockets,
  Classes,
  SysUtils, CESockets;

var
  buf: Pbyte;
  Key_: boolean;
  res:integer=0;
  recvbyte:integer=0;
  icnt:integer;
  CEUDPSocket:TCEUDPSocket=nil;
begin
  Key_ := True;
  CEUDPSocket:=TCEUDPSocket.Create(True,res);
  if (res = -1) then
  begin
    Writeln('Socket Error');
    ReadLn;
    Halt;
  end
  else
    writeln('Socket created - OK');
  if (CEUDPSocket.Bind(7667,'0') = -1) then
  begin
    Writeln('Socket binding Error');
    ReadLn;
    Halt;
  end
  else
    writeln('Socket binded - OK');
    while Key_ do
  begin
    Getmem(buf,CESocketBufferSize);
    recvbyte:=CEUDPSocket.Recive(buf); //fprecv(Sock, buf, 200, 0);
    WriteLn('Recived bytes: '+IntToStr(recvbyte));
    WriteLn('Connection info, Remote IP: '+CEUDPSocket.GetConnectionInfo.IP);
    for icnt:=0 to recvbyte-1 do
    Write(Char(buf[icnt]));
    writeLN('');
    if recvbyte>1 then
    if (Char(buf[0])=#13) and (Char(buf[1])=#10) then
    break;
    FreeMemAndNil(buf);
    Sleep(1);
  end;
  FreeAndNil(CEUDPSocket);
end.
