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
  CETCPSocket:TCETCPSocket=nil;
  AcceptedSocket:TCETCPSocket=nil;
begin
  Key_ := True;
  CETCPSocket:=TCETCPSocket.Create(True,res);
  if (res = -1) then
  begin
    Writeln('Socket Error');
    ReadLn;
    Halt;
  end
  else
    writeln('Socket created - OK');
  if (CETCPSocket.Bind(7667,'0',True) = -1) then
  begin
    Writeln('Socket binding Error');
    ReadLn;
    Halt;
  end
  else
    writeln('Socket binded - OK');
  Getmem(buf,CESocketBufferSize);
  while Key_ do
  begin
    if not Assigned(AcceptedSocket) then
      AcceptedSocket:=CETCPSocket.Accept
    else
    begin
    recvbyte:=CETCPSocket.Recive(buf,AcceptedSocket);
    WriteLn('Recived bytes: '+IntToStr(recvbyte));
    WriteLn('Connection info, Remote IP: '+CETCPSocket.GetConnectionInfo.IP);
    for icnt:=0 to recvbyte-1 do
    Write(Char(buf[icnt]));
    writeLN('');
    if recvbyte>1 then
    if (Char(buf[0])=#13) and (Char(buf[1])=#10) then
    break;
    end;
    Sleep(1);
  end;
  FreeMemAndNil(buf);
  FreeAndNil(CETCPSocket);
end.
