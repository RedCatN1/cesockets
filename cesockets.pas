unit CESockets;

{$mode ObjFPC}{$H+}

interface

uses
  Sockets,
  Classes,
  SysUtils;

Const
  CESocketBufferSize=2048;
  CE_BUFFER_INPUT = 0;
  CE_BUFFER_OUTPUT = 1;

Type
  TCEConnInfo = record
    IP:String;
    Port:Integer;
  end;

 Type
   PCEPacket= ^TCEPacket;
  TCEPacket = record
    Data:Pointer;
    DataSize:LongInt;
  end;
type
  TCEUDPSocket = class(TObject)
  private
    FSocket:longint;
    FSourceAddr:TInetSockAddr;
    FDestinationAddr:TInetSockAddr;
    FSourceAddrSize:longint;
    FDestinationAddrSize:longint;
    FSockUseBroadcast:boolean;
  public
    constructor Create(EnableReuse:boolean;var Result:longint);
    function Bind(BindPort:longint;BindAddress:string):longint;
    Function GetConnectionInfo:TCEConnInfo;
    Function SetBroadcast(BroadState:boolean):longint;
    Function Recive(Buffer:pointer):longint;
    Function Send(Buffer:pointer;BufferSize:longint;SendPort:longint;SendAddress:string):longint;
    destructor Destroy;override;
  end;

  type
  TCEUDPTThreadingSocket = class(TThread)
  private
    FSocket:TCEUDPSocket;
    FInputBuffer:TList;
    FOutputBuffer:TList;
    BufferCS:TRTLCriticalSection;
    GetInBufferSizeEvent:PRTLEvent;
    GetOutBufferSizeEvent:PRTLEvent;
    Function ReciveInternal(Buffer:pointer):longint;
    Function SendInternal(Buffer:pointer;BufferSize:longint;SendPort:longint;SendAddress:string):longint;
  protected
    procedure Execute; override;
  public
    constructor Create(EnableReuse:boolean;var Result:longint);
    function Bind(BindPort:longint;BindAddress:string):longint;
    Function GetConnectionInfo:TCEConnInfo;
    Function SetBroadcast(BroadState:boolean):longint;
    Function Send(Buffer:pointer;BufferSize:longint;SendPort:longint;SendAddress:string):longint;
    destructor Destroy;override;
  end;

  type
  TCETCPSocket = class(TObject)
    FSocket:longint;
  private
    FSourceAddr:TInetSockAddr;
    FDestinationAddr:TInetSockAddr;
    FSourceAddrSize:longint;
    FDestinationAddrSize:longint;
    FAcceptedSessions:TList;
    FEnableReuse:Boolean;
    FSocketTag:string;
    FSocketId:Double;
    FNotCloseSocket:boolean;
    function GetSocketIndexById(SockID:Double):integer;
    function GetSocketIndexByTag(SockTag:string):integer;
    function GetSocketIndexByObj(CETCPSocket:TCETCPSocket):integer;
  public
    constructor Create(EnableReuse:boolean;var Result:longint;SocketTag:string='');
    constructor Create(Socket:longint;EnableReuse:boolean;var Result:longint;SocketTag:string='';SocketID:Double=0);overload;
    function Bind(BindPort:longint;BindAddress:string;AndListen:boolean):longint;
    Function GetConnectionInfo:TCEConnInfo;
    Function SetListen:longint;
    Function Accept(SocketTag:string=''):TCETCPSocket;
    Function Recive(Buffer:pointer):longint;
    Function Connect(SendPort:longint;SendAddress:string):longint;
    Function Send(Buffer:pointer;BufferSize:longint):longint;
    Function Send(Buffer:pointer;BufferSize:longint;AcceptedSocket:TCETCPSocket):longint;overload;
    function GetAcceptedSession(SockID:Double):TCETCPSocket;
    function GetAcceptedSession(SockTag:string):TCETCPSocket;overload;
    function SetNoCloseSocket(Value:boolean):longint;
    function ReleaseAcceptedSession(AcceptedSession:TCETCPSocket;ObjectOnly:boolean=false):longint;
    destructor Destroy;override;
  end;

  type
  TBeforeAccept = function(var SessionTag:string): integer;
  TAfterAccept = function(AcceptedSession:pointer;SessionIndex:integer): integer;
  TAfterRecive = function(SessionID:Double;var SessionTag:string;Data:pointer;var DataSize:integer): string;
  TCETCPTThreadingSocket = class(TThread)
    FSocket:TCETCPSocket;
  private
    FAcceptedSessions:TList;

    FSocketTag:string;
    FSocketId:Double;
    FNotCloseSocket:boolean;
    FIsActiveSession:boolean;
    FEnableInternalInBuffer:boolean;
    FEnableInternalOutBuffer:boolean;
    FMaxQueueSize:integer;
    FReadPos:Integer;
    FWritePos:Integer;
    FReadPackets:Integer;
    FWritePackets:Integer;
    FServerMode:boolean;
    FListenPort:Integer;
    FListenIp:String;
    FBeforeAccept: TBeforeAccept;
    FAfterAccept: TAfterAccept;
    FAfterRecive: TAfterRecive;
    BufferCS:TRTLCriticalSection;
    GetInBufferSizeEvent:PRTLEvent;
    GetOutBufferSizeEvent:PRTLEvent;
    function GetSocketIndexById(SockID:Double):integer;
    function GetSocketIndexByTag(SockTag:string):integer;
    function GetSocketIndexByObj(CETCPSocket:TCETCPTThreadingSocket):integer;
    Function SendInternal(Buffer:pointer;BufferSize:longint):longint;
    Function ReciveInternal(Buffer:pointer):longint;
  protected
    FInputBuffer:TList;
    FOutputBuffer:TList;
    procedure Execute; override;
  public
    constructor Create(EnableReuse:boolean;var Result:longint;ServerMode:boolean;ListenIP:string='0';ListenPort:integer=0;SocketTag:string='');
    constructor Create(Socket:longint;EnableReuse:boolean;var Result:longint;ServerMode:boolean;IsActiveSession:boolean;ListenIP:string='0';ListenPort:integer=0;SocketTag:string='');overload;
    procedure Run;
    function Bind(BindPort:longint;BindAddress:string;AndListen:boolean):longint;
    Function GetConnectionInfo:TCEConnInfo;
    procedure SetInternalInBufferState(Enabled:boolean);
    procedure SetInternalOutBufferState(Enabled:boolean);
    function GetInternalInBufferState:boolean;
    function GetInternalOutBufferState:boolean;
    procedure SetMaxQueueSize(MaxPacketsCount:integer);
    function GetMaxQueueSize:integer;
    procedure SetListenPort(Port:integer);
    function GetListenPort:integer;
    procedure SetListenIp(IP:string);
    function GetListenIp:string;
    function GetSessionID:double;
    function GetSessionTag:string;
    procedure SetSessionTag(TAG:string);
    procedure SetOnBeforeAccept(OnBeforeAccept:TBeforeAccept);
    procedure SetOnAfterAccept(OnAfterAccept:TAfterAccept);
    procedure SetOnAfterRecive(OnAfterRecive:TAfterRecive);
    procedure ReleaseQueuePacket(Packet:PCEPacket);
    function GetNextQueuePacket:PCEPacket;
    Function SetListen:longint;
    Function Accept(SocketTag:string=''):TCETCPTThreadingSocket;
    Function GetPacketSizeFromBuffer(PacketIndex:integer):longint;
    Function GetPacketFromBuffer(PacketIndex:integer;Buffer:pointer):longint;
    Function BufferPacketsCount(BufferType:integer;AcceptedSocket:TCETCPTThreadingSocket=nil):longint;
    Function Connect(SendPort:longint;SendAddress:string):longint;
    Function Send(Buffer:pointer;BufferSize:longint):longint;
    function GetAcceptedSession(SockID:Double):TCETCPTThreadingSocket;
    function GetAcceptedSession(SockTag:string):TCETCPTThreadingSocket;overload;
    function SetNoCloseSocket(Value:boolean):longint;
    function ReleaseAcceptedSession(AcceptedSession:TCETCPTThreadingSocket;ObjectOnly:boolean):longint;
    destructor Destroy;override;
  end;

implementation
//=============================================
//=---------------CEUDPSockets----------------=
//=============================================

//----------------SimpleSocket-----------------

constructor TCEUDPSocket.Create(EnableReuse:boolean;var Result:longint);
var
ReuseVal:longint;
begin
FSourceAddrSize:=SizeOf(FSourceAddr);
FDestinationAddrSize:=SizeOf(FDestinationAddr);
FSocket := fpsocket(AF_INET, SOCK_DGRAM,IPPROTO_UDP );
if (FSocket = -1) then
  begin
    Result:=FSocket;
    Exit;
  end;
if EnableReuse then
ReuseVal:=1
else
ReuseVal:=0;
if (fpsetsockopt(FSocket,SOL_SOCKET,SO_REUSEADDR,@ReuseVal,1)=-1) then
begin
  Result:=-1;
  CloseSocket(FSocket);
  Exit;
end;
end;

Function TCEUDPSocket.Bind(BindPort:longint;BindAddress:string):longint;
begin
FSourceAddr.sin_family:=AF_INET;
FSourceAddr.sin_port:=htons(BindPort);
if (BindAddress='0') or (BindAddress='0.0.0.0') then
FSourceAddr.sin_addr.s_addr := INADDR_ANY
else
FSourceAddr.sin_addr := StrToNetAddr(BindAddress);
if (fpbind(FSocket, @FSourceAddr, FSourceAddrSize) = -1) then
begin
  Result:=-1;
  Exit;
end;
end;

Function TCEUDPSocket.GetConnectionInfo:TCEConnInfo;
begin
Result.IP:=NetAddrToStr(FDestinationAddr.sin_addr);
Result.Port:=FDestinationAddr.sin_port;
end;

Function TCEUDPSocket.SetBroadcast(BroadState:boolean):longint;
var
BroadVal:longint;
begin
if BroadState then
BroadVal:=1
else
BroadVal:=0;
FSockUseBroadcast:=BroadState;
if (fpsetsockopt(FSocket,SOL_SOCKET,SO_BROADCAST,@BroadVal,1)=-1) then
begin
  Result:=-1;
  Exit;
end;
end;

Function TCEUDPSocket.Recive(Buffer:pointer):longint;
begin
Result:=fprecvfrom(FSocket, Buffer, CESocketBufferSize, 0,@FDestinationAddr,@FDestinationAddrSize);
end;

Function TCEUDPSocket.Send(Buffer:pointer;BufferSize:longint;SendPort:longint;SendAddress:string):longint;
begin
FDestinationAddr.sin_family := AF_INET;
FDestinationAddr.sin_Port := htons(SendPort);
if FSockUseBroadcast then
FDestinationAddr.sin_addr := StrToNetAddr('255.255.255.255')
else
FDestinationAddr.sin_addr := StrToNetAddr(SendAddress);
Result:=fpsendto(FSocket, Buffer, BufferSize, 0,@FDestinationAddr,FDestinationAddrSize);
end;

destructor TCEUDPSocket.Destroy;
begin
CloseSocket(FSocket);
inherited
end;

//----------------StreamingSocket--------------

constructor TCEUDPTThreadingSocket.Create(EnableReuse:boolean;var Result:longint);
begin
FSocket:=TCEUDPSocket.Create(EnableReuse,Result);
FInputBuffer:=TList.Create;
FOutputBuffer:=TList.Create;
FreeOnTerminate:=True;
InitCriticalSection(BufferCS);
GetInBufferSizeEvent:=RTLEventCreate;
GetOutBufferSizeEvent:=RTLEventCreate;
RTLEventSetEvent(GetInBufferSizeEvent);
RTLEventSetEvent(GetOutBufferSizeEvent);
inherited Create(False);
end;

procedure TCEUDPTThreadingSocket.Execute;
begin
while not Terminated do
begin

end;
end;

Function TCEUDPTThreadingSocket.Bind(BindPort:longint;BindAddress:string):longint;
begin
Result:=FSocket.Bind(BindPort,BindAddress);
end;

Function TCEUDPTThreadingSocket.GetConnectionInfo:TCEConnInfo;
begin
Result.IP:=FSocket.GetConnectionInfo.IP;
Result.Port:=FSocket.GetConnectionInfo.Port;
end;

Function TCEUDPTThreadingSocket.SetBroadcast(BroadState:boolean):longint;
begin
Result:=FSocket.SetBroadcast(BroadState);
end;

Function TCEUDPTThreadingSocket.ReciveInternal(Buffer:pointer):longint;
begin
Result:=FSocket.Recive(Buffer);
end;

Function TCEUDPTThreadingSocket.SendInternal(Buffer:pointer;BufferSize:longint;SendPort:longint;SendAddress:string):longint;
begin
Result:=FSocket.Send(Buffer,BufferSize,SendPort,SendAddress);
end;

Function TCEUDPTThreadingSocket.Send(Buffer:pointer;BufferSize:longint;SendPort:longint;SendAddress:string):longint;
begin
Result:=SendInternal(Buffer,BufferSize,SendPort,SendAddress);
end;

destructor TCEUDPTThreadingSocket.Destroy;
begin
if Assigned(FInputBuffer) then
  FreeAndNil(FInputBuffer);
if Assigned(FOutputBuffer) then
  FreeAndNil(FOutputBuffer);
DoneCriticalSection(BufferCS);
RTLEventDestroy(GetInBufferSizeEvent);
RTLEventDestroy(GetOutBufferSizeEvent);
FreeAndNil(FSocket);
inherited
end;

//=============================================
//=---------------CETCPSockets----------------=
//=============================================

//----------------SimpleSocket-----------------

function TCETCPSocket.GetSocketIndexById(SockID:Double):integer;
var
i:longint;
begin
Result:=-1;
for i:=0 to FAcceptedSessions.Count-1 do
begin
if Assigned(FAcceptedSessions[i]) then
  if TCETCPSocket(FAcceptedSessions[i]).FSocketId=SockID then
    begin
      Result:=i;
      Break;
    end;
end;
end;

function TCETCPSocket.GetSocketIndexByTag(SockTag:string):integer;
var
i:longint;
begin
Result:=-1;
for i:=0 to FAcceptedSessions.Count-1 do
begin
if Assigned(FAcceptedSessions[i]) then
  if TCETCPSocket(FAcceptedSessions[i]).FSocketTag=SockTag then
    begin
      Result:=i;
      Break;
    end;
end;
end;

function TCETCPSocket.GetSocketIndexByObj(CETCPSocket:TCETCPSocket):integer;
var
i:longint;
begin
Result:=-1;
for i:=0 to FAcceptedSessions.Count-1 do
begin
if Assigned(FAcceptedSessions[i]) then
  if TCETCPSocket(FAcceptedSessions[i])=CETCPSocket then
    begin
      Result:=i;
      Break;
    end;
end;
end;

constructor TCETCPSocket.Create(EnableReuse:boolean;var Result:longint;SocketTag:string='');
var
Socket:longint;
begin
Socket := fpsocket(AF_INET, SOCK_STREAM,0);
if (Socket = -1) then
  begin
    Result:=Socket;
    Exit;
  end
  else
    Create(Socket,EnableReuse,Result,SocketTag);
end;

constructor TCETCPSocket.Create(Socket:longint;EnableReuse:boolean;var Result:longint;SocketTag:string='';SocketID:Double=0);
var
ReuseVal:longint;
begin
FAcceptedSessions:=TList.Create;
FSourceAddrSize:=SizeOf(FSourceAddr);
FDestinationAddrSize:=SizeOf(FDestinationAddr);
FNotCloseSocket:=False;
FSocket := Socket;
if EnableReuse then
ReuseVal:=1
else
ReuseVal:=0;
FEnableReuse:=EnableReuse;
FSocketTag:=SocketTag;
if SocketID=0 then
FSocketId:=Now
else
FSocketId:=SocketID;
//if (fpsetsockopt(FSocket,SOL_SOCKET,SO_REUSEADDR,@ReuseVal,1)=-1) then
//begin
//  Result:=-3;
//  CloseSocket(FSocket);
//  Exit;
//end;
inherited Create;
end;

Function TCETCPSocket.Bind(BindPort:longint;BindAddress:string;AndListen:boolean):longint;
begin
Result:=0;
FSourceAddr.sin_family:=AF_INET;
FSourceAddr.sin_port:=htons(BindPort);
if (BindAddress='0') or (BindAddress='0.0.0.0') then
FSourceAddr.sin_addr.s_addr := INADDR_ANY
else
FSourceAddr.sin_addr := StrToNetAddr(BindAddress);
if (fpbind(FSocket, @FSourceAddr, FSourceAddrSize) = -1) then
begin
  Result:=-2;
  Exit;
end;
if AndListen and (Result>-1) then
  Result:=SetListen;
end;

Function TCETCPSocket.GetConnectionInfo:TCEConnInfo;
begin
Result.IP:=NetAddrToStr(FDestinationAddr.sin_addr);
Result.Port:=FDestinationAddr.sin_port;
end;

Function TCETCPSocket.SetListen:longint;
begin
Result:=0;
If (fplisten(FSocket,1) = -1) then
begin
  Result:=-4;
  Exit;
end;
end;

Function TCETCPSocket.Accept(SocketTag:string=''):TCETCPSocket;
var
AcceptedSocket:longint;
CEAcceptedSocket:TCETCPSocket;
Res:longint=0;
begin
AcceptedSocket:=fpaccept(FSocket,@FDestinationAddr,@FDestinationAddrSize);
CEAcceptedSocket:=TCETCPSocket.Create(AcceptedSocket,FEnableReuse,Res,SocketTag);
if Assigned(CEAcceptedSocket) then
begin
  if Res>-1 then
  begin
    FAcceptedSessions.Add(CEAcceptedSocket);
    Result:=CEAcceptedSocket;
  end
end else
Result:=nil;
end;

Function TCETCPSocket.Recive(Buffer:pointer):longint;
begin
Result:=fprecv(FSocket,Buffer,CESocketBufferSize,0);
end;

Function TCETCPSocket.Connect(SendPort:longint;SendAddress:string):longint;
begin
FDestinationAddr.sin_family := AF_INET;
FDestinationAddr.sin_Port := htons(SendPort);
FDestinationAddr.sin_addr := StrToNetAddr(SendAddress);
Result:=fpconnect(FSocket,@FDestinationAddr,FDestinationAddrSize);
end;

Function TCETCPSocket.Send(Buffer:pointer;BufferSize:longint):longint;
begin
Result:=fpsend(FSocket,Buffer,BufferSize,0);
end;

Function TCETCPSocket.Send(Buffer:pointer;BufferSize:longint;AcceptedSocket:TCETCPSocket):longint;
begin
Result:=AcceptedSocket.Send(Buffer,BufferSize);
end;

function TCETCPSocket.GetAcceptedSession(SockID:Double):TCETCPSocket;
var
SocketIndex:Integer=-1;
begin
SocketIndex:=GetSocketIndexById(SockID);
if Assigned(FAcceptedSessions[SocketIndex]) then
  Result:=TCETCPSocket(FAcceptedSessions[SocketIndex])
else
  Result:=nil;
end;

function TCETCPSocket.GetAcceptedSession(SockTag:string):TCETCPSocket;
var
SocketIndex:Integer=-1;
begin
SocketIndex:=GetSocketIndexByTag(SockTag);
if Assigned(FAcceptedSessions[SocketIndex]) then
  Result:=TCETCPSocket(FAcceptedSessions[SocketIndex])
else
  Result:=nil;
end;

function TCETCPSocket.SetNoCloseSocket(Value:boolean):longint;
begin
Result:=0;
FNotCloseSocket:=Value;
end;

function TCETCPSocket.ReleaseAcceptedSession(AcceptedSession:TCETCPSocket;ObjectOnly:boolean=false):longint;
var
SocketIndex:Integer;
begin
Result:=0;
SocketIndex:=GetSocketIndexByObj(AcceptedSession);
FAcceptedSessions.Delete(SocketIndex);
AcceptedSession.SetNoCloseSocket(ObjectOnly);
if Assigned(AcceptedSession) then
  FreeAndNil(AcceptedSession);
end;

destructor TCETCPSocket.Destroy;
var
i:Integer;
CEAcceptedSocket:TCETCPSocket=nil;
begin
if FAcceptedSessions.Count>0 then
for i:=0 to FAcceptedSessions.Count-1 do
begin
  CEAcceptedSocket:=TCETCPSocket(FAcceptedSessions.Items[i]);
  if Assigned(CEAcceptedSocket) then
    FreeAndNil(CEAcceptedSocket);
end;
if not FNotCloseSocket then
CloseSocket(FSocket);
FreeAndNil(FAcceptedSessions);
inherited
end;

//----------------StreamingSocket--------------

function TCETCPTThreadingSocket.GetSocketIndexById(SockID:Double):integer;
var
i:longint;
begin
Result:=-1;
for i:=0 to FAcceptedSessions.Count-1 do
begin
if Assigned(FAcceptedSessions[i]) then
  if TCETCPTThreadingSocket(FAcceptedSessions[i]).FSocketId=SockID then
    begin
      Result:=i;
      Break;
    end;
end;
end;

function TCETCPTThreadingSocket.GetSocketIndexByTag(SockTag:string):integer;
var
i:longint;
begin
Result:=-1;
for i:=0 to FAcceptedSessions.Count-1 do
begin
if Assigned(FAcceptedSessions[i]) then
  if TCETCPTThreadingSocket(FAcceptedSessions[i]).FSocketTag=SockTag then
    begin
      Result:=i;
      Break;
    end;
end;
end;

function TCETCPTThreadingSocket.GetSocketIndexByObj(CETCPSocket:TCETCPTThreadingSocket):integer;
var
i:longint;
TmpSock:TCETCPTThreadingSocket;
begin
Result:=-1;
for i:=0 to FAcceptedSessions.Count-1 do
begin
if Assigned(FAcceptedSessions[i]) then
begin
  TmpSock:=TCETCPTThreadingSocket(FAcceptedSessions[i]);
  if TmpSock.ThreadID=CETCPSocket.ThreadID then
    begin
      Result:=i;
      Break;
    end;
end;
end;
end;

constructor TCETCPTThreadingSocket.Create(EnableReuse:boolean;var Result:longint;ServerMode:boolean;ListenIP:string='0';ListenPort:integer=0;SocketTag:string='');
var
Socket:longint;
begin
Socket := fpsocket(AF_INET, SOCK_STREAM,0);
if (Socket = -1) then
  begin
    Result:=Socket;
    Exit;
  end
  else
    Create(Socket,EnableReuse,Result,ServerMode,False,ListenIP,ListenPort,SocketTag);
end;

constructor TCETCPTThreadingSocket.Create(Socket:longint;EnableReuse:boolean;var Result:longint;ServerMode:boolean;IsActiveSession:boolean;ListenIP:string='0';ListenPort:integer=0;SocketTag:string='');

begin
FAcceptedSessions:=TList.Create;
FSocketId:=Now;
FSocketTag:=SocketTag;
FSocket:=TCETCPSocket.Create(Socket,EnableReuse,Result,FSocketTag,FSocketId);
FInputBuffer:=TList.Create;
FOutputBuffer:=TList.Create;
FIsActiveSession:=IsActiveSession;
FEnableInternalInBuffer:=False;
FEnableInternalOutBuffer:=False;
FWritePos:=0;
FReadPos:=0;
FWritePackets:=0;
FReadPackets:=0;
FListenPort:=ListenPort;
FListenIp:=ListenIP;
FServerMode:=ServerMode;
FBeforeAccept:=nil;
FAfterAccept:=nil;
FAfterRecive:=nil;
FMaxQueueSize:=100;
if ServerMode then
FIsActiveSession:=False;
if FIsActiveSession then
   FEnableInternalInBuffer:=True ;
InitCriticalSection(BufferCS);
GetInBufferSizeEvent:=RTLEventCreate;
GetOutBufferSizeEvent:=RTLEventCreate;
RTLEventSetEvent(GetInBufferSizeEvent);
RTLEventSetEvent(GetOutBufferSizeEvent);
Bind(FListenPort,FListenIp,FServerMode);
FreeOnTerminate:=True;
inherited Create(True);
end;

procedure TCETCPTThreadingSocket.Run;
begin
Self.Start;
end;

procedure TCETCPTThreadingSocket.Execute;
var
TmpBuffer:pointer=nil;
TmpRecivedSize:longint=0;
TmpCEPacket:PCEPacket=nil;
TmpCEPacket2:PCEPacket=nil;
TmpCETreadingServ:TCETCPTThreadingSocket=nil;
TmpSesId:Double=0;
TmpSesTag:string='';
i:integer=0;
begin
while not Terminated do
begin
if not FIsActiveSession then
  begin
    if Assigned(FBeforeAccept) then
      FBeforeAccept(FSocketTag);
    TmpCETreadingServ:=Accept('');
    TmpSesId:=TmpCETreadingServ.FSocketId;
    TmpSesTag:=TmpCETreadingServ.FSocketTag;
    if Assigned(FAfterAccept) then
      FAfterAccept(TmpCETreadingServ,FAcceptedSessions.Count-1);
  end else
  begin
  try
       RTLEventResetEvent(GetInBufferSizeEvent);
       EnterCriticalSection(BufferCS);
   Getmem(TmpBuffer,CESocketBufferSize);
   TmpRecivedSize:=fprecv(FSocket.FSocket,TmpBuffer,CESocketBufferSize,0);//ReciveInternal(TmpBuffer);
   if TmpRecivedSize>0 then
   if Assigned(FAfterRecive) then
      FAfterRecive(FSocketId,TmpSesTag,TmpBuffer,TmpRecivedSize);
  // TmpCETreadingServ.SetSessionTag(TmpSesTag);
    finally
         LeaveCriticalSection(BufferCS);
         RTLEventSetEvent(GetInBufferSizeEvent);
       end;

   If FEnableInternalInBuffer then
     Begin
       try
        RTLEventResetEvent(GetInBufferSizeEvent);
       EnterCriticalSection(BufferCS);
       Getmem(TmpCEPacket,SizeOf(TCEPacket));
       TmpCEPacket^.DataSize:=TmpRecivedSize;
       Getmem(TmpCEPacket^.Data,TmpRecivedSize);
       Move(TmpBuffer,TmpCEPacket^.Data,TmpRecivedSize);
       Inc(FWritePackets,1);
       if FInputBuffer.Count<FMaxQueueSize then
       begin
         FInputBuffer.Add(TmpCEPacket);
         Inc(FWritePos,1);
       end else
       begin
         if (FWritePos=FInputBuffer.Count) and
             (FInputBuffer.Count>0)then
           FWritePos:=0;
         TmpCEPacket2:=FInputBuffer.Items[FWritePos];
         FInputBuffer.Delete(FWritePos);
         ReleaseQueuePacket(TmpCEPacket2);
         FInputBuffer.Insert(FWritePos,TmpCEPacket);
         Inc(FWritePos,1);
       end;
       finally
         LeaveCriticalSection(BufferCS);
         RTLEventSetEvent(GetInBufferSizeEvent);
       end;
     end;
   If FEnableInternalOutBuffer then
     Begin
       try
       RTLEventResetEvent(GetInBufferSizeEvent);
       EnterCriticalSection(BufferCS);
       if FOutputBuffer.Count>0 then
       for i:=0 to FOutputBuffer.Count-1 do
       begin
         TmpCEPacket:=FOutputBuffer.Items[I];
         SendInternal(TmpCEPacket^.Data,TmpCEPacket^.DataSize);
         ReleaseQueuePacket(TmpCEPacket);
       end;
       FOutputBuffer.Clear;
       finally
         LeaveCriticalSection(BufferCS);
         RTLEventSetEvent(GetInBufferSizeEvent);
       end;
     end;
    try
    RTLEventResetEvent(GetInBufferSizeEvent);
       EnterCriticalSection(BufferCS);
   FreeMemAndNil(TmpBuffer);
     finally
         LeaveCriticalSection(BufferCS);
         RTLEventSetEvent(GetInBufferSizeEvent);
       end;
  end;
end;
end;

Function TCETCPTThreadingSocket.Bind(BindPort:longint;BindAddress:string;AndListen:boolean):longint;
begin
Result:=FSocket.Bind(BindPort,BindAddress,AndListen);
end;

Function TCETCPTThreadingSocket.GetConnectionInfo:TCEConnInfo;
begin
Result.IP:=FSocket.GetConnectionInfo.IP;
Result.Port:=FSocket.GetConnectionInfo.Port;
end;

procedure TCETCPTThreadingSocket.SetInternalInBufferState(Enabled:boolean);
begin
FEnableInternalInBuffer:=Enabled;
end;

procedure TCETCPTThreadingSocket.SetInternalOutBufferState(Enabled:boolean);
begin
FEnableInternalOutBuffer:=Enabled;
end;

function TCETCPTThreadingSocket.GetInternalInBufferState:boolean;
begin
Result:=FEnableInternalInBuffer;
end;

function TCETCPTThreadingSocket.GetInternalOutBufferState:boolean;
begin
Result:=FEnableInternalOutBuffer;
end;

Function TCETCPTThreadingSocket.SetListen:longint;
begin
Result:=FSocket.SetListen;
end;

procedure TCETCPTThreadingSocket.SetMaxQueueSize(MaxPacketsCount:integer);
begin
FMaxQueueSize:=MaxPacketsCount;
end;

function TCETCPTThreadingSocket.GetMaxQueueSize:integer;
begin
Result:=FMaxQueueSize;
end;

procedure TCETCPTThreadingSocket.SetListenPort(Port:integer);
begin
FListenPort:=Port;
end;

function TCETCPTThreadingSocket.GetListenPort:integer;
begin
Result:=FListenPort;
end;

procedure TCETCPTThreadingSocket.SetListenIp(IP:string);
begin
FListenIp:=IP;
end;

function TCETCPTThreadingSocket.GetListenIp:string;
begin
Result:=FListenIp;
end;

function TCETCPTThreadingSocket.GetSessionID:double;
begin
Result:=FSocketId;
end;

function TCETCPTThreadingSocket.GetSessionTag:string;
begin
Result:=FSocketTag;
end;

procedure TCETCPTThreadingSocket.SetSessionTag(TAG:string);
begin
FSocketTag:=TAG;
end;

procedure TCETCPTThreadingSocket.SetOnBeforeAccept(OnBeforeAccept:TBeforeAccept);
begin
FBeforeAccept:=OnBeforeAccept;
end;

procedure TCETCPTThreadingSocket.SetOnAfterAccept(OnAfterAccept:TAfterAccept);
begin
FAfterAccept:=OnAfterAccept;
end;

procedure TCETCPTThreadingSocket.SetOnAfterRecive(OnAfterRecive:TAfterRecive);
begin
FAfterRecive:=OnAfterRecive;
end;

function TCETCPTThreadingSocket.GetNextQueuePacket:PCEPacket;
var
TmpCEPacket:PCEPacket;
begin
if FEnableInternalInBuffer then
begin
  try
//RTLEventWaitFor(GetInBufferSizeEvent);
//EnterCriticalSection(BufferCS);
if FReadPackets<FWritePackets then
begin
if FReadPos=FInputBuffer.Count then
FReadPos:=0;
TmpCEPacket:=FInputBuffer.Items[FReadPos];
Result:=TmpCEPacket;
Inc(FReadPos,1);
Inc(FReadPackets,1);
end else
begin
Result:=nil;
end;
finally
//         LeaveCriticalSection(BufferCS);
       end;
end else
begin
  Result:=nil;
end;
end;

procedure TCETCPTThreadingSocket.ReleaseQueuePacket(Packet:PCEPacket);
begin
FreeMemAndNil(Packet^.Data);
FreeMemAndNil(Packet);
end;

Function TCETCPTThreadingSocket.Accept(SocketTag:string=''):TCETCPTThreadingSocket;
var
TempAcceptedSession:TCETCPSocket;
CEAcceptedSession:TCETCPTThreadingSocket;
Res:longint=0;
begin
TempAcceptedSession:=FSocket.Accept(SocketTag);
CEAcceptedSession:=TCETCPTThreadingSocket.Create(TempAcceptedSession.FSocket,FSocket.FEnableReuse,Res,False,True,SocketTag);
//if Assigned(FBeforeAccept) then
//CEAcceptedSession.SetOnAfterRecive(FBeforeAccept);
//if Assigned(FAfterAccept) then
//CEAcceptedSession.SetOnAfterRecive(FAfterAccept);
if Assigned(FAfterRecive) then
CEAcceptedSession.SetOnAfterRecive(FAfterRecive);
CEAcceptedSession.Run;
FSocket.ReleaseAcceptedSession(TempAcceptedSession,True);
if Assigned(CEAcceptedSession) then
begin
  if Res>-1 then
  begin
    FAcceptedSessions.Add(CEAcceptedSession);
    Result:=CEAcceptedSession;
  end
end else
Result:=nil;
end;

Function TCETCPTThreadingSocket.ReciveInternal(Buffer:pointer):longint;
begin
Result:=FSocket.Recive(Buffer);
end;

Function TCETCPTThreadingSocket.GetPacketSizeFromBuffer(PacketIndex:integer):longint;
var
TmpCEPacket:PCEPacket=nil;
begin
if FEnableInternalInBuffer then
begin
EnterCriticalSection(BufferCS);
if (PacketIndex<FInputBuffer.Count) and
   (PacketIndex>-1) then
TmpCEPacket:=FInputBuffer.Items[PacketIndex];
if TmpCEPacket<>nil then
begin
Result:=TmpCEPacket^.DataSize;
end
else
begin
  Result:=-1;
end;
LeaveCriticalSection(BufferCS);
end else
Result:=-1;
end;

Function TCETCPTThreadingSocket.GetPacketFromBuffer(PacketIndex:integer;Buffer:pointer):longint;
var
TmpCEPacket:PCEPacket=nil;
begin
if FEnableInternalInBuffer then
begin
EnterCriticalSection(BufferCS);
if (PacketIndex<FInputBuffer.Count) and
   (PacketIndex>-1) then
TmpCEPacket:=FInputBuffer.Items[PacketIndex];
if TmpCEPacket<>nil then
begin
Result:=TmpCEPacket^.DataSize;
Move(TmpCEPacket^.DataSize,Buffer,TmpCEPacket^.DataSize);
end
else
begin
  Result:=-1;
end;
LeaveCriticalSection(BufferCS);
end else
Result:=-1;
end;

Function TCETCPTThreadingSocket.BufferPacketsCount(BufferType:integer;AcceptedSocket:TCETCPTThreadingSocket=nil):longint;
begin
//EnterCriticalSection(BufferCS);
if not Assigned(AcceptedSocket) then
begin
If BufferType<1 then
Result:=FInputBuffer.Count
else
Result:=FOutputBuffer.Count;
end else
begin
If BufferType<1 then
Result:=AcceptedSocket.FInputBuffer.Count
else
Result:=AcceptedSocket.FOutputBuffer.Count;
end;
//LeaveCriticalSection(BufferCS);
end;

Function TCETCPTThreadingSocket.Connect(SendPort:longint;SendAddress:string):longint;
begin
Result:=FSocket.Connect(SendPort,SendAddress);
end;

Function TCETCPTThreadingSocket.SendInternal(Buffer:pointer;BufferSize:longint):longint;
begin
  FSocket.Send(Buffer,BufferSize);
end;

Function TCETCPTThreadingSocket.Send(Buffer:pointer;BufferSize:longint):longint;
var
PacketToAdd:PCEPacket;
BufEn:Boolean;
begin
BufEn:=FEnableInternalOutBuffer;

if BufEn then
begin
EnterCriticalSection(BufferCS);
Getmem(PacketToAdd,SizeOf(TCEPacket));
PacketToAdd^.Data:=Buffer;
PacketToAdd^.DataSize:=BufferSize;
Result:=FOutputBuffer.Add(PacketToAdd);
LeaveCriticalSection(BufferCS);
end else
begin
Result:=SendInternal(Buffer,BufferSize);
end;

end;

function TCETCPTThreadingSocket.GetAcceptedSession(SockID:Double):TCETCPTThreadingSocket;
var
SocketIndex:Integer=-1;
begin
SocketIndex:=GetSocketIndexById(SockID);
if Assigned(FAcceptedSessions[SocketIndex]) then
  Result:=TCETCPTThreadingSocket(FAcceptedSessions[SocketIndex])
else
  Result:=nil;
end;

function TCETCPTThreadingSocket.GetAcceptedSession(SockTag:string):TCETCPTThreadingSocket;
var
SocketIndex:Integer=-1;
begin
SocketIndex:=GetSocketIndexByTag(SockTag);
if Assigned(FAcceptedSessions[SocketIndex]) then
  Result:=TCETCPTThreadingSocket(FAcceptedSessions[SocketIndex])
else
  Result:=nil;
end;

function TCETCPTThreadingSocket.SetNoCloseSocket(Value:boolean):longint;
begin
Result:=0;
FNotCloseSocket:=Value;
end;

function TCETCPTThreadingSocket.ReleaseAcceptedSession(AcceptedSession:TCETCPTThreadingSocket;ObjectOnly:boolean):longint;
var
SocketIndex:Integer;
begin
Result:=0;
SocketIndex:=GetSocketIndexByObj(AcceptedSession);
FAcceptedSessions.Delete(SocketIndex);
AcceptedSession.SetNoCloseSocket(ObjectOnly);
if Assigned(AcceptedSession) then
  FreeAndNil(AcceptedSession);
end;

destructor TCETCPTThreadingSocket.Destroy;
var
i:Integer;
CEAcceptedSocket:TCETCPSocket=nil;
begin
if FAcceptedSessions.Count>0 then
for i:=0 to FAcceptedSessions.Count-1 do
begin
  CEAcceptedSocket:=TCETCPSocket(FAcceptedSessions.Items[i]);
  if Assigned(CEAcceptedSocket) then
    FreeAndNil(CEAcceptedSocket);
end;
if Assigned(FInputBuffer) then
  FreeAndNil(FInputBuffer);
if Assigned(FOutputBuffer) then
  FreeAndNil(FOutputBuffer);
DoneCriticalSection(BufferCS);
RTLEventDestroy(GetInBufferSizeEvent);
RTLEventDestroy(GetOutBufferSizeEvent);
if not FNotCloseSocket then
FSocket.SetNoCloseSocket(FNotCloseSocket);
if Assigned(FSocket) then
FreeAndNil(FSocket);
FreeAndNil(FAcceptedSessions);
inherited
end;

end.

