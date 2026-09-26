-- Pure rules: executable in both Roblox and the standalone Luau test runner.
local Rules = {}

function Rules.newProfile()
    return { schema = 1, coins = 0, rounds = 0, answers = 0, reputation = {},
        receivedFrom = {}, reputationDay = 0, reputationToday = 0,
        cosmetics = {}, titles = {}, cards = {}, settings = {}, avoided = {} }
end

function Rules.choice(pair, userId, choice, nonce)
    if pair.closed or pair.nonce ~= nonce or (choice ~= 1 and choice ~= 2) then return false end
    if userId ~= pair.a and userId ~= pair.b then return false end
    if pair.choices[userId] ~= nil then return false end
    pair.choices[userId] = choice
    if pair.choices[pair.a] and pair.choices[pair.b] then
        pair.closed = true
        pair.matched = pair.choices[pair.a] == pair.choices[pair.b]
    end
    return true
end

function Rules.canReputation(profile, senderId, receiverId, now, config)
    if senderId == receiverId then return false, "self" end
    local previous = profile.receivedFrom[tostring(senderId)]
    if previous and now - previous < config.ReputationPairSeconds then return false, "pair_limit" end
    local day = math.floor(now / 86400)
    if profile.reputationDay == day and profile.reputationToday >= config.ReputationDailyLimit then
        return false, "daily_limit"
    end
    return true
end

function Rules.addReputation(profile, senderId, kind, now)
    local day = math.floor(now / 86400)
    if profile.reputationDay ~= day then profile.reputationDay = day; profile.reputationToday = 0 end
    profile.reputationToday += 1
    profile.receivedFrom[tostring(senderId)] = now
    profile.reputation[kind] = (profile.reputation[kind] or 0) + 1
    for id, timestamp in pairs(profile.receivedFrom) do
        if now - timestamp > 86400 * 2 then profile.receivedFrom[id] = nil end
    end
end

function Rules.completionEligible(answerCount, activeSeconds, duration, config)
    return answerCount >= config.MinimumAnswers and activeSeconds >= duration * 0.5
end

-- Maximum-cardinality matching (at most 12 players). Recent pairs carry a cost;
-- hard exclusions are never relaxed. Dynamic programming avoids greedy dead ends.
function Rules.match(ids, allowed, cost)
    local memo = {}
    local function solve(mask)
        if memo[mask] then return memo[mask] end
        local first
        for i = 1, #ids do
            if bit32.band(mask, bit32.lshift(1, i - 1)) == 0 then first = i; break end
        end
        if not first then return { count = 0, cost = 0, pairs = {} } end
        local withFirst = bit32.bor(mask, bit32.lshift(1, first - 1))
        local skipped = solve(withFirst)
        local best = { count = skipped.count, cost = skipped.cost, pairs = skipped.pairs }
        for j = first + 1, #ids do
            local bit = bit32.lshift(1, j - 1)
            if bit32.band(mask, bit) == 0 and allowed(ids[first], ids[j]) then
                local tail = solve(bit32.bor(withFirst, bit))
                local count, price = tail.count + 1, tail.cost + cost(ids[first], ids[j])
                if count > best.count or (count == best.count and price < best.cost) then
                    local result = { { ids[first], ids[j] } }
                    for _, p in ipairs(tail.pairs) do table.insert(result, p) end
                    best = { count = count, cost = price, pairs = result }
                end
            end
        end
        memo[mask] = best
        return best
    end
    return solve(0).pairs
end

return Rules
