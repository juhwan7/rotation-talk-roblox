local World = { seats = {} }
local function part(parent, name, size, cf, color, class)
    local p = Instance.new(class or "Part")
    p.Name = name; p.Size = size; p.CFrame = cf; p.Anchored = true
    p.Color = color; p.Material = Enum.Material.SmoothPlastic; p.Parent = parent
    return p
end
local function sign(parent, text, size)
    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Front; gui.CanvasSize = Vector2.new(900, 420); gui.Parent = parent
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1); label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold; label.TextSize = size or 40
    label.TextColor3 = Color3.fromRGB(235, 245, 255); label.TextWrapped = true
    label.Text = text; label.Parent = gui
    return label
end
function World:Build()
    local folder = Instance.new("Folder"); folder.Name = "RotationTalkLounge"; folder.Parent = workspace
    part(folder, "Floor", Vector3.new(112, 2, 112), CFrame.new(0, -1, 0), Color3.fromRGB(28, 35, 52))
    local spawn = part(folder, "LobbySpawn", Vector3.new(12, 1, 12), CFrame.new(0, 0.5, 38), Color3.fromRGB(94, 234, 212), "SpawnLocation")
    spawn.Neutral = true; spawn.Duration = 0
    for i = 1, 6 do
        local angle = (i - 1) * math.pi / 3
        local center = Vector3.new(math.cos(angle) * 27, 0, math.sin(angle) * 27)
        part(folder, "Table" .. i, Vector3.new(8, 0.7, 5), CFrame.new(center + Vector3.new(0, 3, 0)), Color3.fromRGB(75, 91, 121))
        part(folder, "Leg" .. i, Vector3.new(2, 3, 2), CFrame.new(center + Vector3.new(0, 1.5, 0)), Color3.fromRGB(46, 57, 78))
        self.seats[i] = {}
        for side = 1, 2 do
            local pos = center + Vector3.new(0, 1.5, side == 1 and 5 or -5)
            self.seats[i][side] = part(folder, "Seat" .. i .. "_" .. side, Vector3.new(3, 1, 3),
                CFrame.lookAt(pos, Vector3.new(center.X, pos.Y, center.Z)), Color3.fromRGB(113, 104, 238), "Seat")
        end
        local plate = part(folder, "Number" .. i, Vector3.new(4, 2, 0.3), CFrame.new(center + Vector3.new(0, 5, 0)), Color3.fromRGB(34, 43, 64))
        sign(plate, "TABLE " .. i, 110)
    end
    local board = part(folder, "BestDuoBoard", Vector3.new(19, 10, 1), CFrame.new(0, 9, -45), Color3.fromRGB(35, 44, 67))
    self.board = sign(board, "ROTATION TALK\n함께 고르고, 이야기하고, 새 친구 만나기", 44)
    local lighting = game:GetService("Lighting")
    lighting.ClockTime = 15; lighting.Brightness = 2
end
function World:Seat(player, index, side)
    local char = player.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    local seat = self.seats[index] and self.seats[index][side]
    if humanoid and seat then
        humanoid.Sit = false
        char:PivotTo(seat.CFrame + Vector3.new(0, 3, 0))
        seat:Sit(humanoid)
    end
end
function World:Lobby(player)
    local char = player.Character
    if char then
        local h = char:FindFirstChildOfClass("Humanoid")
        if h then h.Sit = false end
        char:PivotTo(CFrame.new(0, 5, 38))
    end
end
function World:Leaderboard(pairsList)
    local sorted = {}
    for _, pair in ipairs(pairsList) do if not pair.cancelled then table.insert(sorted, pair) end end
    table.sort(sorted, function(a, b) return a.sync > b.sync or (a.sync == b.sync and a.index < b.index) end)
    local lines = { "BEST DUO · 이번 라운드", "SYNC는 선택 게임 점수예요" }
    for i = 1, math.min(3, #sorted) do
        table.insert(lines, string.format("%d  TABLE %d  ·  %d SYNC", i, sorted[i].index, sorted[i].sync))
    end
    self.board.Text = table.concat(lines, "\n")
end
return World
