local Shared = game:GetService("ReplicatedStorage").RotationTalk
local Config = require(Shared.Config)
local Rules = require(Shared.Rules)
local Reputation = {}
function Reputation:Init(data) self.data = data end
function Reputation:Give(sender, target, kind, pair)
    if not table.find(Config.ReputationKinds, kind) then return false, "invalid" end
    if pair.given[sender] then return false, "already" end
    local p = self.data:Get(target)
    if not p or not self.data:Get(sender) then return false, "offline" end
    local ok, reason = Rules.canReputation(p, sender, target, os.time(), Config)
    if not ok then return false, reason end
    -- No yield: validation, ledger update, and the round token consumption are atomic in this server.
    Rules.addReputation(p, sender, kind, os.time())
    pair.given[sender] = true
    return true
end
return Reputation
