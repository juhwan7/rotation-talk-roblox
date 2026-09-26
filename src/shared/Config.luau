-- Server is authoritative; replicated configuration is not a permission boundary.
local tableCount = 20
return table.freeze({
    TableCount = tableCount,
    TableColumns = 4,
    MaxPlayers = tableCount * 2,
    RoundSeconds = 600, -- 180, 300, 420, 600
    ResultsSeconds = 20,
    IntermissionSeconds = 8,
    QuestionSeconds = 45,
    RevealSeconds = 7,
    MatchSync = 10,
    QuestionCoins = 5,
    CompletionCoins = 100,
    BestDuoCoins = 20,
    AttendanceSeconds = 300,
    AttendanceCoins = 50,
    ActiveWindowSeconds = 90,
    MinimumAnswers = 3,
    ReputationDailyLimit = 10,
    ReputationPairSeconds = 86400,
    AutosaveSeconds = 60,
    SessionLeaseSeconds = 180,
    StoreName = "RotationTalk_v1",
    StudioPersistence = false,
    ReputationKinds = { "friend", "funny", "listener", "gamer", "kind" },
    ReputationLabels = { friend = "좋은 친구", funny = "재미있었어요", listener = "대화 잘 통함", gamer = "게임 취향 비슷", kind = "친절해요" },
})
