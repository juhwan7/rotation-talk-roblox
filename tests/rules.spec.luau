local Rules = require("../src/shared/Rules")
local Config = require("../src/shared/Config")
local Questions = require("../src/shared/QuestionData")
local count = 0
local function check(value, label)
    assert(value, label); count += 1
end
local pair = { a = 1, b = 2, nonce = "r1:q1", choices = {}, closed = false }
check(not Rules.choice(pair, 3, 1, pair.nonce), "outsider rejected")
check(not Rules.choice(pair, 1, 0, pair.nonce), "invalid option rejected")
check(not Rules.choice(pair, 1, 0/0, pair.nonce), "NaN rejected")
check(not Rules.choice(pair, 1, {}, pair.nonce), "table rejected")
check(not Rules.choice(pair, 1, 1, "stale"), "stale nonce rejected")
check(Rules.choice(pair, 1, 1, pair.nonce), "first answer accepted")
check(not pair.closed and pair.choices[2] == nil, "first answer does not reveal")
check(not Rules.choice(pair, 1, 2, pair.nonce), "answer cannot be changed")
check(Rules.choice(pair, 2, 1, pair.nonce) and pair.closed and pair.matched, "matching answer closes")
check(not Rules.choice(pair, 2, 1, pair.nonce), "no double credit")
local different = { a = 1, b = 2, nonce = "r2", choices = {}, closed = false }
Rules.choice(different, 1, 1, "r2"); Rules.choice(different, 2, 2, "r2")
check(different.closed and not different.matched, "different answer closes without match")
local p = Rules.newProfile()
local now = 2000000000
check(not Rules.canReputation(p, 1, 1, now, Config), "self reputation rejected")
check(Rules.canReputation(p, 1, 2, now, Config), "new giver accepted")
Rules.addReputation(p, 1, "kind", now)
check(p.reputation.kind == 1, "category counter incremented")
check(not Rules.canReputation(p, 1, 2, now + 1, Config), "repeat rejected")
check(not Rules.canReputation(p, 1, 2, now + 86399, Config), "cooldown boundary rejected")
check(Rules.canReputation(p, 1, 2, now + 86400, Config), "cooldown expires")
for i = 2, 10 do Rules.addReputation(p, i, "kind", now) end
check(not Rules.canReputation(p, 11, 20, now, Config), "daily receiver cap enforced")
check(Rules.canReputation(p, 11, 20, now + 86400, Config), "daily cap reset")
check(not Rules.completionEligible(2, 600, 600, Config), "insufficient participation")
check(not Rules.completionEligible(3, 299, 600, Config), "insufficient activity")
check(Rules.completionEligible(3, 300, 600, Config), "completion threshold")
for n = 0, 12 do
    local ids = {}; for i = 1, n do ids[i] = i end
    local matches = Rules.match(ids, function() return true end, function() return 0 end)
    check(#matches == math.floor(n / 2), "pair count " .. n)
    local seen = {}
    for _, m in ipairs(matches) do
        check(m[1] ~= m[2] and not seen[m[1]] and not seen[m[2]], "unique seats " .. n)
        seen[m[1]] = true; seen[m[2]] = true
    end
end
local matches = Rules.match({1,2,3,4}, function(a,b) return not (a == 3 and b == 4) end, function() return 0 end)
check(#matches == 2, "maximum matching avoids greedy stranded pair")
local blocked = Rules.match({1,2}, function() return false end, function() return 0 end)
check(#blocked == 0, "hard exclusion never relaxed")
local rotated = Rules.match({1,2,3,4}, function() return true end, function(a,b)
    if (a == 1 and b == 2) or (a == 3 and b == 4) then return 10000 end
    return 0
end)
for _, m in ipairs(rotated) do check(not (m[1] == 1 and m[2] == 2) and not (m[1] == 3 and m[2] == 4), "recent partner avoided") end
local ids = {}
for _, q in ipairs(Questions) do
    check(not ids[q.id] and #q.options == 2 and #q.prompt > 0, "question schema " .. q.id)
    ids[q.id] = true
end
print("PASS: " .. count .. " rule checks")
