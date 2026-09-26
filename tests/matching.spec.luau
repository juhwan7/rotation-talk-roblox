local Rules = require("../src/shared/Rules")
local cases = 0
local function verify(n, edges, expected)
    local ids = {}; for i = 1, n do ids[i] = 5000000000 + i end
    local function allowed(a, b) return edges[a - 5000000000][b - 5000000000] ~= nil end
    local result = Rules.match(ids, allowed, function(a, b) return edges[a - 5000000000][b - 5000000000] end)
    local seen = {}
    for _, pair in ipairs(result) do
        assert(pair[1] ~= pair[2] and not seen[pair[1]] and not seen[pair[2]], "duplicate assignment")
        assert(allowed(pair[1], pair[2]), "excluded pair")
        seen[pair[1]] = true; seen[pair[2]] = true
    end
    assert(#result == expected, "maximum count mismatch in case " .. cases)
    cases += 1
end
-- Independent exhaustive oracle, deliberately confined to small graphs.
local function optimum(n, edges, used)
    local first
    for i = 1, n do if not used[i] then first = i; break end end
    if not first then return 0 end
    used[first] = true
    local best = optimum(n, edges, used)
    for j = first + 1, n do
        if not used[j] and edges[first][j] ~= nil then
            used[j] = true
            best = math.max(best, 1 + optimum(n, edges, used))
            used[j] = nil
        end
    end
    used[first] = nil
    return best
end
-- Every simple graph on six vertices, including triangles and stranded endpoints.
for mask = 0, 32767 do
    local edges = {}; for i = 1, 6 do edges[i] = {} end
    local bit = 0
    for a = 1, 6 do for b = a + 1, 6 do
        if bit32.band(mask, bit32.lshift(1, bit)) ~= 0 then
            local weight = ((mask + a * 11 + b * 7) % 31) - 15
            edges[a][b] = weight; edges[b][a] = weight
        end
        bit += 1
    end end
    verify(6, edges, optimum(6, edges, {}))
end
math.randomseed(20260927)
for _ = 1, 600 do
    local n = math.random(7, 10)
    local edges = {}; for i = 1, n do edges[i] = {} end
    local density = math.random()
    for a = 1, n do for b = a + 1, n do
        if math.random() < density then
            local w = math.random(-100, 100)
            edges[a][b] = w; edges[b][a] = w
        end
    end end
    verify(n, edges, optimum(n, edges, {}))
end
local started = os.clock()
for trial = 1, 500 do
    local edges = {}; for i = 1, 40 do edges[i] = {} end
    -- Plant 20 disjoint allowed pairs; other edges have random signed costs.
    for a = 1, 40 do for b = a + 1, 40 do
        if (a % 2 == 1 and b == a + 1) or math.random() < (trial % 10) / 10 then
            local w = math.random(-40, 10000)
            edges[a][b] = w; edges[b][a] = w
        end
    end end
    verify(40, edges, 20)
end
print(string.format("PASS: %d matching graphs; 500 forty-player cases in %.3fs (local Luau, not Studio)", cases, os.clock() - started))
