local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.RotationTalk.Config)
local Data = require(script.Parent.DataService)
local Economy = require(script.Parent.EconomyService)
local Reputation = require(script.Parent.ReputationService)
local World = require(script.Parent.WorldService)
local Round = require(script.Parent.RoundService)
local Remotes = Instance.new("Folder"); Remotes.Name = "Remotes"; Remotes.Parent = ReplicatedStorage.RotationTalk
local function remote(name)
    local r = Instance.new("RemoteEvent"); r.Name = name; r.Parent = Remotes; return r
end
local Action, State, Notice = remote("Action"), remote("State"), remote("Notice")
local rate = {}
World:Build(); Economy:Init(Data); Reputation:Init(Data); Round:Init(Data, Economy, Reputation, World, State)
Data:Start()
local function joined(player)
    if #Players:GetPlayers() > Config.MaxPlayers then player:Kick(string.format("이 서버는 최대 %d명입니다.", Config.MaxPlayers)); return end
    if not Data:Load(player) then return end
    Economy:Join(player.UserId)
    player.CharacterAdded:Connect(function(character)
        character:WaitForChild("Humanoid", 10)
        task.wait(0.3)
        if not player.Parent then return end
        local pair = Round.byUser[player.UserId]
        if pair and Round.phase == "Playing" then World:Seat(player, pair.index, pair.a == player.UserId and 1 or 2)
        else World:Lobby(player) end
    end)
    if player.Character then World:Lobby(player) end
    State:FireClient(player, Round:Snapshot(player.UserId))
end
Players.PlayerAdded:Connect(joined)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(joined, player) end
Players.PlayerRemoving:Connect(function(player)
    Round:Cancel(player.UserId); Economy.sessions[player.UserId] = nil; rate[player.UserId] = nil
    Data:Release(player)
end)
Action.OnServerEvent:Connect(function(player, action, payload)
    if type(action) ~= "string" or type(payload) ~= "table" or not Data:Get(player.UserId) then return end
    local now = os.clock()
    local r = rate[player.UserId] or { start = now, count = 0 }
    rate[player.UserId] = r
    if now - r.start >= 2 then r.start = now; r.count = 0 end
    r.count += 1; if r.count > 8 then return end
    if action == "Answer" then
        if type(payload.nonce) ~= "string" or #payload.nonce > 80 then return end
        if not Round:Answer(player.UserId, payload.nonce, payload.choice) then Notice:FireClient(player, "이미 선택했거나 종료된 질문이에요.") end
    elseif action == "React" then
        if type(payload.kind) ~= "string" or #payload.kind > 20 then return end
        local ok, reason = Round:React(player.UserId, payload.kind, payload.serial)
        Notice:FireClient(player, ok and "따뜻한 반응을 보냈어요!" or (reason == "pair_limit" and "같은 친구에게는 24시간에 한 번 보낼 수 있어요." or "지금은 반응을 보낼 수 없어요. 일일 한도나 라운드를 확인해 주세요."))
    elseif action == "Skip" or action == "Avoid" then
        if payload.serial ~= Round.serial then return end
        if Round:Skip(player.UserId, action == "Avoid") then
            Notice:FireClient(player, action == "Avoid" and "다시 배정하지 않도록 저장했어요. 채팅 차단은 Roblox 메뉴에서 설정해 주세요." or "대기 공간으로 이동했어요. 다음 라운드에 참여해요.")
        end
    elseif action == "Refresh" then
        State:FireClient(player, Round:Snapshot(player.UserId)); return
    end
    State:FireClient(player, Round:Snapshot(player.UserId))
end)
task.spawn(function()
    local previous = os.clock()
    while true do
        task.wait(1)
        local now = os.clock(); Round:Tick(math.min(now - previous, 2)); previous = now
    end
end)
