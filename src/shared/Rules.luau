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

-- General-graph maximum matching with odd-cycle contraction (blossom).
-- No bitmasks or exponential subset search: supports all 40 users.
-- Cost orders candidates and bounded local improvements; it is NOT a globally
-- minimum-weight solver. Maximum pair count and hard exclusions remain exact.
function Rules.match(ids, allowed, cost)
    local n = #ids
    local graph, weights, mate = {}, {}, table.create(n, 0)
    for i = 1, n do graph[i] = {}; weights[i] = {} end
    for i = 1, n do for j = i + 1, n do
        if allowed(ids[i], ids[j]) then
            local w = cost(ids[i], ids[j])
            weights[i][j] = w; weights[j][i] = w
            table.insert(graph[i], j); table.insert(graph[j], i)
        end
    end end
    for i = 1, n do
        table.sort(graph[i], function(a, b)
            return weights[i][a] < weights[i][b] or (weights[i][a] == weights[i][b] and a < b)
        end)
    end
    local function augment(root)
        local parent, base, used = table.create(n, 0), {}, {}
        for i = 1, n do base[i] = i end
        local queue, head = {root}, 1
        used[root] = true
        local function ancestor(a, b)
            local seen = {}
            while true do
                a = base[a]; seen[a] = true
                if mate[a] == 0 then break end
                a = parent[mate[a]]
            end
            while true do
                b = base[b]
                if seen[b] then return b end
                b = parent[mate[b]]
            end
        end
        local function markPath(v, common, child, blossom)
            while base[v] ~= common do
                blossom[base[v]] = true; blossom[base[mate[v]]] = true
                parent[v] = child; child = mate[v]; v = parent[mate[v]]
            end
        end
        while head <= #queue do
            local v = queue[head]; head += 1
            for _, u in ipairs(graph[v]) do
                if base[v] ~= base[u] and mate[v] ~= u then
                    if u == root or (mate[u] ~= 0 and parent[mate[u]] ~= 0) then
                        local common, blossom = ancestor(v, u), {}
                        markPath(v, common, u, blossom); markPath(u, common, v, blossom)
                        for i = 1, n do
                            if blossom[base[i]] then
                                base[i] = common
                                if not used[i] then used[i] = true; table.insert(queue, i) end
                            end
                        end
                    elseif parent[u] == 0 then
                        parent[u] = v
                        if mate[u] == 0 then
                            local endpoint = u
                            while endpoint ~= 0 do
                                local previous = parent[endpoint]
                                local following = mate[previous]
                                mate[endpoint] = previous; mate[previous] = endpoint
                                endpoint = following
                            end
                            return
                        end
                        used[mate[u]] = true; table.insert(queue, mate[u])
                    end
                end
            end
        end
    end
    for i = 1, n do if mate[i] == 0 then augment(i) end end
    -- Reduce repeated partners and prefer waiting players without reducing count.
    for _ = 1, n do
        local improved = false
        for a = 1, n do
            local b = mate[a]
            if b > a then
                for c = 1, n do
                    local d = mate[c]
                    if d == 0 then
                        if weights[a][c] and weights[a][c] < weights[a][b] then
                            mate[a] = c; mate[c] = a; mate[b] = 0; b = c; improved = true
                        elseif weights[b][c] and weights[b][c] < weights[a][b] then
                            mate[b] = c; mate[c] = b; mate[a] = 0; improved = true; break
                        end
                    elseif c > a and d > c and c ~= b then
                        local old = weights[a][b] + weights[c][d]
                        if weights[a][c] and weights[b][d] and weights[a][c] + weights[b][d] < old then
                            mate[a] = c; mate[c] = a; mate[b] = d; mate[d] = b; b = c; improved = true
                        elseif weights[a][d] and weights[b][c] and weights[a][d] + weights[b][c] < old then
                            mate[a] = d; mate[d] = a; mate[b] = c; mate[c] = b; b = d; improved = true
                        end
                    end
                end
            end
        end
        if not improved then break end
    end
    local result = {}
    for i = 1, n do if mate[i] > i then table.insert(result, {ids[i], ids[mate[i]]}) end end
    return result
end

return Rules
