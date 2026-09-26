local Shared = game:GetService("ReplicatedStorage").RotationTalk
local Config = require(Shared.Config)
local Rules = require(Shared.Rules)
local Economy = { sessions = {} }
function Economy:Init(data) self.data = data end
function Economy:Join(id)
    self.sessions[id] = { lastAction = -math.huge, attendance = 0, roundCoins = 0, roundAnswers = 0, roundActive = 0 }
end
function Economy:BeginRound(id)
    local s = self.sessions[id]
    if s then s.roundCoins = 0; s.roundAnswers = 0; s.roundActive = 0 end
end
function Economy:Award(id, amount)
    local p, s = self.data:Get(id), self.sessions[id]
    if not p or not s then return end
    p.coins = math.min(p.coins + amount, 1000000000)
    s.roundCoins += amount
end
function Economy:Answer(id)
    local p, s = self.data:Get(id), self.sessions[id]
    if not p or not s then return end
    s.lastAction = os.clock(); s.roundAnswers += 1; p.answers += 1
    self:Award(id, Config.QuestionCoins)
end
function Economy:Tick(id, dt, inRound)
    local s = self.sessions[id]
    if not s or os.clock() - s.lastAction > Config.ActiveWindowSeconds then return end
    if not inRound then return end
    s.attendance += dt; s.roundActive += dt
    if s.attendance >= Config.AttendanceSeconds then
        s.attendance -= Config.AttendanceSeconds
        self:Award(id, Config.AttendanceCoins)
    end
end
function Economy:Complete(id)
    local p, s = self.data:Get(id), self.sessions[id]
    if p and s and Rules.completionEligible(s.roundAnswers, s.roundActive, Config.RoundSeconds, Config) then
        p.rounds += 1; self:Award(id, Config.CompletionCoins); return true
    end
    return false
end
return Economy
