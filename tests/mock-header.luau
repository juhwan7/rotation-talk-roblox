local clock = 1000
local epoch = 2000000000
local os = { clock = function() return clock end, time = function() return epoch end }
local task = { wait = function(n) clock += n or 0; epoch += n or 0 end, spawn = function(f) f() end }
local warnings = {}
local warn = function(...) table.insert(warnings, {...}) end
local loaders, loaded = {}, {}
local references = setmetatable({}, { __index = function(_, k) return k end })
local script = { Parent = references }
local players = {}
local Players = {}
function Players:GetPlayers()
    local list = {}; for _, p in pairs(players) do table.insert(list, p) end
    table.sort(list, function(a,b) return a.UserId < b.UserId end); return list
end
function Players:GetPlayerByUserId(id) return players[id] end
local storage = { RotationTalk = references }
function storage:WaitForChild() return references end
local mockStore = { values = {}, fail = false, calls = 0 }
function mockStore:UpdateAsync(key, callback)
    self.calls += 1
    if self.fail then error("injected storage failure") end
    local updated = callback(self.values[key])
    if updated then self.values[key] = updated end
    return updated
end
local game = { JobId = "server-test", GetService = function(_, name)
    if name == "Players" then return Players end
    if name == "ReplicatedStorage" then return storage end
    if name == "DataStoreService" then return { GetDataStore = function() return mockStore end } end
    if name == "RunService" then return { IsStudio = function() return false end } end
    if name == "HttpService" then return { GenerateGUID = function() return "test" end } end
    error("unmocked service " .. name)
end }
local function require(name)
    if not loaded[name] then loaded[name] = loaders[name]() end
    return loaded[name]
end
