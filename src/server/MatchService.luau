local Rules = require(game:GetService("ReplicatedStorage").RotationTalk.Rules)
local Match = { recent = {}, waitAge = {} }
function Match:Build(ids, data)
    table.sort(ids, function(a, b)
        local wa, wb = self.waitAge[a] or 0, self.waitAge[b] or 0
        return wa > wb or (wa == wb and a < b)
    end)
    local result = Rules.match(ids, function(a, b)
        local pa, pb = data:Get(a), data:Get(b)
        return pa ~= nil and pb ~= nil and not pa.avoided[tostring(b)] and not pb.avoided[tostring(a)]
    end, function(a, b)
        return (self.recent[a] == b and 10000 or 0) - (self.waitAge[a] or 0) - (self.waitAge[b] or 0)
    end)
    for _, id in ipairs(ids) do self.waitAge[id] = (self.waitAge[id] or 0) + 1 end
    for _, pair in ipairs(result) do
        self.recent[pair[1]] = pair[2]; self.recent[pair[2]] = pair[1]
        self.waitAge[pair[1]] = 0; self.waitAge[pair[2]] = 0
    end
    return result
end
return Match
