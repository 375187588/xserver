
Ç
protocol.protoprotocol"g
UserGameData
	ullUserID (

szNickName (	
ullRoomCard (
sex (
imgurl (	"5
ReplayWinLose
nickname (	

deltascore ("†
ReplaListInfo

gameresult (
roomid (
tableid (.
ReplayWinLose (2.protocol.ReplayWinLose
datetime (	"…
CL_LoginLobbyReq
account (	
userid (
openid (	
nickname (	
sex (

headimgurl (	
token (	"™
CL_LoginLobbyAck
dwResult (
score (
roomcard (
roomid (
gameid (
room_ip (	
	room_port (
ticket (	"
CL_ReplayListReq"
CL_ReplayListAck"$
CL_ReplayDetailReq
roomid ("
CL_ReplayDetailAck"M
CreateOption
key (	
snvalue (
ssvalue (	
mvalue (	"L
CL_CreateGameReq
nGameID ('
options (2.protocol.CreateOption"o
CL_CreateGameAck
dwResult (
roomid (

ip (	
port (
ticket (	
nGameID (".
CL_JoinGameReq
roomid (
mode ("m
CL_JoinGameAck
dwResult (
roomid (

ip (	
port (
ticket (	
nGameID ("H
CL_AddUserRoomCardReq
userid (
	deltacard (
type (" 
CL_BroadCastAck
count ("e
UserBaseInfo
userid (
nickname (	

headimgurl (	
score (
roomcard ("D
CL_UpdateUserDataAck,
UserBaseInfo (2.protocol.UserBaseInfo"„
EnterGameReq
userid (
roomid (
ticket (	
	reconnect (
latitude (	
	longitude (	
adds (	"
EnterGameAck
err ("'
ChatReq
nMsgID (
text (	"9
ChatAck
wChairID (
nMsgID (
text (	"
HeartBeatReq
time ("
HeartBeatAck
time (" 
UserOfflineAck
userid ("
VoiceChatReq
voice (	"-
VoiceChatAck
userid (
voice (	"
GameSceneReq"
GameLBSVoteReq"
GameLBSVoteAck"
GameLeaveReq".
GameLeaveAck
nResult (
nSeat ("
GameVoteReq
bAgree (")
Vote
nSeat (

nVoteState ("A
GameVoteAck
nDissoveSeat (
vote (2.protocol.Vote"/

VoteResult
nSeat (

nVoteState ("N
GameVoteResultAck
nResult ((

voteResult (2.protocol.VoteResult