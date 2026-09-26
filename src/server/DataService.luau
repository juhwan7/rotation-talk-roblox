local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("RotationTalk")
local Config = require(Shared.Config)
local Rules = require(Shared.Rules)
local Data = { profiles = {}, closing = false }
local token = game.JobId ~= "" and game.JobId or HttpService:GenerateGUID(false)
local temporary = RunService:IsStudio() and not Config.StudioPersistence
-- Unpublished Studio places must not request a DataStore, even for initialization.
local store = if temporary then nil else DataStoreService:GetDataStore(Config.StoreName)

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for k, v in pairs(value) do result[k] = copy(v) end
    return result
end

local function valid(p)
    if type(p) ~= "table" or p.schema ~= 1 then return false end
    for _, key in ipairs({ "coins", "rounds", "answers", "reputationDay", "reputationToday" }) do
        local v = p[key]
        if type(v) ~= "number" or v ~= v or v < 0 or v == math.huge or v % 1 ~= 0 then return false end
    end
    for _, key in ipairs({ "reputation", "receivedFrom", "cosmetics", "titles", "cards", "settings", "avoided" }) do
        if type(p[key]) ~= "table" then return false end
    end
    return true
end

function Data:Load(player)
    local record
    if temporary then record = { data = Rules.newProfile(), leaseUntil = math.huge }
    else
        for attempt = 1, 3 do
            local ok, result = pcall(function()
                return store:UpdateAsync("u_" .. player.UserId, function(old)
                    if old and (type(old) ~= "table" or not valid(old.data)) then return nil end
                    if old and old.owner and old.owner ~= token and (old.leaseUntil or 0) > os.time() then return nil end
                    return { data = old and old.data or Rules.newProfile(), owner = token,
                        leaseUntil = os.time() + Config.SessionLeaseSeconds }
                end)
            end)
            if ok and result and result.owner == token then record = result; break end
            if attempt < 3 then task.wait(attempt * 2) end
        end
    end
    if not record then
        if player.Parent then player:Kick("저장 데이터를 안전하게 열 수 없습니다. 잠시 후 다시 접속해 주세요.") end
        return false
    end
    self.profiles[player.UserId] = { data = record.data, leaseUntil = record.leaseUntil, busy = false }
    player:SetAttribute("TemporaryData", temporary)
    if self.closing or not player.Parent then self:Release(player); return false end
    return true
end

function Data:Get(id)
    local entry = self.profiles[id]
    if entry and not entry.releasing and entry.leaseUntil > os.time() then return entry.data end
    return nil
end

function Data:Save(id, release)
    local entry = self.profiles[id]
    if not entry then return true end
    if entry.busy then return false end
    if temporary then return true end
    entry.busy = true
    local snapshot = copy(entry.data)
    local ok, result = pcall(function()
        return store:UpdateAsync("u_" .. id, function(old)
            if not old or old.owner ~= token then return nil end
            return { data = snapshot, owner = if release then nil else token,
                leaseUntil = if release then 0 else os.time() + Config.SessionLeaseSeconds }
        end)
    end)
    entry.busy = false
    if ok and result and (release or result.owner == token) then
        entry.leaseUntil = result.leaseUntil
        return true
    end
    warn("RotationTalk save failed for user", id)
    return false
end

function Data:Release(player)
    local id = player.UserId
    local entry = self.profiles[id]
    if not entry or entry.releasing then return end
    entry.releasing = true
    local deadline = os.clock() + 20
    repeat
        if not entry.busy and self:Save(id, true) then self.profiles[id] = nil; return end
        task.wait(1)
    until os.clock() >= deadline
    self.profiles[id] = nil
    warn("RotationTalk final save exhausted; last autosave retained", id)
end

function Data:Start()
    task.spawn(function()
        while not self.closing do
            task.wait(Config.AutosaveSeconds)
            for id, entry in pairs(self.profiles) do
                if not entry.releasing then
                    task.spawn(function()
                        self:Save(id, false)
                        if entry.leaseUntil <= os.time() then
                            local player = game:GetService("Players"):GetPlayerByUserId(id)
                            if player then player:Kick("저장 연결이 끊겼습니다. 다시 접속해 주세요.") end
                        end
                    end)
                end
            end
        end
    end)
    game:BindToClose(function()
        self.closing = true
        for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
            task.spawn(function() self:Release(player) end)
        end
        local deadline = os.clock() + 25
        while next(self.profiles) and os.clock() < deadline do task.wait(0.2) end
    end)
end
return Data
