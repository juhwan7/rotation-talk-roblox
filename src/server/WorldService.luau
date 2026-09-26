local Theme = require(game:GetService("ReplicatedStorage").RotationTalk.Theme)
local World = { seats = {}, lobbyPosition = Vector3.new(0, 5, 53) }

local function part(parent, name, size, cf, color, class, material)
    local p = Instance.new(class or "Part")
    p.Name = name; p.Size = size; p.CFrame = cf; p.Anchored = true
    p.Color = color; p.Material = material or Enum.Material.SmoothPlastic
    p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end
local function box(parent, name, size, pos, color, material)
    return part(parent, name, size, CFrame.new(pos), color, nil, material)
end
local function group(parent, name)
    local folder = Instance.new("Folder"); folder.Name = name; folder.Parent = parent
    return folder
end
local function sign(parent, text, size, color, face)
    local gui = Instance.new("SurfaceGui")
    -- The stage is approached from +Z, so its readable face is Back (+Z).
    gui.Face = face or Enum.NormalId.Back
    gui.CanvasSize = Vector2.new(1000, 500); gui.LightInfluence = 0; gui.Parent = parent
    local label = Instance.new("TextLabel")
    label.Name = "BoardText"; label.Size = UDim2.fromScale(0.94, 0.92)
    label.Position = UDim2.fromScale(0.03, 0.04); label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold; label.TextSize = size or 44
    label.TextColor3 = color or Theme.Chalk; label.TextWrapped = true
    label.RichText = false; label.Text = text; label.Parent = gui
    return label
end
local function framedBoard(parent, name, pos, size, text, textSize)
    box(parent, name .. "Frame", size + Vector3.new(0.8, 0.8, 0.2), pos, Theme.DarkWood, Enum.Material.Wood)
    local board = box(parent, name, size, pos + Vector3.new(0, 0, 0.2), Theme.Chalkboard)
    return sign(board, text, textSize)
end

local function buildShell(root)
    local shell = group(root, "AssemblyHall")
    box(shell, "Foundation", Vector3.new(124, 2, 136), Vector3.new(0, -1.05, 0), Theme.DarkWood)
    for i = 0, 30 do
        local tint = i % 3 == 0 and Theme.LightOak or Theme.Oak
        box(shell, "OakFloor" .. i, Vector3.new(3.96, 0.18, 136), Vector3.new(-60 + i * 4, 0), tint, Enum.Material.WoodPlanks)
    end
    box(shell, "BackstageWall", Vector3.new(126, 29, 1.5), Vector3.new(0, 14, -68), Theme.Wall)
    box(shell, "Ceiling", Vector3.new(126, 1, 138), Vector3.new(0, 29, 0), Theme.Paper)
    for _, x in ipairs({ -62, 62 }) do
        box(shell, "WallBase", Vector3.new(1.5, 7, 136), Vector3.new(x, 3.5, 0), Theme.WallTrim)
        box(shell, "UpperWall", Vector3.new(1.5, 7, 136), Vector3.new(x, 25.5, 0), Theme.Wall)
        for z = -56, 56, 28 do
            box(shell, "WindowSill", Vector3.new(2.3, 0.5, 22), Vector3.new(x, 7.1, z), Theme.DarkWood)
            local glass = box(shell, "TallWindow", Vector3.new(0.4, 14.5, 22), Vector3.new(x, 14.6, z), Color3.fromRGB(180, 211, 211), Enum.Material.Glass)
            glass.Transparency = 0.42; glass.CastShadow = false
            box(shell, "WindowMullion", Vector3.new(1.7, 15, 0.3), Vector3.new(x, 14.6, z), Theme.Paper)
            box(shell, "WindowCrossbar", Vector3.new(1.7, 0.3, 22), Vector3.new(x, 14.6, z), Theme.Paper)
        end
        for z = -68, 72, 28 do
            box(shell, "WallColumn", Vector3.new(2.3, 22, 6), Vector3.new(x, 11, math.min(z, 68)), Theme.Wall)
        end
        box(shell, "Skirting", Vector3.new(2, 0.8, 136), Vector3.new(x, 0.4, 0), Theme.DarkWood)
    end
    for _, x in ipairs({ -37, 37 }) do
        box(shell, "EntranceWall", Vector3.new(50, 29, 1.5), Vector3.new(x, 14, 68), Theme.Wall)
    end
    box(shell, "EntranceLintel", Vector3.new(24, 13, 1.5), Vector3.new(0, 22, 68), Theme.Wall)
    for _, x in ipairs({ -5.7, 5.7 }) do
        local door = box(shell, "GlassEntranceDoor", Vector3.new(11.3, 15, 0.5), Vector3.new(x, 7.5, 68), Color3.fromRGB(184, 209, 199), Enum.Material.Glass)
        door.Transparency = 0.4
        box(shell, "DoorRail", Vector3.new(10.7, 0.4, 0.5), Vector3.new(x, 6.5, 67.6), Theme.Brass, Enum.Material.Metal)
    end
    for z = -42, 42, 28 do
        box(shell, "CeilingBeam", Vector3.new(124, 1.8, 1.2), Vector3.new(0, 27.6, z), Theme.WallTrim)
        for _, x in ipairs({ -32, 0, 32 }) do
            local fixture = box(shell, "CeilingLight", Vector3.new(9, 0.2, 3), Vector3.new(x, 27.1, z), Theme.Chalk, Enum.Material.Neon)
            fixture.CastShadow = false
            if x == 0 then
                local light = Instance.new("SurfaceLight")
                light.Face = Enum.NormalId.Bottom; light.Range = 40; light.Angle = 140
                light.Brightness = 0.7; light.Color = Theme.Paper; light.Shadows = false; light.Parent = fixture
            end
        end
    end
end

local function buildStage(root)
    local stage = group(root, "SchoolStage")
    box(stage, "StageBase", Vector3.new(100, 3.5, 24), Vector3.new(0, 1.75, -53), Theme.DarkWood, Enum.Material.Wood)
    box(stage, "StageTop", Vector3.new(100, 0.25, 24), Vector3.new(0, 3.6, -53), Theme.LightOak, Enum.Material.WoodPlanks)
    for _, x in ipairs({ -44, 44 }) do
        for step = 1, 4 do
            box(stage, "StageStep", Vector3.new(10, step * 0.85, 2), Vector3.new(x, step * 0.425, -32 - step * 2), Theme.LightOak, Enum.Material.Wood)
        end
    end
    box(stage, "CurtainHeader", Vector3.new(102, 4, 1.5), Vector3.new(0, 24, -63), Theme.Curtain, Enum.Material.Fabric)
    for _, side in ipairs({ -1, 1 }) do
        for fold = 1, 9 do
            box(stage, "CurtainFold", Vector3.new(1.4, 18, 1.2 + fold % 2 * 0.5), Vector3.new(side * (35 + fold * 1.5), 13, -62.4), fold % 2 == 0 and Theme.CurtainShade or Theme.Curtain, Enum.Material.Fabric)
        end
        box(stage, "CurtainTie", Vector3.new(14, 0.5, 2), Vector3.new(side * 43, 10, -61.7), Theme.Brass)
    end
    local title = box(stage, "SchoolAssemblyBanner", Vector3.new(64, 4.6, 0.4), Vector3.new(0, 23.6, -61.8), Theme.Paper)
    sign(title, "ROTATION TALK\n우리들의 이야기 강당", 64, Theme.Chalkboard)
    local board = framedBoard(stage, "BestDuoBoard", Vector3.new(0, 13.5, -62), Vector3.new(47, 13, 0.4), "오늘의 대화 짝꿍\n새로운 이야기가 곧 시작돼요", 52)
    box(stage, "Podium", Vector3.new(5, 4, 3), Vector3.new(-26, 5.6, -48), Theme.Oak, Enum.Material.Wood)
    local podiumSign = box(stage, "PodiumBadge", Vector3.new(3, 2, 0.2), Vector3.new(-26, 5.7, -46.4), Theme.Chalkboard)
    sign(podiumSign, "TALK\nCLUB", 95)
    local mic = box(stage, "MicrophoneStand", Vector3.new(0.15, 2, 0.15), Vector3.new(-26, 8.4, -48), Theme.Steel, Enum.Material.Metal)
    mic.CanCollide = false
    for _, x in ipairs({ -36, 36 }) do
        box(stage, "StageSpeaker", Vector3.new(3, 6, 3), Vector3.new(x, 6.7, -48), Theme.Steel)
    end
    return board
end

local function buildConversationTables(root, seats)
    local tables = group(root, "ConversationTables")
    for i = 1, 6 do
        local column, row = (i - 1) % 3, math.floor((i - 1) / 3)
        local center = Vector3.new((column - 1) * 27, 0, -12 + row * 28)
        local tableGroup = group(tables, "Table" .. i)
        box(tableGroup, "GreenFloorMat", Vector3.new(18, 0.08, 20), center + Vector3.new(0, 0.16, 0), Theme.Chalkboard, Enum.Material.Fabric)
        box(tableGroup, "DeskTop", Vector3.new(10, 0.65, 5.5), center + Vector3.new(0, 3.2, 0), Theme.LightOak, Enum.Material.Wood)
        for _, x in ipairs({ -4, 4 }) do for _, z in ipairs({ -1.9, 1.9 }) do
            box(tableGroup, "DeskLeg", Vector3.new(0.4, 3, 0.4), center + Vector3.new(x, 1.6, z), Theme.Steel, Enum.Material.Metal)
        end end
        seats[i] = {}
        for side = 1, 2 do
            local offset = side == 1 and 5.6 or -5.6
            local pos = center + Vector3.new(0, 1.85, offset)
            seats[i][side] = part(tableGroup, "Seat" .. i .. "_" .. side, Vector3.new(3.3, 0.45, 3.2),
                CFrame.lookAt(pos, Vector3.new(center.X, pos.Y, center.Z)), Theme.Oak, "Seat", Enum.Material.Wood)
            local backZ = offset + (side == 1 and 1.45 or -1.45)
            box(tableGroup, "ChairBack", Vector3.new(3.3, 2.5, 0.3), center + Vector3.new(0, 3.05, backZ), Theme.Oak, Enum.Material.Wood)
            for _, x in ipairs({ -1.25, 1.25 }) do
                box(tableGroup, "ChairLeg", Vector3.new(0.25, 1.8, 2.6), center + Vector3.new(x, 1, offset), Theme.Steel, Enum.Material.Metal)
            end
        end
        local card = box(tableGroup, "TableNumber", Vector3.new(3.1, 1.65, 0.15), center + Vector3.new(3.1, 4.35, 0), Theme.Paper)
        sign(card, string.format("%02d\n대화 테이블", i), 98, Theme.Chalkboard)
        sign(card, string.format("%02d\n대화 테이블", i), 98, Theme.Chalkboard, Enum.NormalId.Front)
        box(tableGroup, "QuestionCard", Vector3.new(2.8, 0.06, 1.6), center + Vector3.new(-2.7, 3.56, 0), Theme.Paper)
    end
end

local function buildFoyer(root)
    local foyer = group(root, "FoyerAndAudience")
    -- Decorative audience chairs are Parts, not matchmaking Seats.
    for _, x in ipairs({ -48, 48 }) do
        for z = -15, 30, 15 do
            for offset = -3, 3, 6 do
                local pos = Vector3.new(x + offset, 1.8, z)
                box(foyer, "AudienceSeat", Vector3.new(3.7, 0.7, 3.8), pos, Theme.Curtain, Enum.Material.Fabric)
                box(foyer, "AudienceBack", Vector3.new(3.7, 3, 0.6), pos + Vector3.new(0, 1.1, 1.6), Theme.Curtain, Enum.Material.Fabric)
                box(foyer, "AudienceBase", Vector3.new(2.5, 1.5, 2.5), pos - Vector3.new(0, 1, 0), Theme.DarkWood)
            end
        end
    end
    framedBoard(foyer, "WelcomeBoard", Vector3.new(-31, 7, 45), Vector3.new(18, 10, 0.6), "오늘의 모임\n\n01  가볍게 고르기\n02  서로 이야기하기\n03  새로운 친구 만나기", 48)
    framedBoard(foyer, "KindnessBoard", Vector3.new(31, 7, 45), Vector3.new(18, 10, 0.6), "우리 강당의 약속\n\n다른 취향도 존중해요\n개인정보는 지켜요\n불편하면 건너뛰어요", 48)
    for _, x in ipairs({ -31, 31 }) do
        for _, offset in ipairs({ -7, 7 }) do box(foyer, "NoticeBoardPost", Vector3.new(0.6, 7, 0.6), Vector3.new(x + offset, 3.5, 44.8), Theme.DarkWood) end
    end
    local spawn = part(foyer, "LobbySpawn", Vector3.new(14, 0.2, 10), CFrame.new(0, 0.25, 53), Theme.Chalkboard, "SpawnLocation", Enum.Material.Fabric)
    spawn.Neutral = true; spawn.Duration = 0
    local decal = spawn:FindFirstChildOfClass("Decal"); if decal then decal:Destroy() end
    for _, x in ipairs({ -54, 54 }) do
        local pot = box(foyer, "Planter", Vector3.new(4, 3, 4), Vector3.new(x, 1.6, 52), Theme.WallTrim)
        local leaves = box(foyer, "Plant", Vector3.new(5, 6, 5), pot.Position + Vector3.new(0, 4.3, 0), Theme.Chalkboard, Enum.Material.Grass)
        leaves.Shape = Enum.PartType.Ball; leaves.CanCollide = false
    end
end

function World:Build()
    local old = workspace:FindFirstChild("RotationTalkLounge")
    if old then old:Destroy() end
    self.seats = {}
    local root = group(workspace, "RotationTalkLounge")
    buildShell(root); self.board = buildStage(root)
    buildConversationTables(root, self.seats); buildFoyer(root)
    local lighting = game:GetService("Lighting")
    lighting.ClockTime = 10.5; lighting.Brightness = 2
    lighting.Ambient = Color3.fromRGB(153, 145, 128)
    lighting.OutdoorAmbient = Color3.fromRGB(175, 180, 170)
end
function World:Seat(player, index, side)
    if not player then return end
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
        char:PivotTo(CFrame.lookAt(self.lobbyPosition, Vector3.new(0, 5, -40)))
    end
end
function World:Leaderboard(pairsList)
    local sorted = {}
    for _, pair in ipairs(pairsList) do if not pair.cancelled then table.insert(sorted, pair) end end
    table.sort(sorted, function(a, b) return a.sync > b.sync or (a.sync == b.sync and a.index < b.index) end)
    local lines = { "오늘의 대화 짝꿍", "BEST DUO  /  이번 라운드" }
    if #sorted == 0 then table.insert(lines, "새로운 이야기가 곧 시작돼요") end
    for i = 1, math.min(3, #sorted) do
        table.insert(lines, string.format("%d   테이블 %02d   ·   %d SYNC", i, sorted[i].index, sorted[i].sync))
    end
    table.insert(lines, "다른 취향도 존중하는 우리 강당")
    self.board.Text = table.concat(lines, "\n")
end
return World
