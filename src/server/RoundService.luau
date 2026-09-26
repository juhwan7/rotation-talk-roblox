local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage").RotationTalk
local Config = require(Shared.Config)
local Questions = require(Shared.QuestionData)
local Rules = require(Shared.Rules)
local Match = require(script.Parent.MatchService)
local Round = { phase = "Waiting", serial = 0, pairs = {}, byUser = {}, deadline = 0 }

function Round:Init(data, economy, reputation, world, state)
    self.data = data; self.economy = economy; self.reputation = reputation; self.world = world; self.state = state
end
function Round:ReadyIds()
    local ids = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if self.data:Get(player.UserId) then table.insert(ids, player.UserId) end
    end
    return ids
end
function Round:NextQuestion(pair)
    pair.questionIndex += 1
    pair.question = Questions[((self.serial + pair.index + pair.questionIndex - 3) % #Questions) + 1]
    pair.nonce = tostring(self.serial) .. ":" .. pair.index .. ":" .. pair.questionIndex
    pair.choices = {}; pair.closed = false; pair.matched = false
    pair.questionDeadline = os.clock() + Config.QuestionSeconds
    pair.revealUntil = nil
end
function Round:Begin()
    self.serial += 1; self.pairs = {}; self.byUser = {}
    local ids = self:ReadyIds()
    local matched = Match:Build(ids, self.data)
    for _, id in ipairs(ids) do self.economy:BeginRound(id) end
    for index, idsPair in ipairs(matched) do
        local pair = { a = idsPair[1], b = idsPair[2], index = index, sync = 0, matches = 0,
            questionIndex = 0, given = {}, cancelled = false }
        self:NextQuestion(pair)
        table.insert(self.pairs, pair)
        self.byUser[pair.a] = pair; self.byUser[pair.b] = pair
        self.world:Seat(Players:GetPlayerByUserId(pair.a), index, 1)
        self.world:Seat(Players:GetPlayerByUserId(pair.b), index, 2)
    end
    if #matched == 0 then self.phase = "Waiting"; self.deadline = 0; return end
    self.phase = "Playing"; self.deadline = os.clock() + Config.RoundSeconds
end
function Round:Cancel(id)
    local pair = self.byUser[id]
    if not pair then return end
    pair.cancelled = true
    self.byUser[pair.a] = nil; self.byUser[pair.b] = nil
    for _, userId in ipairs({ pair.a, pair.b }) do
        local player = Players:GetPlayerByUserId(userId)
        if player then self.world:Lobby(player) end
    end
end
function Round:Skip(id, avoid)
    local pair = self.byUser[id]
    if not pair then return false end
    local other = pair.a == id and pair.b or pair.a
    if avoid then
        local p = self.data:Get(id)
        if not p then return false end
        local count = 0; for _ in pairs(p.avoided) do count += 1 end
        if count >= 200 and not p.avoided[tostring(other)] then return false end
        p.avoided[tostring(other)] = true
    end
    self:Cancel(id)
    return true
end
function Round:Answer(id, nonce, choice)
    local pair = self.byUser[id]
    if self.phase ~= "Playing" or not pair or pair.cancelled or not self.data:Get(id) then return false end
    if os.clock() >= self.deadline or os.clock() >= pair.questionDeadline then return false end
    if not Rules.choice(pair, id, choice, nonce) then return false end
    self.economy:Answer(id)
    if pair.closed then
        pair.revealUntil = os.clock() + Config.RevealSeconds
        if pair.matched then pair.sync += Config.MatchSync; pair.matches += 1 end
    end
    return true
end
function Round:React(id, kind, serial)
    if serial ~= self.serial or self.phase ~= "Results" or os.clock() >= self.deadline then return false, "phase" end
    local pair = self.byUser[id]
    if not pair or pair.cancelled then return false, "pair" end
    return self.reputation:Give(id, pair.a == id and pair.b or pair.a, kind, pair)
end
function Round:Finish()
    self.phase = "Results"; self.deadline = os.clock() + Config.ResultsSeconds
    local best = 0
    for _, pair in ipairs(self.pairs) do if not pair.cancelled then best = math.max(best, pair.sync) end end
    for _, pair in ipairs(self.pairs) do
        if not pair.cancelled then
            for _, id in ipairs({ pair.a, pair.b }) do
                local eligible = self.economy:Complete(id)
                if eligible and best > 0 and pair.sync == best then self.economy:Award(id, Config.BestDuoCoins) end
            end
        end
    end
end
function Round:Snapshot(id)
    local p, s = self.data:Get(id), self.economy.sessions[id]
    local pair = self.byUser[id]
    local view = { phase = self.phase, serial = self.serial,
        remaining = math.max(0, math.ceil(self.deadline - os.clock())), coins = p and p.coins or 0,
        roundCoins = s and s.roundCoins or 0, reputation = p and p.reputation or {},
        loading = p == nil, paired = pair ~= nil }
    if not pair then return view end
    local otherId = pair.a == id and pair.b or pair.a
    local other = Players:GetPlayerByUserId(otherId)
    view.partner = other and other.DisplayName or "상대가 나갔어요"
    view.partnerId = otherId; view.tableIndex = pair.index; view.sync = pair.sync; view.matches = pair.matches
    view.reacted = pair.given[id] == true
    if self.phase == "Playing" then
        local elapsed = Config.RoundSeconds - view.remaining
        view.stage = elapsed < Config.RoundSeconds * 0.2 and "서로 알아가기" or (elapsed < Config.RoundSeconds * 0.8 and "자유 대화" or "마무리 선택")
        view.question = pair.question; view.nonce = pair.nonce
        view.answered = pair.choices[id] ~= nil
        view.questionRemaining = math.max(0, math.ceil(pair.questionDeadline - os.clock()))
        if pair.closed then
            if pair.choices[pair.a] and pair.choices[pair.b] then
                view.result = pair.matched and "MATCH · 같은 선택!" or "DIFFERENT · 다른 취향도 좋아요"
                view.myChoice = pair.choices[id]; view.otherChoice = pair.choices[otherId]
            else view.result = "시간 종료 · 다음 질문을 기다려요" end
        end
    end
    return view
end
function Round:Broadcast()
    self.world:Leaderboard(self.pairs)
    for _, player in ipairs(Players:GetPlayers()) do self.state:FireClient(player, self:Snapshot(player.UserId)) end
end
function Round:Tick(dt)
    local now = os.clock()
    if self.phase == "Waiting" then
        if #self:ReadyIds() >= 2 and now >= (self.retryAt or 0) then
            self:Begin(); self.retryAt = now + 5
        end
    elseif self.phase == "Playing" then
        local alive = 0
        for _, pair in ipairs(self.pairs) do
            if not pair.cancelled then
                alive += 1
                if not pair.closed and now >= pair.questionDeadline then
                    pair.closed = true; pair.revealUntil = now + Config.RevealSeconds
                elseif pair.closed and pair.revealUntil and now >= pair.revealUntil then self:NextQuestion(pair) end
                self.economy:Tick(pair.a, dt, true); self.economy:Tick(pair.b, dt, true)
            end
        end
        if alive == 0 then
            self.phase = "Intermission"; self.deadline = now + Config.IntermissionSeconds
        elseif now >= self.deadline then self:Finish() end
    elseif now >= self.deadline then
        if self.phase == "Results" then
            self.phase = "Intermission"; self.deadline = now + Config.IntermissionSeconds
            for _, player in ipairs(Players:GetPlayers()) do self.world:Lobby(player) end
        else self:Begin() end
    end
    self:Broadcast()
end
return Round
