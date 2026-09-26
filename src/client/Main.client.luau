local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("RotationTalk")
local Config = require(Shared:WaitForChild("Config"))
local Theme = require(Shared:WaitForChild("Theme"))
local Remotes = Shared:WaitForChild("Remotes")
local Action = Remotes:WaitForChild("Action")
local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui"); gui.Name = "RotationTalkHUD"; gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.Parent = player:WaitForChild("PlayerGui")
local colors = { bg = Theme.Paper, card = Theme.PaperInset, text = Theme.Ink, accent = Theme.Chalkboard }
local function make(class, props, parent)
    local object = Instance.new(class)
    for k, v in pairs(props) do object[k] = v end
    object.Parent = parent; return object
end
local panel = make("Frame", { Name = "ActivityNotebook", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.new(0.34, 0, 0.78, 0), BackgroundColor3 = colors.bg, BorderSizePixel = 0 }, gui)
make("UISizeConstraint", { MinSize = Vector2.new(285, 250), MaxSize = Vector2.new(430, 640) }, panel)
make("UICorner", { CornerRadius = UDim.new(0, 12) }, panel)
make("UIStroke", { Color = Theme.WallTrim, Thickness = 2, Transparency = 0.2 }, panel)
local header = make("Frame", { Name = "SchoolHeader", Size = UDim2.new(1, 0, 0, 74), BackgroundColor3 = Theme.Chalkboard, BorderSizePixel = 0 }, panel)
make("UICorner", { CornerRadius = UDim.new(0, 12) }, header)
make("Frame", { Size = UDim2.new(1, 0, 0, 12), Position = UDim2.new(0, 0, 1, -12), BackgroundColor3 = Theme.Chalkboard, BorderSizePixel = 0 }, header)
make("TextLabel", { Size = UDim2.new(1, -30, 0, 21), Position = UDim2.fromOffset(15, 10), Text = "ROTATION TALK  /  TALK CLUB", Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Theme.PaperInset, BackgroundTransparency = 1 }, header)
make("TextLabel", { Size = UDim2.new(1, -30, 0, 31), Position = UDim2.fromOffset(15, 32), Text = "우리들의 이야기 강당", Font = Enum.Font.GothamBold, TextSize = 21, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Theme.Chalk, BackgroundTransparency = 1 }, header)
local scroll = make("ScrollingFrame", { Name = "NotebookPages", Size = UDim2.new(1, -24, 1, -94), Position = UDim2.fromOffset(12, 84), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = Theme.Chalkboard, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new() }, panel)
make("UIListLayout", { Padding = UDim.new(0, 9), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)
local order = 0
local function label(text, height, size)
    order += 1
    return make("TextLabel", { LayoutOrder = order, Size = UDim2.new(1, -8, 0, height), BackgroundTransparency = 1,
        Font = Enum.Font.GothamMedium, TextColor3 = colors.text, TextSize = size or 16, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, Text = text, RichText = false }, scroll)
end
local function button(text, callback)
    order += 1
    local b = make("TextButton", { LayoutOrder = order, Size = UDim2.new(1, -8, 0, 46), BackgroundColor3 = colors.card,
        Font = Enum.Font.GothamBold, TextColor3 = colors.text, TextSize = 16, TextWrapped = true, Text = text, AutoButtonColor = true }, scroll)
    make("UICorner", { CornerRadius = UDim.new(0, 8) }, b)
    make("UIStroke", { Color = Theme.WallTrim, Thickness = 1, Transparency = 0.5 }, b)
    b.Activated:Connect(callback); return b
end
label("오늘의 활동 카드", 24, 13).TextColor3 = Theme.MutedInk
local phase = label("친구를 기다리고 있어요", 26, 18)
local stats = label("", 52)
stats.BackgroundTransparency = 0; stats.BackgroundColor3 = Theme.PaperInset
make("UICorner", { CornerRadius = UDim.new(0, 6) }, stats)
make("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 8) }, stats)
local partner = label("", 30)
local prompt = label("가벼운 선택에서 대화를 시작해 보세요.", 56, 20)
local snapshot, sentNonce
local choices = {}
for i = 1, 2 do
    choices[i] = button("선택 " .. i, function()
        if not snapshot or not snapshot.nonce or snapshot.answered or sentNonce == snapshot.nonce or snapshot.result then return end
        sentNonce = snapshot.nonce
        Action:FireServer("Answer", { nonce = snapshot.nonce, choice = i })
    end)
    choices[i].Visible = false
end
local result = label("", 60)
local reactions = {}
for _, kind in ipairs(Config.ReputationKinds) do
    reactions[kind] = button(Config.ReputationLabels[kind], function()
        if snapshot then Action:FireServer("React", { kind = kind, serial = snapshot.serial }) end
    end)
    reactions[kind].Visible = false
end
local skip = button("이번 상대 건너뛰기", function()
    if snapshot then Action:FireServer("Skip", { serial = snapshot.serial }) end
end)
local avoid = button("이 상대와 다시 배정하지 않기", function()
    if snapshot then Action:FireServer("Avoid", { serial = snapshot.serial }) end
end)
skip.Visible = false; avoid.Visible = false
local notice = label("", 56)
button("신고 · 차단 · 음소거 안내", function()
    notice.Text = "Roblox 메뉴 → 사람 목록에서 상대를 선택해 신고·차단하세요. 음성 사용 시 음소거도 설정할 수 있어요. 위험하면 먼저 건너뛰기를 누르세요."
end)
local profile = label("내가 받은 따뜻한 반응", 122, 14)
label("개인정보나 외부 연락처를 공유하지 마세요.\nSYNC는 궁합이 아닌 게임 점수예요.\n채팅은 Roblox 기본 채팅을 이용하세요.", 76, 13)
local dataMode = label("", 38, 13)
local overlay = make("TextLabel", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.35), Size = UDim2.fromScale(0.8, 0.18), BackgroundTransparency = 0.06, BackgroundColor3 = Theme.Chalkboard,
    Font = Enum.Font.GothamBlack, TextScaled = true, TextColor3 = Theme.Chalk, Text = "ROTATE!  다음 친구에게", Visible = false }, gui)
make("UICorner", { CornerRadius = UDim.new(0, 12) }, overlay)
make("UITextSizeConstraint", { MaxTextSize = 72, MinTextSize = 20 }, overlay)
local function render(v)
    snapshot = v
    local clock = string.format("%02d:%02d", math.floor(v.remaining / 60), v.remaining % 60)
    if v.loading then phase.Text = "저장 데이터 불러오는 중"
    elseif v.phase == "Intermission" then phase.Text = "ROTATE! · " .. clock
    elseif not v.paired then phase.Text = v.phase == "Waiting" and "친구를 기다리고 있어요" or "다음 라운드 대기 · " .. clock
    elseif v.phase == "Results" then phase.Text = "이번 대화 돌아보기 · " .. clock
    else phase.Text = (v.stage or "대화 시간") .. " · " .. clock end
    overlay.Visible = v.phase == "Intermission"
    stats.Text = string.format("TalkCoin %d  ·  이번 라운드 +%d\nSYNC %d", v.coins, v.roundCoins, v.sync or 0)
    partner.Text = v.partner and (string.format("%02d번 테이블 · ", v.tableIndex) .. v.partner) or "강당에서 다음 친구를 기다려요."
    local playing = v.paired and v.phase == "Playing" and v.question ~= nil
    prompt.Text = playing and (v.question.category .. " · " .. v.question.prompt) or (v.phase == "Results" and "함께한 친구에게 따뜻한 반응을 보내세요" or "같은 공간에서 다음 만남을 기다려요")
    for i, b in ipairs(choices) do
        b.Visible = playing
        if playing then
            b.Text = v.question.options[i]
            b.Active = not v.answered and not v.result
            b.BackgroundColor3 = v.answered and colors.bg or colors.card
            b.TextColor3 = v.answered and Theme.MutedInk or Theme.Ink
        end
    end
    if playing then
        result.Text = v.result or (v.answered and "선택 완료! 상대의 선택을 기다리고 있어요." or "선택은 둘 다 고른 뒤 공개돼요. · " .. v.questionRemaining .. "초")
        if v.myChoice then result.Text ..= "\n나: " .. v.question.options[v.myChoice] .. " · 상대: " .. v.question.options[v.otherChoice] end
    elseif v.paired and v.phase == "Results" then result.Text = "같은 선택 " .. v.matches .. "회 · " .. v.sync .. " SYNC\n획득 +" .. v.roundCoins .. " TalkCoin"
    else result.Text = "질문 참여와 활동 시간에 따라 보상을 받아요. 채팅을 많이 입력할 필요는 없어요." end
    for _, b in pairs(reactions) do b.Visible = v.paired and v.phase == "Results" and not v.reacted end
    skip.Visible = v.paired; avoid.Visible = v.paired
    local lines = { "내가 받은 따뜻한 반응" }
    for _, kind in ipairs(Config.ReputationKinds) do table.insert(lines, Config.ReputationLabels[kind] .. "  " .. (v.reputation[kind] or 0)) end
    profile.Text = table.concat(lines, "\n")
    dataMode.Text = player:GetAttribute("TemporaryData") and "Studio 임시 데이터 모드 · 종료하면 초기화돼요" or "서버 저장 모드"
end
Remotes:WaitForChild("State").OnClientEvent:Connect(render)
Remotes:WaitForChild("Notice").OnClientEvent:Connect(function(message) notice.Text = message end)
Action:FireServer("Refresh", {})
