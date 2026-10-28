--[[ Darknes Soft | by Darknes Studio
  Universal hub for Delta.
  * Intro: samurai runs across the screen, letters drop out behind him, game background is blurred
  * Minimized = thin bar at the bottom of the screen (tap it to open)
  * Working: Info, Sky (local), Music (local), Graphics (Potato / DLSS 5 mode), Settings
  * Local-player settings, NPC training-target visuals, adaptive UI, Pro dashboard
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")

local lp = Players.LocalPlayer

----------------------------------------------------------------
-- CONFIG (edit here)
----------------------------------------------------------------
local HUB_A, HUB_B = "Darknes", "Soft"
local HUB_BY = "by Darknes Studio"
local WIN_W, WIN_H = 540, 320
local SETTINGS_FILE = "DarknesSoft.json"

-- Songs: src can be a Roblox audio ID ("1234567890"), "rbxassetid://...",
-- or a direct .mp3 link (needs request/writefile/getcustomasset in the executor).
-- Fill the empty src fields. A remix slot with its own src overrides the main one.
local function variants(extra)
	local v = {
		{ label = "Original" },
		{ label = "Slowed", speed = 0.85 },
		{ label = "Sped up", speed = 1.2 },
	}
	for _, e in ipairs(extra or {}) do table.insert(v, e) end
	return v
end

local Songs = {
	{ title = "Лазать по стенам", artist = "", src = "",
		variants = variants({
			{ label = "Remix 1", src = "" },
			{ label = "Remix 2", src = "" },
			{ label = "Remix 3", src = "" },
		}) },
	{ title = "Отпусти меня", artist = "Влад Пив", src = "116876116040463", variants = variants() },
	{ title = "Ярче солнца", artist = "", src = "83333464189701", variants = variants() },
	{ title = "MANIA x MYLANCORE", artist = "hxtemore", src = "", variants = variants() },
	{ title = "Ярче солнца — Красавица", artist = "", src = "83333464189701", variants = variants() },
	{ title = "Король и Шут — Кукла колдуна", artist = "", src = "6383462613", variants = variants() },
	{ title = "Король и Шут — Дурак и молния (Phonk Remix)", artist = "", src = "15689451063", variants = variants() },
	{ title = "Король и Шут — Лесник (Speed Up)", artist = "", src = "14457757973", variants = variants() },
	{ title = "Дора — Дорадура", artist = "", src = "5061302809", variants = variants() },
	{ title = "Face — Я роняю запад", artist = "", src = "1007608619", variants = variants() },
	{ title = "Instasamka — Bloody Party", artist = "", src = "5050721410", variants = variants() },
	{ title = "Агата Кристи — Ковер-вертолет", artist = "", src = "6167928992", variants = variants() },
	{ title = "LIZER — Сердце", artist = "", src = "3582495668", variants = variants() },
	{ title = "Пошлая Молли — Контракт", artist = "", src = "126230411779552", variants = variants() },
	{ title = "Dead Blonde — Банкомат", artist = "", src = "70455971582713", variants = variants() },
}

-- Sky presets. "618" is a guess (hot pink-magenta twilight): tweak the colors freely.
-- Optional: skybox = { Bk=, Dn=, Ft=, Lf=, Rt=, Up= } with rbxassetid links for a real galaxy texture.
local SkyPresets = {
	Galaxy = {
		clock = 0, brightness = 1.5,
		ambient = Color3.fromRGB(40, 20, 90), outdoor = Color3.fromRGB(60, 30, 120),
		shiftTop = Color3.fromRGB(120, 60, 200), shiftBottom = Color3.fromRGB(30, 10, 80),
		atm = { Color = Color3.fromRGB(120, 70, 200), Decay = Color3.fromRGB(40, 20, 110), Density = 0.35, Haze = 1.8, Glare = 0.2, Offset = 0.3 },
		cc = { TintColor = Color3.fromRGB(205, 180, 255), Saturation = 0.3, Contrast = 0.15 },
		bloom = { Intensity = 0.9, Size = 45, Threshold = 0.85 },
		stars = 6000,
	},
	Tone618 = {
		clock = 18.2, brightness = 2,
		ambient = Color3.fromRGB(120, 40, 90), outdoor = Color3.fromRGB(160, 60, 120),
		shiftTop = Color3.fromRGB(255, 80, 160), shiftBottom = Color3.fromRGB(120, 30, 90),
		atm = { Color = Color3.fromRGB(255, 110, 185), Decay = Color3.fromRGB(170, 40, 120), Density = 0.4, Haze = 2.2, Glare = 0.5, Offset = 0.1 },
		cc = { TintColor = Color3.fromRGB(255, 190, 230), Saturation = 0.35, Contrast = 0.1 },
		bloom = { Intensity = 0.7, Size = 40, Threshold = 0.9 },
		stars = 1500,
	},
	PinkSunset = {
		clock = 17.6, brightness = 2.4,
		ambient = Color3.fromRGB(150, 90, 110), outdoor = Color3.fromRGB(190, 120, 140),
		shiftTop = Color3.fromRGB(255, 150, 170), shiftBottom = Color3.fromRGB(255, 120, 120),
		atm = { Color = Color3.fromRGB(255, 170, 190), Decay = Color3.fromRGB(255, 120, 150), Density = 0.33, Haze = 1.6, Glare = 0.6, Offset = 0.15 },
		cc = { TintColor = Color3.fromRGB(255, 215, 225), Saturation = 0.2, Contrast = 0.05 },
		bloom = { Intensity = 0.5, Size = 36, Threshold = 1 },
		stars = 0,
	},
	NeonNight = {
		clock = 0, brightness = 1.8,
		ambient = Color3.fromRGB(20, 30, 60), outdoor = Color3.fromRGB(30, 50, 90),
		shiftTop = Color3.fromRGB(0, 200, 255), shiftBottom = Color3.fromRGB(255, 0, 170),
		atm = { Color = Color3.fromRGB(60, 120, 220), Decay = Color3.fromRGB(200, 0, 150), Density = 0.38, Haze = 2, Glare = 0, Offset = 0.2 },
		cc = { TintColor = Color3.fromRGB(200, 230, 255), Saturation = 0.4, Contrast = 0.2 },
		bloom = { Intensity = 1.2, Size = 50, Threshold = 0.8 },
		stars = 3000,
	},
	ClearDay = {
		clock = 14, brightness = 3,
		ambient = Color3.fromRGB(140, 140, 150), outdoor = Color3.fromRGB(170, 180, 200),
		shiftTop = Color3.fromRGB(0, 0, 0), shiftBottom = Color3.fromRGB(0, 0, 0),
		atm = { Color = Color3.fromRGB(190, 210, 240), Decay = Color3.fromRGB(150, 170, 200), Density = 0.2, Haze = 0.5, Glare = 0, Offset = 0 },
		cc = { TintColor = Color3.fromRGB(255, 255, 255), Saturation = 0.1, Contrast = 0 },
		bloom = { Intensity = 0.2, Size = 24, Threshold = 1.4 },
		stars = 0,
	},
}

----------------------------------------------------------------
-- Saved settings (language, color, intro)
----------------------------------------------------------------
local cfg = { lang = "en", hue = 0.968, intro = true }
pcall(function()
	if isfile and readfile and isfile(SETTINGS_FILE) then
		local data = HttpService:JSONDecode(readfile(SETTINGS_FILE))
		for k, v in pairs(data) do cfg[k] = v end
	end
end)
local function saveCfg()
	pcall(function()
		if writefile then writefile(SETTINGS_FILE, HttpService:JSONEncode(cfg)) end
	end)
end

----------------------------------------------------------------
-- Language (English keys -> Russian)
----------------------------------------------------------------
local RU = {
	["Info"] = "Инфо", ["ESP"] = "ESP", ["Local Player"] = "Игрок", ["Aim"] = "Прицел", ["Misc"] = "Разное",
	["Teleports"] = "Телепорты", ["Farm"] = "Фарм", ["Sky"] = "Небо", ["Music"] = "Музыка",
	["Graphics"] = "Графика", ["Settings"] = "Настройки",
	["Player"] = "Игрок", ["Game"] = "Игра", ["Executor"] = "Экзекутор",
	["Player ESP"] = "ESP игроков", ["Line ESP"] = "Линии ESP", ["Nametag ESP"] = "ESP имён",
	["Gun ESP"] = "ESP оружия", ["XRay"] = "Рентген",
	["Coming soon…"] = "Скоро…",
	["Changes only your own sky. Other players see the normal one."] = "Небо меняется только у тебя. Другие игроки видят обычное.",
	["🌌 Galaxy"] = "🌌 Галактика", ["🌸 Tone 618"] = "🌸 Тон 618", ["🌇 Pink Sunset"] = "🌇 Розовый закат",
	["🌃 Neon Night"] = "🌃 Неоновая ночь", ["☀️ Clear Day"] = "☀️ Ясный день", ["↩ Reset sky"] = "↩ Сбросить небо",
	["Nothing is playing"] = "Ничего не играет",
	["No source: put an ID or link into Songs →"] = "Нет источника: впиши ID или ссылку в Songs →",
	["Error:"] = "Ошибка:",
	["⏯ Pause / Resume"] = "⏯ Пауза / Продолжить", ["⏹ Stop"] = "⏹ Стоп", ["Volume"] = "Громкость",
	["Original"] = "Оригинал", ["Slowed"] = "Замедлено", ["Sped up"] = "Ускорено",
	["Remix 1"] = "Ремикс 1", ["Remix 2"] = "Ремикс 2", ["Remix 3"] = "Ремикс 3",
	["Potato Mode"] = "Potato режим", ["DLSS 5 Mode"] = "DLSS 5 режим",
	["Potato: cuts shadows, effects and textures to raise FPS on weak devices."] = "Potato: убирает тени, эффекты и текстуры, чтобы поднять FPS на слабых устройствах.",
	["DLSS 5: max quality and cinematic effects for powerful devices. This is a visual preset, not real DLSS."] = "DLSS 5: максимальное качество и кинематографичные эффекты для мощных устройств. Это визуальный пресет, а не настоящий DLSS.",
	["Language"] = "Язык", ["Accent color"] = "Цвет акцента", ["Hue"] = "Оттенок",
	["Intro animation"] = "Анимация запуска", ["Window transparency"] = "Прозрачность окна",
	["⏻ Deactivate"] = "⏻ Деактивировать",
	["Deactivate turns everything off instantly. To use the hub again, run the loadstring in Delta again."] = "Деактивация мгновенно всё отключает. Чтобы снова включить хаб, заново запусти loadstring в Delta.",
}

local lang = cfg.lang
local i18n = {}

local function T(s)
	if lang == "ru" then return RU[s] or s end
	return s
end

local function reglang(fn)
	fn()
	table.insert(i18n, fn)
end

local function setLang(l)
	lang = l
	cfg.lang = l
	for _, f in ipairs(i18n) do f() end
	saveCfg()
end

----------------------------------------------------------------
-- Theme (everything derives from one hue)
----------------------------------------------------------------
local theme = {}
local themed = {}

local function computeTheme(h)
	theme.accent = Color3.fromHSV(h, 0.82, 1)
	theme.row = Color3.fromHSV(h, 0.45, 0.17)
	theme.side = Color3.fromHSV(h, 0.5, 0.30)
	theme.off = Color3.fromHSV(h, 0.18, 0.33)
	theme.g0 = Color3.fromHSV(h, 0.65, 0.27)
	theme.g1 = Color3.fromHSV(h, 0.55, 0.08)
	theme.moon = Color3.fromHSV(h, 0.25, 1)
end
computeTheme(cfg.hue)

local C = {
	text = Color3.fromRGB(238, 228, 233),
	muted = Color3.fromRGB(158, 136, 146),
}

local function reg(obj, prop, key)
	obj[prop] = theme[key]
	table.insert(themed, function() obj[prop] = theme[key] end)
end

local function regFn(fn)
	fn()
	table.insert(themed, fn)
end

local function setHue(h)
	cfg.hue = h
	computeTheme(h)
	for _, f in ipairs(themed) do f() end
	saveCfg()
end

----------------------------------------------------------------
-- Helpers
----------------------------------------------------------------
local conns = {}
local function bind(signal, fn)
	local c = signal:Connect(fn)
	table.insert(conns, c)
	return c
end

local function new(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end

local function round(o, r) return new("UICorner", { CornerRadius = UDim.new(0, r) }, o) end

local function pad(o, l, r, t, b)
	return new("UIPadding", {
		PaddingLeft = UDim.new(0, l), PaddingRight = UDim.new(0, r),
		PaddingTop = UDim.new(0, t), PaddingBottom = UDim.new(0, b),
	}, o)
end

-- props.en = English source string (gets translated and re-translated on language change)
local function text(parent, props)
	local base = {
		BackgroundTransparency = 1, Font = Enum.Font.GothamMedium, TextColor3 = C.text,
		TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
	}
	local en = props.en
	props.en = nil
	for k, v in pairs(props) do base[k] = v end
	local o = new("TextLabel", base, parent)
	if en then reglang(function() o.Text = T(en) end) end
	return o
end

local function makeDraggable(handle, target)
	local dragging, startInput, startPos
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			startInput = input.Position
			startPos = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	bind(UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
			local d = input.Position - startInput
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end

local cleanup -- defined at the bottom
local dead = false
local introGui, introBlur

----------------------------------------------------------------
-- Window
----------------------------------------------------------------
local function pickParent()
	local ok, ui = pcall(function() return gethui and gethui() end)
	if ok and ui then return ui end
	return lp:WaitForChild("PlayerGui")
end

local parent = pickParent()
for _, n in ipairs({ "DarknesSoftUI", "DS_Intro" }) do
	local old = parent:FindFirstChild(n)
	if old then old:Destroy() end
end

local gui = new("ScreenGui", { Name = "DarknesSoftUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, parent)

local main = new("Frame", {
	Name = "Main", Size = UDim2.fromOffset(WIN_W, WIN_H),
	Position = UDim2.new(0.5, -WIN_W / 2, 0.5, -WIN_H / 2),
	BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ClipsDescendants = true, Visible = false,
}, gui)
round(main, 14)
local grad = new("UIGradient", { Rotation = 35 }, main)
regFn(function() grad.Color = ColorSequence.new(theme.g0, theme.g1) end)

local moon = new("Frame", {
	Size = UDim2.fromOffset(250, 250), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.62, 0, 0.5, 0),
	BackgroundTransparency = 0.91, BorderSizePixel = 0,
}, main)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, moon)
reg(moon, "BackgroundColor3", "moon")

-- Header
local header = new("Frame", { Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1 }, main)
makeDraggable(header, main)

local logo = new("ImageLabel", {
    Size = UDim2.fromOffset(34, 34), Position = UDim2.fromOffset(12, 9),
    BackgroundColor3 = Color3.fromRGB(14, 8, 11), BackgroundTransparency = 0,
    BorderSizePixel = 0, Image = "rbxassetid://114578684289019",
    ScaleType = Enum.ScaleType.Crop, ImageTransparency = 0,
}, header)
round(logo, 8)

local title = text(header, { Size = UDim2.fromOffset(190, 22), Position = UDim2.fromOffset(54, 5), RichText = true, TextSize = 17, Font = Enum.Font.GothamBold })
regFn(function()
	title.Text = '<font color="#' .. theme.accent:ToHex() .. '">' .. HUB_A .. '</font> ' .. HUB_B
end)
text(header, { Size = UDim2.fromOffset(190, 16), Position = UDim2.fromOffset(54, 27), Text = HUB_BY, TextColor3 = C.muted, TextSize = 12 })

local pill = new("Frame", { Size = UDim2.fromOffset(128, 28), Position = UDim2.fromOffset(246, 12), BorderSizePixel = 0 }, header)
round(pill, 14)
reg(pill, "BackgroundColor3", "accent")
text(pill, { Size = UDim2.new(1, 0, 1, 0), Text = "Версия 5.8 Alfa", TextXAlignment = Enum.TextXAlignment.Center, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.new(1, 1, 1) })

-- Minimized state: thin bar at the bottom of the screen
local bar = new("TextButton", {
	Name = "DS_Bar", Size = UDim2.fromOffset(180, 22), AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Visible = false,
}, gui)
local stick = new("Frame", {
	Size = UDim2.fromOffset(110, 4), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -4), BorderSizePixel = 0,
}, bar)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, stick)
reg(stick, "BackgroundColor3", "accent")
bar.MouseButton1Click:Connect(function()
	main.Visible = true
	bar.Visible = false
end)

local function ctrl(txt, xOff, cb)
	local b = new("TextButton", {
		Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, xOff, 0, 12), BackgroundTransparency = 1,
		Text = txt, TextColor3 = C.text, Font = Enum.Font.GothamBold, TextSize = 16, AutoButtonColor = false,
	}, main)
	b.MouseButton1Click:Connect(cb)
	return b
end

local maximized, normalSize, normalPos = false, nil, nil
ctrl("–", -102, function()
	main.Visible = false
	bar.Visible = true
end)
ctrl("□", -70, function()
	if not maximized then
		normalSize, normalPos = main.Size, main.Position
		main.Size = UDim2.new(0.92, 0, 0.92, 0)
		main.Position = UDim2.new(0.04, 0, 0.04, 0)
	else
		main.Size, main.Position = normalSize, normalPos
	end
	maximized = not maximized
end)
ctrl("×", -38, function() cleanup() end)

-- Sidebar + content
local sidebar = new("ScrollingFrame", {
	Position = UDim2.new(0, 8, 0, 58), Size = UDim2.new(0, 132, 1, -66), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, main)
new("UIListLayout", { Padding = UDim.new(0, 4) }, sidebar)

local content = new("Frame", { Position = UDim2.new(0, 148, 0, 58), Size = UDim2.new(1, -156, 1, -66), BackgroundTransparency = 1 }, main)

local pages, tabs = {}, {}

local function selectTab(name)
	for n, p in pairs(pages) do p.Visible = (n == name) end
	for n, t in pairs(tabs) do
		t.btn.BackgroundTransparency = (n == name) and 0.35 or 1
		t.label.TextColor3 = (n == name) and Color3.new(1, 1, 1) or C.muted
	end
end

local function addTab(name, icon)
	local btn = new("TextButton", { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, sidebar)
	round(btn, 8)
	reg(btn, "BackgroundColor3", "side")
	local ic = text(btn, { Size = UDim2.fromOffset(26, 32), Position = UDim2.fromOffset(8, 0), Text = icon, TextXAlignment = Enum.TextXAlignment.Center, TextSize = 15 })
	reg(ic, "TextColor3", "accent")
	local label = text(btn, { Size = UDim2.new(1, -40, 1, 0), Position = UDim2.fromOffset(38, 0), en = name, TextColor3 = C.muted })

	local page = new("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false,
	}, content)
	reg(page, "ScrollBarImageColor3", "accent")
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)
	pad(page, 0, 8, 0, 6)

	pages[name] = page
	tabs[name] = { btn = btn, label = label }
	btn.MouseButton1Click:Connect(function() selectTab(name) end)
	return page
end

----------------------------------------------------------------
-- Components
----------------------------------------------------------------
local function nextLO(page)
	local n = (page:GetAttribute("n") or 0) + 1
	page:SetAttribute("n", n)
	return n
end

local function newRow(page, h)
	local r = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 0.2, BorderSizePixel = 0, LayoutOrder = nextLO(page) }, page)
	round(r, 10)
	reg(r, "BackgroundColor3", "row")
	return r
end

local function addToggle(page, label, default, cb)
	local r = newRow(page, 44)
	text(r, { Size = UDim2.new(1, -80, 1, 0), Position = UDim2.fromOffset(14, 0), en = label })
	local on = default
	local sw = new("TextButton", {
		Size = UDim2.fromOffset(46, 24), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
		Text = "", AutoButtonColor = false,
	}, r)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, sw)
	regFn(function() sw.BackgroundColor3 = on and theme.accent or theme.off end)
	local knob = new("Frame", {
		Size = UDim2.fromOffset(18, 18), AnchorPoint = Vector2.new(0, 0.5),
		Position = on and UDim2.new(1, -22, 0.5, 0) or UDim2.new(0, 4, 0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
	}, sw)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)

	local ctl = {}
	function ctl.set(v, silent)
		on = v
		local ti = TweenInfo.new(0.15)
		TweenService:Create(sw, ti, { BackgroundColor3 = on and theme.accent or theme.off }):Play()
		TweenService:Create(knob, ti, { Position = on and UDim2.new(1, -22, 0.5, 0) or UDim2.new(0, 4, 0.5, 0) }):Play()
		if cb and not silent then cb(on) end
	end
	sw.MouseButton1Click:Connect(function() ctl.set(not on) end)
	return ctl
end

local function addButton(page, label, cb, accented)
	local r = newRow(page, 40)
	reg(r, "BackgroundColor3", accented and "accent" or "row")
	local b = new("TextButton", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamMedium,
		TextColor3 = C.text, TextSize = 14, AutoButtonColor = false,
	}, r)
	reglang(function() b.Text = T(label) end)
	b.MouseButton1Click:Connect(function()
		r.BackgroundColor3 = accented and Color3.new(1, 1, 1) or theme.accent
		TweenService:Create(r, TweenInfo.new(0.3), { BackgroundColor3 = accented and theme.accent or theme.row }):Play()
		cb()
	end)
	return r
end

local function addSlider(page, label, min, max, default, cb)
	local r = newRow(page, 54)
	text(r, { Size = UDim2.new(0.6, 0, 0, 28), Position = UDim2.fromOffset(14, 2), en = label })
	local val = text(r, { Size = UDim2.new(0.4, -26, 0, 28), Position = UDim2.new(0.6, 0, 0, 2), Text = tostring(math.floor(default + 0.5)), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = C.muted })
	local track = new("Frame", { Size = UDim2.new(1, -28, 0, 6), Position = UDim2.new(0, 14, 0, 38), BorderSizePixel = 0 }, r)
	round(track, 3)
	reg(track, "BackgroundColor3", "off")
	local fill = new("Frame", { Size = UDim2.new((default - min) / (max - min), 0, 1, 0), BorderSizePixel = 0 }, track)
	round(fill, 3)
	reg(fill, "BackgroundColor3", "accent")
	local hit = new("TextButton", { Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0, 0, 0, 28), BackgroundTransparency = 1, Text = "" }, r)

	local dragging = false
	local function setFromX(x)
		local a = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		local v = math.floor(min + (max - min) * a + 0.5)
		fill.Size = UDim2.new(a, 0, 1, 0)
		val.Text = tostring(v)
		cb(v)
	end
	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			page.ScrollingEnabled = false
			setFromX(input.Position.X)
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					page.ScrollingEnabled = true
				end
			end)
		end
	end)
	bind(UserInputService.InputChanged, function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
			setFromX(input.Position.X)
		end
	end)

	local ctl = {}
	function ctl.set(v)
		local a = math.clamp((v - min) / (max - min), 0, 1)
		fill.Size = UDim2.new(a, 0, 1, 0)
		val.Text = tostring(math.floor(v + 0.5))
	end
	return ctl
end

local function addInfo(page, key, value)
	local r = newRow(page, 38)
	text(r, { Size = UDim2.new(0.4, 0, 1, 0), Position = UDim2.fromOffset(14, 0), en = key, TextColor3 = C.muted, TextSize = 13 })
	text(r, {
		Size = UDim2.new(0.6, -26, 1, 0), Position = UDim2.new(0.4, 0, 0, 0), Text = tostring(value),
		TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, TextSize = 13,
	})
end

local function addNote(page, en)
	return text(page, {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, en = en, TextColor3 = C.muted,
		TextSize = 12, TextWrapped = true, LayoutOrder = nextLO(page),
	})
end

local function addChoice(page, label, options, current, cb)
	local r = newRow(page, 64)
	text(r, { Size = UDim2.new(1, -24, 0, 24), Position = UDim2.fromOffset(14, 6), en = label })
	local holder = new("Frame", { Size = UDim2.new(1, -28, 0, 26), Position = UDim2.fromOffset(14, 32), BackgroundTransparency = 1 }, r)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }, holder)
	local btns = {}
	local function refresh()
		for v, b in pairs(btns) do b.BackgroundColor3 = (v == current) and theme.accent or theme.side end
	end
	for _, opt in ipairs(options) do
		local b = new("TextButton", {
			Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X, BorderSizePixel = 0,
			Text = opt.label, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = Color3.new(1, 1, 1),
		}, holder)
		round(b, 13)
		pad(b, 14, 14, 0, 0)
		btns[opt.value] = b
		b.MouseButton1Click:Connect(function()
			current = opt.value
			refresh()
			cb(opt.value)
		end)
	end
	regFn(refresh)
end

local function addSwatches(page, label, hues, cb)
	local r = newRow(page, 64)
	text(r, { Size = UDim2.new(1, -24, 0, 24), Position = UDim2.fromOffset(14, 6), en = label })
	local holder = new("Frame", { Size = UDim2.new(1, -28, 0, 26), Position = UDim2.fromOffset(14, 32), BackgroundTransparency = 1 }, r)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10) }, holder)
	for _, h in ipairs(hues) do
		local s = new("TextButton", { Size = UDim2.fromOffset(26, 26), BackgroundColor3 = Color3.fromHSV(h, 0.82, 1), Text = "", AutoButtonColor = false }, holder)
		new("UICorner", { CornerRadius = UDim.new(1, 0) }, s)
		s.MouseButton1Click:Connect(function() cb(h) end)
	end
end

----------------------------------------------------------------
-- Tabs
----------------------------------------------------------------
local pInfo = addTab("Info", "ⓘ")
local pESP = addTab("ESP", "◉")
local pLocal = addTab("Local Player", "☺")
local pAim = addTab("Aim", "⌖")
local pMisc = addTab("Misc", "▤")
local pTp = addTab("Teleports", "➤")
local pFarm = addTab("Farm", "☠")
local pSky = addTab("Sky", "☁")
local pMusic = addTab("Music", "♫")
local pGfx = addTab("Graphics", "✺")
local pSet = addTab("Settings", "⚙")

-- Info
local gameName, execName = "?", "?"
pcall(function() gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name end)
pcall(function() execName = identifyexecutor() end)
addInfo(pInfo, "Player", lp.DisplayName .. " (@" .. lp.Name .. ")")
addInfo(pInfo, "Game", gameName)
addInfo(pInfo, "PlaceId", game.PlaceId)
addInfo(pInfo, "Executor", execName)

-- ESP: intentionally limited to NPCs/training dummies, not other players.
addNote(pESP, "NPC ESP работает на NPC и тренировочных манекенах. Отображение игроков сквозь стены не включено.")
local npcEspEnabled, npcNamesEnabled = false, true
local npcMarks, npcTags = {}, {}
local function clearNpcMark(model)
    local mark = npcMarks[model]
    if mark then pcall(function() mark:Destroy() end); npcMarks[model] = nil end
    local tag = npcTags[model]
    if tag then pcall(function() tag:Destroy() end); npcTags[model] = nil end
end
local function updateNpcEsp()
    if not npcEspEnabled and not npcNamesEnabled then
        for model in pairs(npcMarks) do clearNpcMark(model) end
        return
    end
    local alive = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) and obj ~= lp.Character then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local root = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")
            if hum and root and hum.Health > 0 then
                alive[obj] = true
                local mark = npcMarks[obj]
                if not mark then
                    mark = new("Highlight", { Name = "DS_NPC_Highlight", Adornee = obj, FillColor = theme.accent, OutlineColor = Color3.new(1,1,1), FillTransparency = 0.78, OutlineTransparency = 0.1, Enabled = false }, gui)
                    npcMarks[obj] = mark
                end
                mark.Enabled = npcEspEnabled
                mark.FillColor = theme.accent
                local tag = npcTags[obj]
                if npcNamesEnabled and not tag then
                    tag = new("BillboardGui", { Name = "DS_NPC_Tag", Adornee = root, Size = UDim2.fromOffset(150, 28), StudsOffset = Vector3.new(0, 2.6, 0), AlwaysOnTop = true, Enabled = true }, gui)
                    local label = new("TextLabel", { Size = UDim2.new(1,0,1,0), BackgroundColor3 = Color3.fromRGB(18,18,24), BackgroundTransparency = 0.25, TextColor3 = Color3.new(1,1,1), TextStrokeTransparency = 0.5, TextSize = 12, Font = Enum.Font.GothamSemibold, Text = obj.Name }, tag)
                    round(label, 7)
                    npcTags[obj] = tag
                elseif tag and not npcNamesEnabled then
                    tag:Destroy(); npcTags[obj] = nil
                elseif tag then
                    tag.Adornee = root
                end
            end
        end
    end
    for model, mark in pairs(npcMarks) do
        if typeof(model) == "Instance" and model:IsA("Model") and not alive[model] then clearNpcMark(model) end
    end
end
addToggle(pESP, "NPC highlight", false, function(v) npcEspEnabled = v; updateNpcEsp() end)
addToggle(pESP, "NPC name tags", true, function(v) npcNamesEnabled = v; updateNpcEsp() end)
local espClock = 0
bind(RunService.Heartbeat, function(dt)
    espClock += dt
    if espClock >= 1.2 then espClock = 0; pcall(updateNpcEsp) end
end)

-- Local Player: local character settings; restore original values on disable.
local function currentHumanoid()
    local char = lp.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end
local savedMovement = {}
local function applyHumanoid(prop, value)
    local h = currentHumanoid()
    if not h then return end
    if savedMovement[prop] == nil then savedMovement[prop] = h[prop] end
    h[prop] = value
end
addNote(pLocal, "Настройки действуют только на твоего персонажа и зависят от ограничений игры.")
addSlider(pLocal, "WalkSpeed", 8, 32, 16, function(v) applyHumanoid("WalkSpeed", v) end)
addSlider(pLocal, "JumpPower", 25, 100, 50, function(v)
    local h = currentHumanoid()
    if h then
        if h.UseJumpPower then applyHumanoid("JumpPower", v) else applyHumanoid("JumpHeight", math.max(3, v / 7)) end
    end
end)
addButton(pLocal, "↩ Restore movement", function()
    local h = currentHumanoid()
    if h then for prop, value in pairs(savedMovement) do pcall(function() h[prop] = value end) end end
    table.clear(savedMovement)
end)
lp.CharacterAdded:Connect(function() task.wait(1); table.clear(savedMovement) end)

-- Aim: reticle and camera field of view only; no automatic targeting.
addNote(pAim, "Настройки визуального прицела и камеры. Автонаведение не используется.")
local aimCircle = new("ImageLabel", {
    Name = "DS_AimFOV", Size = UDim2.fromOffset(180, 180), AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
    Image = "rbxassetid://114578684289019", ScaleType = Enum.ScaleType.Fit,
    Visible = false, ZIndex = 20,
}, gui)
addToggle(pAim, "Show FOV circle", false, function(v) aimCircle.Visible = v end)
addSlider(pAim, "FOV circle size", 60, 360, 180, function(v) aimCircle.Size = UDim2.fromOffset(v, v) end)
addSlider(pAim, "Camera FOV", 60, 100, 70, function(v)
    local cam = workspace.CurrentCamera
    if cam then cam.FieldOfView = v end
end)
addButton(pAim, "↩ Reset camera FOV", function()
    local cam = workspace.CurrentCamera
    if cam then cam.FieldOfView = 70 end
end)

-- Training lock targets NPCs only; it never locks onto other players.
local npcLockEnabled = false
local function nearestNpcInFov()
    local cam = workspace.CurrentCamera
    if not cam then return nil end
    local center = cam.ViewportSize / 2
    local best, bestDist = nil, math.huge
    local radius = aimCircle.Visible and aimCircle.AbsoluteSize.X / 2 or 140
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) and obj ~= lp.Character then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local root = obj:FindFirstChild("Head") or obj:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and root then
                local pos, onScreen = cam:WorldToViewportPoint(root.Position)
                if onScreen and pos.Z > 0 then
                    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if dist < radius and dist < bestDist then best, bestDist = root, dist end
                end
            end
        end
    end
    return best
end
addToggle(pAim, "NPC training lock", false, function(v) npcLockEnabled = v end)
bind(RunService.RenderStepped, function(dt)
    if not npcLockEnabled then return end
    local cam = workspace.CurrentCamera
    local target = nearestNpcInFov()
    if cam and target then
        local goal = CFrame.lookAt(cam.CFrame.Position, target.Position)
        cam.CFrame = cam.CFrame:Lerp(goal, math.clamp(dt * 5, 0, 0.22))
    end
end)

-- Misc: Pro key panel and local utility controls.
addNote(pMisc, "Дополнительные параметры интерфейса.")

local proUnlocked = false
local function makeModal(name, height)
    local overlay = new("TextButton", {
        Name = name .. "Overlay", Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(5, 7, 12),
        BackgroundTransparency = 0.42, Text = "", AutoButtonColor = false, ZIndex = 100,
    }, gui)
    local blurFx = new("BlurEffect", { Name = name .. "Blur", Size = 0 }, Lighting)
    TweenService:Create(blurFx, TweenInfo.new(0.25), { Size = 18 }):Play()
    local card = new("Frame", {
        Name = name, Size = UDim2.new(0.84, 0, 0, height), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 18), BackgroundColor3 = Color3.fromRGB(27, 29, 36),
        BackgroundTransparency = 0.12, BorderSizePixel = 0, ZIndex = 101,
    }, overlay)
    round(card, 18)
    new("UIStroke", { Color = Color3.fromRGB(255,255,255), Transparency = 0.78, Thickness = 1 }, card)
    pad(card, 18, 18, 16, 16)
    TweenService:Create(card, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 0.5, 0) }):Play()
    local function close()
        pcall(function() blurFx:Destroy() end)
        pcall(function() overlay:Destroy() end)
    end
    return overlay, card, close
end

local function showAlphaWarning()
    local overlay, card, close = makeModal("DS_AlphaWarning", 240)
    text(card, { Size = UDim2.new(1, 0, 0, 30), Text = "⚠  Внимание", Font = Enum.Font.GothamBold, TextSize = 20, ZIndex = 102 })
    text(card, { Size = UDim2.new(1, 0, 0, 68), Position = UDim2.fromOffset(0, 38), Text = "Учтите: это альфа-версия скрипта. Возможны недоработки и баги.", TextWrapped = true, TextSize = 14, ZIndex = 102 })
    local check = new("TextButton", { Size = UDim2.fromOffset(24, 24), Position = UDim2.fromOffset(0, 116), Text = "", BackgroundColor3 = Color3.fromRGB(45,47,56), BorderSizePixel = 0, ZIndex = 102 }, card)
    round(check, 5)
    new("UIStroke", { Color = theme.accent, Transparency = 0.2, Thickness = 1 }, check)
    local checkMark = text(check, { Size = UDim2.new(1,0,1,0), Text = "✓", TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = Color3.new(1,1,1), Visible = false, ZIndex = 103 })
    text(card, { Size = UDim2.new(1, -34, 0, 26), Position = UDim2.fromOffset(34, 115), Text = "Я ознакомился с предупреждением", TextSize = 12, TextWrapped = true, ZIndex = 102 })
    local accept = new("TextButton", { Size = UDim2.new(1, 0, 0, 38), Position = UDim2.new(0, 0, 1, -40), Text = "Я принимаю условия и продолжить", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.new(1,1,1), BackgroundColor3 = theme.accent, BackgroundTransparency = 0.2, Visible = false, ZIndex = 102 }, card)
    round(accept, 10)
    check.MouseButton1Click:Connect(function()
        local checked = not checkMark.Visible
        checkMark.Visible = checked
        accept.Visible = checked
    end)
    accept.MouseButton1Click:Connect(close)
end

local function showProDashboard()
    main.Visible = false
    local overlay, card, close = makeModal("DS_ProDashboard", 330)
    text(card, { Size = UDim2.new(1,0,0,30), Text = "✦  DARKNES PRO", Font = Enum.Font.GothamBlack, TextSize = 21, ZIndex = 102 })
    text(card, { Size = UDim2.new(1,0,0,22), Position = UDim2.fromOffset(0,34), Text = "Премиальная панель · 5.8 Alfa", TextSize = 12, TextColor3 = C.muted, ZIndex = 102 })
    local function proButton(y, label, cb)
        local b = new("TextButton", { Size = UDim2.new(1,0,0,38), Position = UDim2.fromOffset(0,y), BackgroundColor3 = Color3.fromRGB(48,42,60), TextColor3 = C.text, Text = label, Font = Enum.Font.GothamSemibold, TextSize = 13, AutoButtonColor = true, ZIndex = 102 }, card)
        round(b, 10)
        b.MouseButton1Click:Connect(cb)
        return b
    end
    proButton(66, "Прицел: показать / скрыть FOV", function() aimCircle.Visible = not aimCircle.Visible end)
    proButton(110, "NPC Training Lock: вкл. / выкл.", function() npcLockEnabled = not npcLockEnabled end)
    proButton(154, "NPC ESP: вкл. / выкл.", function() npcEspEnabled = not npcEspEnabled; updateNpcEsp() end)
    proButton(198, "Переключить тему акцента", function()
        local nextHue = ((cfg.hue or 0.968) + 0.13) % 1
        setHue(nextHue)
    end)
    local back = proButton(266, "← Вернуться в обычное меню", function() close(); main.Visible = true end)
    back.BackgroundColor3 = theme.accent
end

local function showProKey()
    if proUnlocked then
        local overlay, card, close = makeModal("DS_ProInfo", 130)
        text(card, { Size = UDim2.new(1,0,0,34), Text = "Darknes Pro", Font = Enum.Font.GothamBold, TextSize = 19, ZIndex = 102 })
        text(card, { Size = UDim2.new(1,0,0,30), Position = UDim2.fromOffset(0,42), Text = "Pro-режим уже активирован.", TextSize = 13, ZIndex = 102 })
        return
    end
    local overlay, card, close = makeModal("DS_ProKey", 205)
    text(card, { Size = UDim2.new(1,0,0,30), Text = "Darknes Pro", Font = Enum.Font.GothamBold, TextSize = 20, ZIndex = 102 })
    text(card, { Size = UDim2.new(1,0,0,25), Position = UDim2.fromOffset(0,35), Text = "Введите ключ для продолжения", TextSize = 13, ZIndex = 102 })
    local box = new("TextBox", { Size = UDim2.new(1,0,0,38), Position = UDim2.fromOffset(0,68), BackgroundColor3 = Color3.fromRGB(43,45,54), TextColor3 = C.text, PlaceholderText = "Ключ", Text = "", ClearTextOnFocus = false, Font = Enum.Font.Gotham, TextSize = 14, ZIndex = 102 }, card)
    round(box, 9)
    local status = text(card, { Size = UDim2.new(1,0,0,20), Position = UDim2.fromOffset(0,108), Text = "", TextColor3 = C.muted, TextSize = 12, ZIndex = 102 })
    local enter = new("TextButton", { Size = UDim2.new(1,0,0,36), Position = UDim2.new(0,0,1,-38), Text = "Активировать", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.new(1,1,1), BackgroundColor3 = theme.accent, ZIndex = 102 }, card)
    round(enter, 9)
    enter.MouseButton1Click:Connect(function()
        if box.Text == "Darknes" then
            proUnlocked = true
            status.Text = "Ключ принят"
            task.wait(0.35)
            close()
            showProDashboard()
        else
            status.Text = "Неверный ключ"
        end
    end)
end
addButton(pMisc, "✦ Переключиться на Pro", showProKey, true)
addToggle(pMisc, "Compact UI", false, function(v)
    TweenService:Create(main, TweenInfo.new(0.2), { Size = v and UDim2.fromOffset(460, 280) or UDim2.fromOffset(WIN_W, WIN_H) }):Play()
end)

----------------------------------------------------------------
-- Sky (local only)
----------------------------------------------------------------
local LIGHT_PROPS = { "ClockTime", "Ambient", "OutdoorAmbient", "Brightness", "ColorShift_Top", "ColorShift_Bottom" }
local FX = {
	Atmosphere = { "Color", "Decay", "Density", "Haze", "Glare", "Offset" },
	ColorCorrectionEffect = { "TintColor", "Saturation", "Contrast" },
	BloomEffect = { "Intensity", "Size", "Threshold" },
	Sky = { "StarCount", "CelestialBodiesShown", "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp" },
}
local DEFAULT_SKY = {
	SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex", SkyboxDn = "rbxasset://textures/sky/sky512_dn.tex",
	SkyboxFt = "rbxasset://textures/sky/sky512_ft.tex", SkyboxLf = "rbxasset://textures/sky/sky512_lf.tex",
	SkyboxRt = "rbxasset://textures/sky/sky512_rt.tex", SkyboxUp = "rbxasset://textures/sky/sky512_up.tex",
}
local SKY_TI = TweenInfo.new(1.5, Enum.EasingStyle.Sine)

local saved, made, skyTweens = nil, {}, {}

local function snapshot()
	if saved then return end
	saved = { light = {}, fx = {} }
	for _, p in ipairs(LIGHT_PROPS) do saved.light[p] = Lighting[p] end
	for class, props in pairs(FX) do
		for _, o in ipairs(Lighting:GetChildren()) do
			if o:IsA(class) and not o.Name:find("^DS_") then
				local t = {}
				for _, p in ipairs(props) do t[p] = o[p] end
				saved.fx[o] = t
				break
			end
		end
	end
end

-- Reuses the game's own object of that class (restored on reset), otherwise makes our own DS_ one
local function getOrMake(class, name)
	for _, o in ipairs(Lighting:GetChildren()) do
		if o:IsA(class) and not o.Name:find("^DS_") then return o end
	end
	local mine = Lighting:FindFirstChild("DS_" .. name)
	if mine then return mine end
	mine = Instance.new(class)
	mine.Name = "DS_" .. name
	mine.Parent = Lighting
	table.insert(made, mine)
	return mine
end

local function skyTween(obj, props)
	local tw = TweenService:Create(obj, SKY_TI, props)
	table.insert(skyTweens, tw)
	tw:Play()
end

local function cancelSkyTweens()
	for _, tw in ipairs(skyTweens) do pcall(function() tw:Cancel() end) end
	skyTweens = {}
end

local function applySky(p)
	snapshot()
	cancelSkyTweens()
	skyTween(Lighting, {
		ClockTime = p.clock, Brightness = p.brightness, Ambient = p.ambient, OutdoorAmbient = p.outdoor,
		ColorShift_Top = p.shiftTop, ColorShift_Bottom = p.shiftBottom,
	})
	skyTween(getOrMake("Atmosphere", "SkyAtmosphere"), p.atm)
	skyTween(getOrMake("ColorCorrectionEffect", "SkyColor"), p.cc)
	skyTween(getOrMake("BloomEffect", "SkyBloom"), p.bloom)

	local sky = getOrMake("Sky", "Sky")
	sky.StarCount = p.stars
	sky.CelestialBodiesShown = true
	local faces = DEFAULT_SKY
	if p.skybox then
		faces = {
			SkyboxBk = p.skybox.Bk, SkyboxDn = p.skybox.Dn, SkyboxFt = p.skybox.Ft,
			SkyboxLf = p.skybox.Lf, SkyboxRt = p.skybox.Rt, SkyboxUp = p.skybox.Up,
		}
	end
	for k, v in pairs(faces) do sky[k] = v end
end

local function resetSky()
	cancelSkyTweens()
	if not saved then return end
	for p, v in pairs(saved.light) do Lighting[p] = v end
	for obj, props in pairs(saved.fx) do
		if obj.Parent then
			for p, v in pairs(props) do obj[p] = v end
		end
	end
	for _, o in ipairs(made) do o:Destroy() end
	saved, made = nil, {}
end

addNote(pSky, "Changes only your own sky. Other players see the normal one.")
addButton(pSky, "🌌 Galaxy", function() applySky(SkyPresets.Galaxy) end)
addButton(pSky, "🌸 Tone 618", function() applySky(SkyPresets.Tone618) end)
addButton(pSky, "🌇 Pink Sunset", function() applySky(SkyPresets.PinkSunset) end)
addButton(pSky, "🌃 Neon Night", function() applySky(SkyPresets.NeonNight) end)
addButton(pSky, "☀️ Clear Day", function() applySky(SkyPresets.ClearDay) end)
addButton(pSky, "↩ Reset sky", resetSky)

----------------------------------------------------------------
-- Music (local only)
----------------------------------------------------------------
local sound = new("Sound", { Name = "DS_Music", Looped = true, Volume = 0.5 }, SoundService)

local function resolveSource(src)
	src = tostring(src)
	if src:match("^%d+$") then return "rbxassetid://" .. src end
	if src:find("^rbxassetid://") or src:find("^rbxasset://") then return src end
	if src:find("^https?://") then
		if not (request and writefile and getcustomasset) then
			return nil, "executor lacks request/writefile/getcustomasset"
		end
		local name = "dsmusic_" .. src:gsub("[^%w]", ""):sub(-40) .. ".mp3"
		local ok, err = pcall(function()
			if not (isfile and isfile(name)) then
				local res = request({ Url = src, Method = "GET" })
				if not res or not res.Body or #res.Body < 1000 then error("download failed") end
				writefile(name, res.Body)
			end
		end)
		if not ok then return nil, tostring(err) end
		local ok2, asset = pcall(getcustomasset, name)
		if not ok2 then return nil, "getcustomasset failed" end
		return asset
	end
	return nil, "unknown source format"
end

local nowState = { kind = "idle" }
local nowLabel = text(pMusic, { Size = UDim2.new(1, 0, 0, 36), TextColor3 = C.muted, TextSize = 13, TextWrapped = true, LayoutOrder = nextLO(pMusic) })
local function renderNow()
	local s = nowState
	if s.kind == "idle" then
		nowLabel.Text = T("Nothing is playing")
	elseif s.kind == "play" then
		nowLabel.Text = "▶ " .. s.title .. " (" .. T(s.variant) .. ")"
	elseif s.kind == "nosrc" then
		nowLabel.Text = T("No source: put an ID or link into Songs →") .. " " .. s.title
	else
		nowLabel.Text = T("Error:") .. " " .. tostring(s.msg)
	end
end
reglang(renderNow)

local function playSong(song, var)
	local src = var.src or song.src
	if not src or src == "" then
		nowState = { kind = "nosrc", title = song.title }
		renderNow()
		return
	end
	local id, err = resolveSource(src)
	if not id then
		nowState = { kind = "err", msg = err }
		renderNow()
		return
	end
	sound:Stop()
	sound.SoundId = id
	sound.PlaybackSpeed = var.speed or 1
	sound:Play()
	nowState = { kind = "play", title = song.title, variant = var.label }
	renderNow()
end

addButton(pMusic, "⏯ Pause / Resume", function()
	if sound.IsPlaying then sound:Pause() else sound:Resume() end
end)
addButton(pMusic, "⏹ Stop", function()
	sound:Stop()
	nowState = { kind = "idle" }
	renderNow()
end)
addSlider(pMusic, "Volume", 0, 100, 50, function(v) sound.Volume = v / 100 end)

for _, song in ipairs(Songs) do
	local card = new("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 0.2, BorderSizePixel = 0, LayoutOrder = nextLO(pMusic),
	}, pMusic)
	round(card, 10)
	reg(card, "BackgroundColor3", "row")
	pad(card, 12, 12, 10, 10)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, card)

	local title = song.title
	if song.artist ~= "" then title = title .. "  ·  " .. song.artist end
	text(card, { Size = UDim2.new(1, 0, 0, 20), Text = title, LayoutOrder = 1 })

	local chips = new("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = 2 }, card)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Wraps = true, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, chips)

	for i, var in ipairs(song.variants) do
		local chip = new("TextButton", {
			Size = UDim2.fromOffset(0, 26), AutomaticSize = Enum.AutomaticSize.X, BorderSizePixel = 0,
			Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = C.text, LayoutOrder = i,
		}, chips)
		round(chip, 13)
		pad(chip, 12, 12, 0, 0)
		reg(chip, "BackgroundColor3", "side")
		reglang(function() chip.Text = T(var.label) end)
		chip.MouseButton1Click:Connect(function() playSong(song, var) end)
	end
end

----------------------------------------------------------------
-- Graphics: Potato mode + DLSS 5 mode
----------------------------------------------------------------
local function mkFx(class, name, props)
	local o = Instance.new(class)
	o.Name = name
	for k, v in pairs(props) do o[k] = v end
	o.Parent = Lighting
	return o
end

-- Potato mode ------------------------------------------------
local potato = { on = false, token = 0, saved = setmetatable({}, { __mode = "k" }) }

local function setP(inst, prop, value)
	local rec = potato.saved[inst]
	if not rec then
		rec = {}
		potato.saved[inst] = rec
	end
	if rec[prop] == nil then
		local ok, cur = pcall(function() return inst[prop] end)
		if not ok then return end
		rec[prop] = cur
	end
	pcall(function() inst[prop] = value end)
end

local EFFECTS = { ParticleEmitter = true, Trail = true, Beam = true, Fire = true, Smoke = true, Sparkles = true }

local function inCharacter(inst)
	local m = inst:FindFirstAncestorOfClass("Model")
	return m ~= nil and m:FindFirstChildOfClass("Humanoid") ~= nil
end

local function potatoInst(inst)
	if EFFECTS[inst.ClassName] then
		setP(inst, "Enabled", false)
	elseif inst:IsA("BasePart") then
		if inst:IsA("Terrain") or inCharacter(inst) then return end
		if inst.Material ~= Enum.Material.Neon and inst.Material ~= Enum.Material.ForceField then
			setP(inst, "Material", Enum.Material.SmoothPlastic)
		end
		setP(inst, "Reflectance", 0)
		setP(inst, "CastShadow", false)
		if inst:IsA("MeshPart") then setP(inst, "RenderFidelity", Enum.RenderFidelity.Performance) end
	elseif inst:IsA("Decal") or inst:IsA("Texture") then
		if inCharacter(inst) then return end
		setP(inst, "Transparency", 1)
	elseif inst:IsA("Light") then
		setP(inst, "Shadows", false)
	end
end

local function potatoOn()
	if potato.on then return end
	potato.on = true
	potato.token = potato.token + 1
	local token = potato.token

	potato.light = {}
	for _, p in ipairs({ "GlobalShadows", "EnvironmentDiffuseScale", "EnvironmentSpecularScale" }) do
		local ok, v = pcall(function() return Lighting[p] end)
		if ok then potato.light[p] = v end
	end
	pcall(function() Lighting.GlobalShadows = false end)
	pcall(function() Lighting.EnvironmentDiffuseScale = 0 end)
	pcall(function() Lighting.EnvironmentSpecularScale = 0 end)
	pcall(function() potato.quality = settings().Rendering.QualityLevel end)
	pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)

	for _, e in ipairs(Lighting:GetChildren()) do
		if e:IsA("PostEffect") and not e.Name:find("^DS_") then setP(e, "Enabled", false) end
	end

	local terrain = workspace:FindFirstChildOfClass("Terrain")
	if terrain then
		setP(terrain, "WaterWaveSize", 0)
		setP(terrain, "WaterWaveSpeed", 0)
		setP(terrain, "WaterReflectance", 0)
		pcall(function()
			potato.deco = gethiddenproperty(terrain, "Decoration")
			sethiddenproperty(terrain, "Decoration", false)
		end)
	end

	potato.conn = workspace.DescendantAdded:Connect(function(inst)
		if potato.on then pcall(potatoInst, inst) end
	end)

	task.spawn(function()
		local all = workspace:GetDescendants()
		for i, inst in ipairs(all) do
			if potato.token ~= token or not potato.on then return end
			pcall(potatoInst, inst)
			if i % 300 == 0 then task.wait() end
		end
	end)
end

local function potatoOff()
	if not potato.on then return end
	potato.on = false
	potato.token = potato.token + 1
	if potato.conn then
		potato.conn:Disconnect()
		potato.conn = nil
	end
	local savedInst = potato.saved
	-- Restore original values before allowing another activation; this prevents
	-- a fast off/on toggle from racing an older asynchronous restore.
	for p, v in pairs(potato.light or {}) do pcall(function() Lighting[p] = v end) end
	if potato.quality ~= nil then pcall(function() settings().Rendering.QualityLevel = potato.quality end) end
	if potato.deco ~= nil then
		pcall(function()
			local terrain = workspace:FindFirstChildOfClass("Terrain")
			if terrain then sethiddenproperty(terrain, "Decoration", potato.deco) end
		end)
	end
	potato.light, potato.quality, potato.deco = nil, nil, nil
	potato.saved = setmetatable({}, { __mode = "k" })
	local i = 0
	for inst, rec in pairs(savedInst) do
		for prop, v in pairs(rec) do
			pcall(function() inst[prop] = v end)
		end
		i = i + 1
		-- Yield periodically so large maps do not freeze the client.
		if i % 400 == 0 then task.wait() end
	end
end

-- DLSS 5 style mode ------------------------------------------
local ultra = { on = false }

local function ultraOn()
	if ultra.on then return end
	ultra.on = true
	ultra.light = {}
	for _, p in ipairs({ "GlobalShadows", "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "ExposureCompensation", "ShadowSoftness" }) do
		local ok, v = pcall(function() return Lighting[p] end)
		if ok then ultra.light[p] = v end
	end
	pcall(function() ultra.quality = settings().Rendering.QualityLevel end)
	pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level21 end)
	pcall(function() Lighting.GlobalShadows = true end)
	pcall(function() Lighting.EnvironmentDiffuseScale = 1 end)
	pcall(function() Lighting.EnvironmentSpecularScale = 1 end)
	pcall(function() Lighting.ExposureCompensation = 0.15 end)
	pcall(function() Lighting.ShadowSoftness = 0.2 end)
	ultra.fx = {
		mkFx("BloomEffect", "DS_UltraBloom", { Intensity = 0.4, Size = 28, Threshold = 0.92 }),
		mkFx("SunRaysEffect", "DS_UltraSun", { Intensity = 0.15, Spread = 0.9 }),
		mkFx("ColorCorrectionEffect", "DS_UltraColor", { Contrast = 0.1, Saturation = 0.15, Brightness = 0.02 }),
		mkFx("DepthOfFieldEffect", "DS_UltraDOF", { FarIntensity = 0.1, FocusDistance = 120, InFocusRadius = 80, NearIntensity = 0 }),
	}
end

local function ultraOff()
	if not ultra.on then return end
	ultra.on = false
	for _, o in ipairs(ultra.fx or {}) do pcall(function() o:Destroy() end) end
	for p, v in pairs(ultra.light or {}) do pcall(function() Lighting[p] = v end) end
	if ultra.quality ~= nil then pcall(function() settings().Rendering.QualityLevel = ultra.quality end) end
	ultra.fx, ultra.light, ultra.quality = nil, nil, nil
end

local potatoCtl, ultraCtl
potatoCtl = addToggle(pGfx, "Potato Mode", false, function(v)
	if v then
		if ultra.on then
			ultraOff()
			ultraCtl.set(false, true)
		end
		potatoOn()
	else
		potatoOff()
	end
end)
ultraCtl = addToggle(pGfx, "DLSS 5 Mode", false, function(v)
	if v then
		if potato.on then
			potatoOff()
			potatoCtl.set(false, true)
		end
		ultraOn()
	else
		ultraOff()
	end
end)
addNote(pGfx, "Potato: cuts shadows, effects and textures to raise FPS on weak devices.")
addNote(pGfx, "DLSS 5: max quality and cinematic effects for powerful devices. This is a visual preset, not real DLSS.")

----------------------------------------------------------------
-- Settings
----------------------------------------------------------------
addChoice(pSet, "Language", { { value = "en", label = "English" }, { value = "ru", label = "Русский" } }, lang, function(v) setLang(v) end)

local hueSlider
addSwatches(pSet, "Accent color", { 0.968, 0.07, 0.38, 0.5, 0.6, 0.76, 0.88 }, function(h)
	setHue(h)
	hueSlider.set(h * 360)
end)
hueSlider = addSlider(pSet, "Hue", 0, 360, cfg.hue * 360, function(v) setHue(v / 360) end)

addToggle(pSet, "Intro animation", cfg.intro, function(v)
	cfg.intro = v
	saveCfg()
end)
addSlider(pSet, "Window transparency", 0, 60, 0, function(v) main.BackgroundTransparency = v / 100 end)
addButton(pSet, "⏻ Deactivate", function() cleanup() end, true)
addNote(pSet, "Deactivate turns everything off instantly. To use the hub again, run the loadstring in Delta again.")

-- Adaptive control profiles: touch-first, desktop, or gamepad layout sizing.
local deviceLabel = addNote(pSet, "Управление: Телефон (по умолчанию).")
local function setDeviceProfile(profile)
    local cam = workspace.CurrentCamera
    local viewport = cam and cam.ViewportSize or Vector2.new(800, 600)
    if profile == "Телефон" then
        local w = math.max(300, math.min(380, viewport.X - 24))
        local h = math.max(360, math.min(520, viewport.Y - 60))
        main.Size = UDim2.fromOffset(w, h)
        main.Position = UDim2.new(0.5, -w/2, 0.5, -h/2)
        deviceLabel.Text = "Управление: Телефон · крупные элементы и сенсорный ввод."
    elseif profile == "ПК" then
        main.Size = UDim2.fromOffset(640, 390)
        main.Position = UDim2.new(0.5, -320, 0.5, -195)
        deviceLabel.Text = "Управление: ПК · компактная широкая панель, мышь и клавиатура."
    else
        main.Size = UDim2.fromOffset(560, 370)
        main.Position = UDim2.new(0.5, -280, 0.5, -185)
        deviceLabel.Text = "Управление: Геймпад · увеличенные элементы и навигация интерфейса."
    end
end
addButton(pSet, "Управление: Телефон", function() setDeviceProfile("Телефон") end)
addButton(pSet, "Управление: ПК", function() setDeviceProfile("ПК") end)
addButton(pSet, "Управление: Геймпад", function() setDeviceProfile("Геймпад") end)

----------------------------------------------------------------
-- Intro: samurai runs, letters drop out behind him, game is blurred
----------------------------------------------------------------
local function buildSamurai(parentGui, k, accent)
	local DARK = Color3.fromRGB(12, 10, 14)
	local root = new("Frame", {
		Size = UDim2.fromOffset(70 * k, 76 * k), AnchorPoint = Vector2.new(0.5, 1), BackgroundTransparency = 1,
	}, parentGui)

	-- zero-size frame = pivot point; rotating it rotates everything attached to it
	local function joint(par, x, y)
		return new("Frame", { Position = UDim2.fromOffset(x * k, y * k), Size = UDim2.fromOffset(0, 0), BackgroundTransparency = 1 }, par)
	end
	local function part(par, x, y, w, h, r, color)
		local f = new("Frame", {
			Position = UDim2.fromOffset(x * k, y * k), Size = UDim2.fromOffset(w * k, h * k),
			BackgroundColor3 = color or DARK, BorderSizePixel = 0,
		}, par)
		if r then new("UICorner", { CornerRadius = UDim.new(0, r * k) }, f) end
		if not color then
			new("UIStroke", { Color = accent, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, f)
		end
		return f
	end
	local function makeLeg()
		local thigh = joint(root, 35, 46)
		part(thigh, -3.5, 0, 7, 15, 3)
		local shin = joint(thigh, 0, 15)
		part(shin, -3, 0, 6, 15, 3)
		part(shin, -3, 13, 11, 4, 2)
		return { thigh = thigh, shin = shin }
	end
	local function makeArm()
		local up = joint(root, 36, 24)
		part(up, -2.5, 0, 5, 11, 2.5)
		local fore = joint(up, 0, 11)
		part(fore, -2.2, 0, 4.4, 11, 2.2)
		return { up = up, fore = fore }
	end

	-- back to front
	local scarf1 = joint(root, 31, 22)
	part(scarf1, -2, 0, 4, 13, 1.5, accent)
	local scarf2 = joint(scarf1, 0, 13)
	part(scarf2, -2, 0, 4, 13, 1.5, accent)

	local legB = makeLeg()
	local armB = makeArm()

	local torso = part(root, 27, 20, 16, 28, 5)
	part(torso, 0, 19, 16, 3, 1, accent) -- belt
	local sword = part(torso, -12, 21, 36, 2.4, 1) -- katana
	sword.Rotation = -14
	part(torso, 18, 20, 7, 3.6, 1, accent) -- hilt

	local legF = makeLeg()
	part(root, 28.5, 7, 13, 13, 6.5) -- head
	part(root, 19, 2, 32, 9, 4.5) -- kasa
	part(root, 30, -2, 10, 6, 3)
	local armF = makeArm()

	local function update(phi)
		local function leg(l, p)
			local th = phi + p
			l.thigh.Rotation = -42 * math.sin(th)
			l.shin.Rotation = 12 + 48 * math.max(0, math.cos(th))
		end
		leg(legF, 0)
		leg(legB, math.pi)
		armF.up.Rotation = 48 * math.sin(phi)
		armF.fore.Rotation = -(35 + 25 * math.sin(phi))
		armB.up.Rotation = 48 * math.sin(phi + math.pi)
		armB.fore.Rotation = -(35 + 25 * math.sin(phi + math.pi))
		torso.Rotation = 13 + 3 * math.sin(phi * 2)
		scarf1.Rotation = 78 + 10 * math.sin(phi * 2)
		scarf2.Rotation = 14 * math.sin(phi * 2 + 1)
	end
	update(0)
	return root, update
end

local function runIntro()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(800, 400)
	local skipped = false

	local ig = new("ScreenGui", {
		Name = "DS_Intro", ResetOnSpawn = false, DisplayOrder = 1000, IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, parent)
	introGui = ig

	local blur = new("BlurEffect", { Name = "DS_IntroBlur", Size = 0 }, Lighting)
	introBlur = blur
	TweenService:Create(blur, TweenInfo.new(0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = 28 }):Play()

	local overlay = new("TextButton", {
		Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = theme.g1, BackgroundTransparency = 1,
		BorderSizePixel = 0, Text = "", AutoButtonColor = false,
	}, ig)
	overlay.MouseButton1Click:Connect(function() skipped = true end)
	TweenService:Create(overlay, TweenInfo.new(0.5), { BackgroundTransparency = 0.25 }):Play()

	local moonSize = vp.Y * 0.95
	local introMoon = new("Frame", {
		Size = UDim2.fromOffset(moonSize, moonSize), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = theme.moon, BackgroundTransparency = 1, BorderSizePixel = 0,
	}, ig)
	new("UICorner", { CornerRadius = UDim.new(1, 0) }, introMoon)
	TweenService:Create(introMoon, TweenInfo.new(0.9, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { BackgroundTransparency = 0.88 }):Play()

	local word = "DARKNES SOFT"
	local size = math.clamp(math.floor(vp.X / 15), 26, 60)
	local adv = size * 0.74
	local x0 = (vp.X - adv * #word) / 2
	local ground = vp.Y * 0.62
	local k = (size * 1.9) / 76

	local line = new("Frame", {
		Size = UDim2.new(1, 0, 0, 2), Position = UDim2.fromOffset(0, ground), BackgroundColor3 = theme.accent,
		BackgroundTransparency = 1, BorderSizePixel = 0,
	}, ig)
	TweenService:Create(line, TweenInfo.new(0.6), { BackgroundTransparency = 0.5 }):Play()

	local letters = {}
	for i = 1, #word do
		local ch = word:sub(i, i)
		if ch ~= " " then
			letters[i] = new("TextLabel", {
				Size = UDim2.fromOffset(adv, size * 1.3), AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.fromOffset(x0 + (i - 1) * adv, ground - vp.Y * 0.5),
				BackgroundTransparency = 1, Text = ch, Font = Enum.Font.GothamBlack, TextSize = size,
				TextColor3 = (i <= 7) and theme.accent or Color3.new(1, 1, 1), TextTransparency = 1,
				TextStrokeColor3 = Color3.new(0, 0, 0), TextStrokeTransparency = 1,
			}, ig)
		end
	end

	local sub = new("TextLabel", {
		Size = UDim2.fromOffset(vp.X, size * 0.7), Position = UDim2.fromOffset(0, ground + size * 0.35),
		BackgroundTransparency = 1, Text = HUB_BY, Font = Enum.Font.GothamMedium, TextSize = math.floor(size * 0.45),
		TextColor3 = C.text, TextTransparency = 1,
	}, ig)

	local root, update = buildSamurai(ig, k, theme.accent)

	local function drop(i)
		local l = letters[i]
		if not l then return end
		TweenService:Create(l, TweenInfo.new(0.6, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
			Position = UDim2.fromOffset(x0 + (i - 1) * adv, ground),
		}):Play()
		TweenService:Create(l, TweenInfo.new(0.2), { TextTransparency = 0, TextStrokeTransparency = 0.5 }):Play()
	end

	-- run across the screen
	local DURATION = 2.6
	local startX, endX = -50 * k, vp.X + 50 * k
	local t0 = os.clock()
	local nextLetter = 1
	while not skipped and not dead do
		local el = os.clock() - t0
		if el >= DURATION then break end
		local x = startX + (endX - startX) * (el / DURATION)
		local phi = el * 14
		root.Position = UDim2.fromOffset(x, ground + 6 - math.abs(math.sin(phi)) * 3 * k)
		update(phi)
		while nextLetter <= #word and x - 20 * k > x0 + (nextLetter - 1) * adv + adv * 0.5 do
			drop(nextLetter)
			nextLetter = nextLetter + 1
		end
		RunService.Heartbeat:Wait()
	end

	if not skipped and not dead then
		root.Visible = false
		while nextLetter <= #word do
			drop(nextLetter)
			nextLetter = nextLetter + 1
		end
		TweenService:Create(sub, TweenInfo.new(0.5), { TextTransparency = 0 }):Play()
		local t1 = os.clock()
		while os.clock() - t1 < 1.3 and not skipped and not dead do
			RunService.Heartbeat:Wait()
		end
	end

	-- fade out everything, remove blur
	if not dead then
		local ti = TweenInfo.new(0.5)
		TweenService:Create(overlay, ti, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(introMoon, ti, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(line, ti, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(sub, ti, { TextTransparency = 1 }):Play()
		TweenService:Create(blur, ti, { Size = 0 }):Play()
		for _, l in pairs(letters) do
			TweenService:Create(l, ti, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
		root.Visible = false
		task.wait(0.55)
	end
end

----------------------------------------------------------------
-- Deactivate: instant shutdown
----------------------------------------------------------------
cleanup = function()
	if dead then return end
	dead = true
	for model in pairs(npcMarks) do pcall(function() clearNpcMark(model) end) end
	pcall(function() gui:Destroy() end)
	if introGui then pcall(function() introGui:Destroy() end) end
	if introBlur then pcall(function() introBlur:Destroy() end) end
	for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	pcall(function()
		sound:Stop()
		sound:Destroy()
	end)
	task.spawn(function()
		pcall(resetSky)
		pcall(ultraOff)
		pcall(potatoOff)
	end)
end

----------------------------------------------------------------
-- Start
----------------------------------------------------------------
selectTab("Info")

if cfg.intro then
	task.spawn(function()
		pcall(runIntro)
		if introGui then pcall(function() introGui:Destroy() end) introGui = nil end
		if introBlur then pcall(function() introBlur:Destroy() end) introBlur = nil end
		if not dead then main.Visible = true; task.wait(0.2); showAlphaWarning() end
	end)
else
	main.Visible = true
	task.defer(showAlphaWarning)
end
