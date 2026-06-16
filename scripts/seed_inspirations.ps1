# PocketBase 灵感种子数据导入脚本 (PowerShell)
param(
    [string]$AdminToken
)

if (-not $AdminToken) {
    Write-Host "Usage: .\seed_inspirations.ps1 -AdminToken <token>"
    exit 1
}

$PB_URL = "http://127.0.0.1:8090"
$headers = @{ Authorization = $AdminToken; "Content-Type" = "application/json" }
$count = 0

function Import-One {
    param($Emoji, $Quote, $Author, $Category, $Priority)
    $body = @{ emoji = $Emoji; quote = $Quote; author = $Author; category = $Category; isActive = $true; priority = $Priority } | ConvertTo-Json -Compress
    try {
        $null = Invoke-RestMethod -Uri "$PB_URL/api/collections/inspirations/records" -Method Post -Body $body -Headers $headers
        $script:count++
        Write-Host "  [$count] $Emoji $Category - $($Quote.Substring(0, [Math]::Min(30, $Quote.Length)))..."
    } catch {
        Write-Host "  WARN: $($_.Exception.Message)"
    }
}

Write-Host "Importing inspirations..."

# ═══ Writing (写作鼓励) ═══
Import-One "✍️" "写作是灵魂的呼吸，每一个字都是你与自己的对话。" "未知" "writing" 10
Import-One "🔥" "最好的时间就是现在。拿起笔，让思绪流淌。" "村上春树" "writing" 10
Import-One "🎯" "不需要完美的第一稿，只需要被写下来的第一稿。" "乔迪·皮考特" "writing" 9
Import-One "🖋️" "写作不是想好了再写，而是在写的过程中想清楚。" "威廉·福克纳" "writing" 9
Import-One "📝" "如果你觉得生活平淡无奇，那是因为你还没有开始记录。" "安妮·迪拉德" "writing" 9
Import-One "⚡" "动手写吧。第一个句子永远是最难的，但也是最重要的。" "厄尼斯特·海明威" "writing" 8
Import-One "🎨" "写作是唯一让你同时成为艺术家和工具的艺术形式。" "雷·布拉德伯里" "writing" 8
Import-One "🏗️" "一篇好文章不是写出来的，是改出来的。" "詹姆斯·米切纳" "writing" 8
Import-One "🌊" "写作如同游泳，一旦停下来就会下沉。保持动笔的节奏。" "奥克塔维亚·巴特勒" "writing" 7
Import-One "🗝️" "你身上有故事，只有你能讲述。别让它们永远沉默。" "托妮·莫里森" "writing" 7
Import-One "🔨" "写作不是艺术，是手艺。每天打磨，终会见光。" "史蒂芬·普莱斯菲尔德" "writing" 7
Import-One "🪞" "你在纸上写下的每一个字，都是你灵魂的一面镜子。" "村上春树" "writing" 6

# ═══ Creativity (创意激发) ═══
Import-One "💡" "灵感不会主动上门，它在你开始动笔的那一刻才会降临。" "杰克·伦敦" "creativity" 9
Import-One "🧩" "创造力就是把看似无关的事物连接起来的能力。" "史蒂夫·乔布斯" "creativity" 9
Import-One "🌌" "你的潜意识比你想象中更聪明。相信第一直觉，把它写下来。" "雷·布拉德伯里" "creativity" 8
Import-One "🎭" "创意不是等待暴风雨过去，而是学会在雨中跳舞。" "佚名" "creativity" 8
Import-One "🦋" "一个微小的念头，经过时间的孵化，可以改变一切。" "詹姆斯·艾伦" "creativity" 7
Import-One "🎪" "好奇心是创造力的引擎。永远保持对世界提问的能力。" "爱因斯坦" "creativity" 7
Import-One "🔮" "最好的创意往往来自于最不经意的瞬间——捕捉它们，别让它们溜走。" "达·芬奇" "creativity" 7
Import-One "🌱" "每个伟大的发明都始于一个人说「如果…会怎样？」" "佚名" "creativity" 6
Import-One "🪐" "写作时的你是造物主——可以从虚无中创造整个世界。" "尼尔·盖曼" "creativity" 6
Import-One "🎲" "随机性是最好的灵感来源。翻开一本书、随机走一条路、和一个陌生人聊天。" "布莱恩·伊诺" "creativity" 6

# ═══ Persistence (坚持记录) ═══
Import-One "🌱" "每天记录一件小事，一年后你会有 365 个故事。" "格蕾塔·鲁宾" "persistence" 9
Import-One "⏳" "坚持写作 100 天，你会惊讶地发现自己已经完全变了一个人。" "佚名" "persistence" 8
Import-One "🧱" "不积跬步，无以至千里。每天 200 字，一年就是一本书。" "荀子" "persistence" 8
Import-One "🎢" "写作最难的不是写，而是坐下来。一旦坐下，一切就开始了。" "伊莎贝尔·阿连德" "persistence" 8
Import-One "🌳" "你种下的是每天的几分钟，收获的是几年后的一片森林。" "佚名" "persistence" 7
Import-One "🏔️" "写作是一场马拉松，而不是百米冲刺。慢慢来，但不要停。" "村上春树" "persistence" 7
Import-One "📆" "习惯的力量大过意志力。每天同一时间写作，让它成为呼吸般自然。" "史蒂芬·金" "persistence" 7
Import-One "🌙" "即使今天只写了一句「今天不想写」，你也已经赢了。" "佚名" "persistence" 6
Import-One "🪜" "进步从来不是线性的。请相信你在上升，即使感觉在停滞。" "安·拉莫特" "persistence" 6
Import-One "🔋" "写作的秘诀？写完今天该写的字数。明天再写明天的。" "约翰·欧文" "persistence" 6

# ═══ Wisdom (人生智慧) ═══
Import-One "🌟" "生活不是我们活过的日子，而是我们记住的日子。" "马尔克斯" "wisdom" 8
Import-One "🧠" "写作是思考的终极形式——它把模糊的感受变成清晰的洞见。" "保罗·格雷厄姆" "wisdom" 8
Import-One "🎯" "我们写作，不仅是为了被理解，更是为了理解自己。" "琼·狄迪恩" "wisdom" 7
Import-One "🗺️" "文字是心灵的地图——写下来，你才能看见自己在哪。" "佚名" "wisdom" 7
Import-One "🌅" "每一个人的生命都是一部史诗。你只需要开始记录。" "约瑟夫·坎贝尔" "wisdom" 7
Import-One "💎" "写作帮你把生活的碎片打磨成闪闪发光的宝石。" "佚名" "wisdom" 6
Import-One "🕰️" "多年后翻开今天的记录，你会感激此刻选择动笔的自己。" "佚名" "wisdom" 6
Import-One "🎻" "人生就像一首曲子，记录让每一个音符都有意义。" "罗曼·罗兰" "wisdom" 6

# ═══ Literature (文学之美) ═══
Import-One "📖" "每一个伟大的故事，都始于一个简单的记录。" "史蒂芬·金" "literature" 8
Import-One "🌈" "文字是时间的容器，把一瞬的感动封存为永恒。" "泰戈尔" "literature" 8
Import-One "🕯️" "在你内心最深处，有一个声音值得被听见。写下来吧。" "弗吉尼亚·伍尔夫" "literature" 7
Import-One "🎶" "好的文字有节奏、有韵律、有呼吸。像音乐一样写作。" "杜鲁门·卡波特" "literature" 7
Import-One "🏛️" "写作是人类最伟大的发明——没有文字，就没有文明。" "佚名" "literature" 6
Import-One "🪶" "简洁是智慧的灵魂。用最少的词说最多的话。" "莎士比亚" "literature" 6
Import-One "🖼️" "好的文字像一幅画，让读者看到你眼中的世界。" "安东·契诃夫" "literature" 6
Import-One "🎻" "写作是沉默中的交响乐，每一个字都是一个音符。" "佚名" "literature" 6

# ═══ Mindfulness (正念觉察) ═══
Import-One "🧘" "写作是一种冥想。当笔尖触碰纸张的那一刻，你就活在了当下。" "佚名" "mindfulness" 8
Import-One "🍃" "记录你的感受，不是评判它，只是观察它。这是最好的自我疗愈。" "一行禅师" "mindfulness" 7
Import-One "🌊" "思绪如浪潮涌来，写作是唯一能让你在浪中站稳的锚。" "佚名" "mindfulness" 7
Import-One "🪷" "在书写中，你既可以是一朵莲花，也可以是池塘本身。" "佚名" "mindfulness" 6
Import-One "🕊️" "每日记录三次感恩的事，一个月后你会发现世界完全不同。" "佚名" "mindfulness" 6
Import-One "🌿" "把焦虑写下来，它就会从你的脑子里转移到纸上，不再那么可怕。" "佚名" "mindfulness" 6
Import-One "🔔" "此刻的每一个感受都值得被记录——悲伤、喜悦、平静、躁动。" "佚名" "mindfulness" 5
Import-One "🪞" "写作是和自己最深层次的对话。诚实面对，温柔对待。" "朱莉娅·卡梅隆" "mindfulness" 5

Write-Host ""
Write-Host "✅ Done! Imported $count inspirations."
