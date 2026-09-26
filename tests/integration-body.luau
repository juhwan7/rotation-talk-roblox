
local checks = 0
local function check(value, message) assert(value, message); checks += 1 end
local Config = require("Config")
local Rules = require("Rules")
local Data = require("DataService")
local Economy = require("EconomyService")
local Reputation = require("ReputationService")
local Round = require("RoundService")
local function player(id)
    local p = { UserId = id, DisplayName = "Player" .. id, Parent = true, attributes = {} }
    function p:SetAttribute(k,v) self.attributes[k] = v end
    function p:Kick(reason) self.kicked = reason end
    players[id] = p; return p
end
local first, second = player(1), player(2)
check(Data:Load(first) and Data:Load(second), "profiles acquired")
check(mockStore.values.u_1.owner == game.JobId, "session lease acquired")
Data:Get(1).coins = 22
check(Data:Save(1, false) and mockStore.values.u_1.data.coins == 22, "save writes snapshot")
Data:Get(1).coins = 23
check(mockStore.values.u_1.data.coins == 22, "snapshot is deep copied")
mockStore.values.u_3 = { data = Rules.newProfile(), owner = "other-server", leaseUntil = epoch + 180 }
local third = player(3)
check(not Data:Load(third) and third.kicked ~= nil, "foreign active lease rejected")
check(mockStore.values.u_3.owner == "other-server", "foreign record not overwritten")
players[3] = nil
mockStore.fail = true
local fourth = player(4)
check(not Data:Load(fourth) and mockStore.values.u_4 == nil, "failed load never writes default profile")
players[4] = nil
local before = Data.profiles[1].leaseUntil
check(not Data:Save(1, false) and Data.profiles[1].leaseUntil == before, "failed save does not extend lease")
mockStore.fail = false
local seats, lobby = {}, {}
local World = {
    Seat = function(_, p, index, side) seats[p.UserId] = {index, side} end,
    Lobby = function(_, p) lobby[p.UserId] = true end,
    Leaderboard = function() end,
}
local states = {}
local State = { FireClient = function(_, p, v) states[p.UserId] = v end }
Economy:Init(Data); Economy:Join(1); Economy:Join(2)
Reputation:Init(Data); Round:Init(Data, Economy, Reputation, World, State)
Round:Begin()
check(Round.phase == "Playing" and #Round.pairs == 1, "round begins with two users")
check(seats[1][1] == seats[2][1] and seats[1][2] ~= seats[2][2], "shared table different seats")
local pair = Round.byUser[1]
local coins = Data:Get(1).coins
check(Round:Answer(1, pair.nonce, 1), "current answer accepted")
check(Data:Get(1).coins == coins + 5, "question reward credited")
local view = Round:Snapshot(2)
check(view.otherChoice == nil and view.myChoice == nil and view.result == nil, "opponent snapshot conceals answer")
check(not Round:Answer(1, pair.nonce, 2) and Data:Get(1).coins == coins + 5, "duplicate answer no extra reward")
check(Round:Answer(2, pair.nonce, 1) and pair.sync == 10, "same answer scores once")
view = Round:Snapshot(2)
check(view.myChoice == 1 and view.otherChoice == 1 and view.result ~= nil, "both answers reveal")
local oldNonce = pair.nonce
clock += 8; Round:Tick(1)
check(pair.nonce ~= oldNonce and not Round:Answer(1, oldNonce, 1), "old nonce rejected after transition")
check(Round:Answer(1, pair.nonce, 2), "next question")
clock += 46; Round:Tick(1)
view = Round:Snapshot(2)
check(view.result ~= nil and view.otherChoice == nil, "timeout hides lone answer")
clock += 8; Round:Tick(1)
check(not pair.closed, "timeout progresses")
local session = Economy.sessions[1]
session.attendance = 299; session.lastAction = clock
coins = Data:Get(1).coins
Economy:Tick(1, 1, true)
check(Data:Get(1).coins == coins + 50 and session.attendance == 0, "five active minutes pay once")
session.lastAction = clock - 91
Economy:Tick(1, 300, true)
check(session.attendance == 0, "idle earns no attendance")
session.lastAction = clock
Economy:Tick(1, 300, false)
check(session.attendance == 0, "lobby earns no attendance")
session.roundAnswers = 3; session.roundActive = 300
Economy.sessions[2].roundAnswers = 0; Economy.sessions[2].roundActive = 0
coins = Data:Get(1).coins
Round:Finish()
check(Data:Get(1).coins == coins + 120, "completion and best duo")
check(Data:Get(2).rounds == 0, "inactive player has no completion")
check(not Round:Answer(1, pair.nonce, 1), "result stage rejects answers")
check(not Round:React(1, "kind", Round.serial - 1), "stale reputation round")
check(Round:React(1, "kind", Round.serial), "valid reaction")
check(Data:Get(2).reputation.kind == 1, "receiver counter")
check(not Round:React(1, "funny", Round.serial), "round reaction cannot repeat")
clock += 21; Round:Tick(1)
check(Round.phase == "Intermission" and lobby[1], "results to rotation")
clock += 9; Round:Tick(1)
check(Round.phase == "Playing" and Round.serial == 2, "automatic next round")
check(not Round:React(1, "kind", Round.serial), "playing stage rejects reputation")
check(Round:Skip(1, true), "avoid accepted")
check(Data:Get(1).avoided["2"] and Round.byUser[2] == nil, "both return to lobby and avoid stored")
Round:Tick(1); clock += 9; Round:Tick(1)
check(Round.phase == "Waiting" and #Round.pairs == 0, "blocked pair never rematched")
check(Data:Save(1, false) and mockStore.values.u_1.data.avoided["2"], "avoid persisted")
check(Data:Save(2, false), "reputation persisted")
Data:Release(second)
check(Data.profiles[2] == nil and mockStore.values.u_2.owner == nil, "release clears lock")
check(Data:Load(second), "profile reload")
check(not Rules.canReputation(Data:Get(2), 1, 2, epoch, Config), "pair cooldown survives reload")
mockStore.values.u_1.owner = "other-server"
check(not Data:Save(1, false), "lost ownership cannot save")
Data.profiles[1].leaseUntil = epoch - 1
check(Data:Get(1) == nil, "expired lease disables mutations")
studioMode = true
local accesses = storeAccesses
local TempData = loaders.DataService()
check(storeAccesses == accesses, "temporary mode never requests DataStore")
local temporaryPlayer = player(99)
check(TempData:Load(temporaryPlayer), "unpublished Studio profile loads")
check(temporaryPlayer.attributes.TemporaryData == true, "temporary status shown")
TempData:Get(99).coins = 40
check(TempData:Save(99, false) and storeAccesses == accesses, "temporary save stays in memory")
TempData:Release(temporaryPlayer)
check(TempData.profiles[99] == nil and storeAccesses == accesses, "temporary release avoids persistence")
players = {}; seats = {}; states = {}
local FullData = loaders.DataService()
Economy:Init(FullData); Reputation:Init(FullData)
local FullRound = loaders.RoundService()
FullRound:Init(FullData, Economy, Reputation, World, State)
check(Config.TableCount == 20 and Config.MaxPlayers == 40, "twenty two-person tables")
for id = 101, 140 do
    check(FullData:Load(player(id)), "full server profile " .. id)
    Economy:Join(id)
end
FullRound:Begin()
check(#FullRound.pairs == 20 and FullRound.phase == "Playing", "forty players create twenty pairs")
local previous = {}
for _, p in ipairs(FullRound.pairs) do
    check(seats[p.a][1] == p.index and seats[p.b][1] == p.index and seats[p.a][2] ~= seats[p.b][2], "full server seat mapping")
    check(p.index <= Config.TableCount and FullRound:Snapshot(p.a).tableIndex == p.index, "valid table HUD index")
    previous[p.a] = p.b; previous[p.b] = p.a
end
local last = FullRound.pairs[20]
check(FullRound:Answer(last.a, last.nonce, 1), "table twenty accepts answer")
check(FullRound:Snapshot(last.b).otherChoice == nil, "table twenty answer privacy")
FullRound:Finish(); FullRound:Begin()
check(#FullRound.pairs == 20, "forty players rotate without loss")
for _, p in ipairs(FullRound.pairs) do check(previous[p.a] ~= p.b, "full server avoids previous partner") end
players[140] = nil
FullRound:Begin()
check(#FullRound.pairs == 19, "thirty nine players create nineteen pairs")
local waiting = 0
for id = 101, 139 do if not FullRound.byUser[id] then waiting += 1 end end
check(waiting == 1, "odd population has exactly one waiting player")
-- One-sided exclusions must still prevent pairing in a large server.
for id = 102, 139 do FullData:Get(101).avoided[tostring(id)] = true end
FullRound:Begin()
check(#FullRound.pairs == 19 and FullRound.byUser[101] == nil, "hard exclusions at capacity")
print("PASS: " .. checks .. " server integration checks (mock services)")
