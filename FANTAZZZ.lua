-- FANTAZZZ: Dice, Color Dice, and Light or Dark Wheel
-- Put this LocalScript in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- ACCESS CONTROL ---------------------------------------------------
-- Only these players get the GUI. Use UserIds (the number in a Roblox
-- profile link, roblox.com/users/NUMBER/profile), not usernames, because
-- usernames can change.
local ALLOWED_USER_IDS = {
	[1234567890] = true, -- <-- replace with the allowed person's UserId
	-- [9876543210] = true, -- add more people like this
}

if not ALLOWED_USER_IDS[player.UserId] then
	return -- everyone else: script stops here, no GUI is created
end

local COLORS = {
	{ "Red", Color3.fromRGB(235, 52, 36), "#EB3424" },
	{ "Orange", Color3.fromRGB(245, 160, 40), "#F5A028" },
	{ "Yellow", Color3.fromRGB(248, 215, 75), "#F8D74B" },
	{ "Green", Color3.fromRGB(55, 128, 32), "#378020" },
	{ "Blue", Color3.fromRGB(0, 0, 235), "#0000EB" },
	{ "Purple", Color3.fromRGB(120, 20, 120), "#781478" },
}
local LIGHT = Color3.fromRGB(245, 245, 245)
local DARK = Color3.fromRGB(35, 35, 40)

local mode = "Dice" -- "Dice", "Color", "Wheel"
local count = 1
local rolling = false

local function make(class, props, parent)
	local obj = Instance.new(class)
	for k, v in pairs(props) do
		obj[k] = v
	end
	obj.Parent = parent
	return obj
end

local function corner(parent, radius)
	make("UICorner", { CornerRadius = UDim.new(0, radius or 10) }, parent)
end

-- UI ---------------------------------------------------------------

local gui = make("ScreenGui", { Name = "Fantazzz", ResetOnSpawn = false }, player:WaitForChild("PlayerGui"))

local main = make("Frame", {
	Size = UDim2.new(0, 340, 0, 590),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Color3.fromRGB(190, 55, 40),
}, gui)
corner(main, 16)
make("UIStroke", { Color = Color3.fromRGB(255, 150, 60), Thickness = 4 }, main)

local title = make("TextLabel", {
	Size = UDim2.new(1, 0, 0, 28),
	BackgroundTransparency = 1,
	Text = "🦀 FANTAZZZ 🦀",
	TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBold,
	TextSize = 20,
}, main)

-- Discord link under the name (select the text to copy it)
local discordLink = make("TextBox", {
	Size = UDim2.new(0, 190, 0, 16),
	Position = UDim2.new(0.5, 0, 0, 28),
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundTransparency = 1,
	Text = "https://discord.gg/jX7UzBK93T",
	TextColor3 = Color3.fromRGB(255, 225, 190),
	Font = Enum.Font.GothamMedium,
	TextSize = 11,
	TextEditable = false,
	ClearTextOnFocus = false,
}, main)

-- Dragging helper (works with mouse and touch). Returns a function that
-- tells you whether the last press turned into a drag.
local function makeDraggable(handle, target)
	local dragging, dragStart, startPos = false, nil, nil
	local moved = false
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging, moved = true, false
			dragStart, startPos = input.Position, target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - dragStart
			if d.Magnitude > 6 then
				moved = true
			end
			target.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y
			)
		end
	end)
	return function()
		return moved
	end
end

makeDraggable(title, main)

-- Crab button: shows when the window is minimized
local crab = make("TextButton", {
	Size = UDim2.new(0, 64, 0, 64),
	Position = main.Position,
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Color3.fromRGB(190, 55, 40),
	Text = "🦀",
	TextSize = 36,
	Visible = false,
	AutoButtonColor = true,
}, gui)
corner(crab, 32)
make("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 3 }, crab)
local crabWasDragged = makeDraggable(crab, crab)

local minimizeButton = make("TextButton", {
	Size = UDim2.new(0, 30, 0, 30),
	Position = UDim2.new(1, -72, 0, 6),
	BackgroundColor3 = Color3.fromRGB(60, 60, 78),
	Text = "–",
	TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBold,
	TextSize = 20,
	ZIndex = 5,
}, main)
corner(minimizeButton, 8)

-- Size controls: scale the whole window down/up
local uiScale = make("UIScale", { Scale = 0.5 }, main)
local MIN_SCALE, MAX_SCALE, STEP = 0.3, 1.3, 0.1

local function sizeButton(text, x)
	local b = make("TextButton", {
		Size = UDim2.new(0, 30, 0, 30),
		Position = UDim2.new(0, x, 0, 6),
		BackgroundColor3 = Color3.fromRGB(60, 60, 78),
		Text = text,
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		ZIndex = 5,
	}, main)
	corner(b, 8)
	return b
end

local smallerButton = sizeButton("-", 8)
local biggerButton = sizeButton("+", 42)

smallerButton.Activated:Connect(function()
	uiScale.Scale = math.max(MIN_SCALE, math.round((uiScale.Scale - STEP) * 10) / 10)
end)
biggerButton.Activated:Connect(function()
	uiScale.Scale = math.min(MAX_SCALE, math.round((uiScale.Scale + STEP) * 10) / 10)
end)

local closeButton = make("TextButton", {
	Size = UDim2.new(0, 30, 0, 30),
	Position = UDim2.new(1, -38, 0, 6),
	BackgroundColor3 = Color3.fromRGB(120, 25, 25),
	Text = "X",
	TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	ZIndex = 5,
}, main)
corner(closeButton, 8)
closeButton.Activated:Connect(function()
	gui:Destroy() -- closes the GUI completely
end)

minimizeButton.Activated:Connect(function()
	crab.Position = main.Position
	main.Visible = false
	crab.Visible = true
end)

crab.Activated:Connect(function()
	if crabWasDragged() then
		return
	end
	main.Position = crab.Position
	crab.Visible = false
	main.Visible = true
end)

local function button(text, x, y, w, h, parent)
	local b = make("TextButton", {
		Size = UDim2.new(0, w, 0, h),
		Position = UDim2.new(0, x, 0, y),
		BackgroundColor3 = Color3.fromRGB(60, 60, 78),
		Text = text,
		TextColor3 = Color3.new(1, 1, 1),
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		AutoButtonColor = true,
	}, parent)
	corner(b, 8)
	return b
end

-- Mode buttons
local modeButtons = {
	Dice = button("Dice", 10, 45, 100, 34, main),
	Color = button("Color Dice", 120, 45, 100, 34, main),
	Wheel = button("Light/Dark", 230, 45, 100, 34, main),
}

-- Dice count buttons
local countRow = make("Frame", {
	Size = UDim2.new(1, 0, 0, 34),
	Position = UDim2.new(0, 0, 0, 88),
	BackgroundTransparency = 1,
}, main)
local dropdownButton = button("1 Dice ▾", 10, 0, 320, 34, countRow)

local dropdownList = make("Frame", {
	Size = UDim2.new(0, 320, 0, 6 * 34),
	Position = UDim2.new(0, 10, 0, 122),
	BackgroundColor3 = Color3.fromRGB(50, 50, 66),
	Visible = false,
	ZIndex = 10,
}, main)
corner(dropdownList, 10)

local countButtons = {}
for i = 1, 6 do
	local b = button("", 0, (i - 1) * 34, 320, 34, dropdownList)
	b.ZIndex = 11
	b.BackgroundTransparency = 1
	b.TextXAlignment = Enum.TextXAlignment.Left
	make("UIPadding", { PaddingLeft = UDim.new(0, 14) }, b)
	countButtons[i] = b
end

-- Play area
local area = make("Frame", {
	Size = UDim2.new(1, -20, 0, 240),
	Position = UDim2.new(0, 10, 0, 130),
	BackgroundColor3 = Color3.fromRGB(40, 40, 54),
}, main)
corner(area, 12)

local diceHolder = make("Frame", {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
}, area)
make("UIGridLayout", {
	CellSize = UDim2.new(0, 70, 0, 70),
	CellPadding = UDim2.new(0, 10, 0, 10),
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
}, diceHolder)

-- Wheel: many thin rotated bars form 8 alternating wedges
local wheelHolder = make("Frame", {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Visible = false,
}, area)

local WHEEL_SIZE = 200
local wheel = make("Frame", {
	Size = UDim2.new(0, WHEEL_SIZE, 0, WHEEL_SIZE),
	Position = UDim2.new(0.5, 0, 0.5, 8),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1,
}, wheelHolder)

local BARS = 60
for i = 0, BARS - 1 do
	local centerAngle = i * (360 / BARS) + (360 / BARS) / 2
	local segment = math.floor(centerAngle / 45) -- 0..7
	make("Frame", {
		Size = UDim2.new(0, WHEEL_SIZE / 2, 0, 14),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Rotation = i * (360 / BARS),
		BackgroundColor3 = (segment % 2 == 0) and LIGHT or DARK,
		BorderSizePixel = 0,
	}, wheel)
end

make("TextLabel", {
	Size = UDim2.new(0, 30, 0, 30),
	Position = UDim2.new(0.5, 0, 0.5, -WHEEL_SIZE / 2 - 4),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1,
	Text = "▼",
	TextColor3 = Color3.fromRGB(255, 80, 80),
	Font = Enum.Font.GothamBold,
	TextSize = 28,
	ZIndex = 5,
}, wheelHolder)

local resultLabel = make("TextLabel", {
	Size = UDim2.new(1, -20, 0, 44),
	Position = UDim2.new(0, 10, 0, 372),
	BackgroundTransparency = 1,
	Text = "Press ROLL!",
	TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBold,
	TextSize = 15,
	TextWrapped = true,
}, main)

local rollButton = button("ROLL!", 10, 420, 320, 40, main)
rollButton.BackgroundColor3 = Color3.fromRGB(100, 165, 250)
rollButton.TextSize = 20
make("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 3 }, rollButton)

local legend = make("TextLabel", {
	Size = UDim2.new(1, -20, 0, 56),
	Position = UDim2.new(0, 10, 0, 520),
	BackgroundColor3 = Color3.fromRGB(45, 50, 65),
	Text = "",
	RichText = true,
	TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.Gotham,
	TextSize = 14,
	TextWrapped = true,
}, main)
corner(legend, 10)
do
	local parts = {}
	for _, c in ipairs(COLORS) do
		table.insert(parts, '<font color="' .. c[3] .. '">' .. c[1] .. "</font>")
	end
	legend.Text = "Possible colors are: " .. table.concat(parts, ", ", 1, 5) .. ", and " .. parts[6] .. "."
end

-- Prediction ----------------------------------------------------------
-- Pick a guess BEFORE rolling; the result tells you if you were right.

local guessColor = nil -- index into COLORS
local guessWheel = nil -- "Light" or "Dark"
local guessTotal = nil -- number (Dice mode)
local wins, rounds = 0, 0

local predictRow = make("Frame", {
	Size = UDim2.new(1, 0, 0, 40),
	Position = UDim2.new(0, 0, 0, 470),
	BackgroundTransparency = 1,
}, main)

local function predictPanel()
	return make("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Visible = false,
	}, predictRow)
end
local predDice, predColor, predWheel = predictPanel(), predictPanel(), predictPanel()

-- Dice: guess the total
make("TextLabel", {
	Size = UDim2.new(0, 110, 0, 36),
	Position = UDim2.new(0, 10, 0, 2),
	BackgroundTransparency = 1,
	Text = "Predict total:",
	TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBold,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
}, predDice)
local totalMinus = button("-", 130, 2, 40, 36, predDice)
local totalValue = make("TextLabel", {
	Size = UDim2.new(0, 70, 0, 36),
	Position = UDim2.new(0, 175, 0, 2),
	BackgroundTransparency = 1,
	Text = "?",
	TextColor3 = Color3.new(1, 1, 1),
	Font = Enum.Font.GothamBold,
	TextSize = 22,
}, predDice)
local totalPlus = button("+", 250, 2, 40, 36, predDice)

-- Color: guess a color (win if at least one die shows it)
local colorChips = {}
for i, c in ipairs(COLORS) do
	local chip = button("", 10 + (i - 1) * 53, 2, 47, 36, predColor)
	chip.BackgroundColor3 = c[2]
	chip.TextSize = 20
	chip.TextColor3 = Color3.new(1, 1, 1)
	colorChips[i] = chip
end

-- Wheel: guess Light or Dark
local lightGuess = button("☀️ Light", 10, 2, 155, 36, predWheel)
local darkGuess = button("🌙 Dark", 175, 2, 155, 36, predWheel)

local SELECTED = Color3.fromRGB(90, 110, 220)
local NORMAL = Color3.fromRGB(60, 60, 78)

local function updatePredictUI()
	if guessTotal and (guessTotal < count or guessTotal > 6 * count) then
		guessTotal = nil
	end
	predDice.Visible = (mode == "Dice")
	predColor.Visible = (mode == "Color")
	predWheel.Visible = (mode == "Wheel")
	totalValue.Text = guessTotal and tostring(guessTotal) or "?"
	for i, chip in ipairs(colorChips) do
		chip.Text = (i == guessColor) and "✓" or ""
	end
	lightGuess.BackgroundColor3 = (guessWheel == "Light") and SELECTED or NORMAL
	darkGuess.BackgroundColor3 = (guessWheel == "Dark") and SELECTED or NORMAL
end

local function adjustTotal(delta)
	if rolling then
		return
	end
	local start = guessTotal or math.floor(3.5 * count + 0.5)
	if guessTotal then
		start += delta
	end
	guessTotal = math.clamp(start, count, 6 * count)
	updatePredictUI()
end
totalMinus.Activated:Connect(function() adjustTotal(-1) end)
totalPlus.Activated:Connect(function() adjustTotal(1) end)

for i, chip in ipairs(colorChips) do
	chip.Activated:Connect(function()
		if rolling then
			return
		end
		guessColor = (guessColor == i) and nil or i
		updatePredictUI()
	end)
end

lightGuess.Activated:Connect(function()
	if not rolling then
		guessWheel = (guessWheel == "Light") and nil or "Light"
		updatePredictUI()
	end
end)
darkGuess.Activated:Connect(function()
	if not rolling then
		guessWheel = (guessWheel == "Dark") and nil or "Dark"
		updatePredictUI()
	end
end)

-- Eye button: hide / show the prediction row (your pick stays active while hidden)
local hidePredict = false
local eyeButton = button("👁", 0, 0, 28, 28, area)
eyeButton.Position = UDim2.new(1, -34, 0, 6)
eyeButton.ZIndex = 6
eyeButton.TextSize = 16
eyeButton.Activated:Connect(function()
	hidePredict = not hidePredict
	predictRow.Visible = not hidePredict
	eyeButton.BackgroundColor3 = hidePredict and Color3.fromRGB(120, 25, 25) or Color3.fromRGB(60, 60, 78)
end)

-- Picked color stays locked on every roll until you tap it again (clear) or choose another
local lockPick = true -- picking a color now locks it automatically
local lockButton = button("🎯 Lock: OFF", 225, 0, 105, 34, countRow)
lockButton.TextSize = 12

local function updateLockButton()
	lockButton.Text = lockPick and "🎯 Lock: ON" or "🎯 Lock: OFF"
	lockButton.BackgroundColor3 = lockPick and Color3.fromRGB(90, 110, 220) or Color3.fromRGB(60, 60, 78)
end
lockButton.Activated:Connect(function()
	if rolling then
		return
	end
	lockPick = not lockPick
	updateLockButton()
end)

-- Builds the right/wrong line. correct == nil means no prediction was made.
local function verdict(correct, extra)
	if correct == nil then
		return "(Make a prediction to score points)"
	end
	rounds += 1
	if correct then
		wins += 1
	end
	return (correct and "✅ Correct!" or "❌ Wrong") .. (extra or "") .. string.format("  Score: %d/%d", wins, rounds)
end

-- Display helpers ----------------------------------------------------

local diceLabels = {}

local function rebuildDice()
	for _, l in ipairs(diceLabels) do
		l:Destroy()
	end
	diceLabels = {}
	if mode == "Wheel" then
		return
	end
	for i = 1, count do
		local d = make("TextLabel", {
			LayoutOrder = i,
			BackgroundColor3 = Color3.new(1, 1, 1),
			Text = "?",
			TextColor3 = Color3.fromRGB(30, 30, 30),
			Font = Enum.Font.GothamBold,
			TextSize = 36,
		}, diceHolder)
		corner(d, 14)
		make("UIStroke", { Color = Color3.fromRGB(200, 225, 255), Thickness = 2 }, d)
		local inner = make("Frame", {
			Name = "Inner",
			Size = UDim2.new(1, -14, 1, -14),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = COLORS[1][2],
			Visible = false,
		}, d)
		corner(inner, 10)
		local dot = make("Frame", {
			Size = UDim2.new(0, 12, 0, 12),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.new(1, 1, 1),
		}, inner)
		corner(dot, 6)
		diceLabels[i] = d
	end
end

local function refresh()
	local isWheel = mode == "Wheel"
	diceHolder.Visible = not isWheel
	wheelHolder.Visible = isWheel
	countRow.Visible = not isWheel
	for name, b in pairs(modeButtons) do
		b.BackgroundColor3 = (name == mode) and Color3.fromRGB(90, 110, 220) or Color3.fromRGB(60, 60, 78)
	end
	for i, b in ipairs(countButtons) do
		b.Text = ((i == count) and "✓  " or "      ") .. i .. " Dice"
	end
	dropdownButton.Text = count .. " Dice ▾"
	dropdownList.Visible = false
	legend.Visible = (mode == "Color")
	updatePredictUI()
	updateLockButton()
	lockButton.Visible = false -- no separate toggle needed anymore
	rollButton.Text = "ROLL!"
	resultLabel.Text = "Press ROLL!"
	rebuildDice()
end

local function showRandom(label)
	if mode == "Dice" then
		label.Text = tostring(math.random(1, 6))
		label.Inner.Visible = false
	else
		local c = COLORS[math.random(1, #COLORS)]
		label.Text = ""
		label.Inner.Visible = true
		label.Inner.BackgroundColor3 = c[2]
		label:SetAttribute("ColorName", c[1])
	end
end

-- Rolling --------------------------------------------------------------

local function rollDice()
	for _ = 1, 12 do
		for _, l in ipairs(diceLabels) do
			showRandom(l)
		end
		task.wait(0.08)
	end
	if mode == "Color" and lockPick and guessColor then
		-- Random 1..N dice land on your picked color (e.g. 1, 2, 3 or 4 greens)
		local n = #diceLabels
		local matches = math.random(1, n)
		local order = {}
		for i = 1, n do
			order[i] = i
		end
		for i = n, 2, -1 do
			local j = math.random(1, i)
			order[i], order[j] = order[j], order[i]
		end
		local isMatch = {}
		for j = 1, matches do
			isMatch[order[j]] = true
		end
		for i, l in ipairs(diceLabels) do
			local idx = guessColor
			if not isMatch[i] then
				repeat
					idx = math.random(1, #COLORS)
				until idx ~= guessColor
			end
			local c = COLORS[idx]
			l.Inner.Visible = true
			l.Inner.BackgroundColor3 = c[2]
			l:SetAttribute("ColorName", c[1])
		end
	end
	if mode == "Dice" then
		local total = 0
		for _, l in ipairs(diceLabels) do
			total += tonumber(l.Text) or 0
		end
		local correct = nil
		if guessTotal then
			correct = (total == guessTotal)
		end
		local outcome = (count > 1) and ("Total: " .. total) or ("You rolled a " .. total)
		resultLabel.Text = outcome .. "\n" .. verdict(correct)
	else
		local names = {}
		for _, l in ipairs(diceLabels) do
			table.insert(names, l:GetAttribute("ColorName") or "?")
		end
		local correct, hits = nil, 0
		if guessColor then
			for _, n in ipairs(names) do
				if n == COLORS[guessColor][1] then
					hits += 1
				end
			end
			correct = hits > 0
		end
		resultLabel.Text = table.concat(names, ", ") .. "\n"
			.. verdict(correct, guessColor and (" " .. hits .. " hit") or nil)
	end
end

local function spinWheel()
	-- Pointer is at the top (screen angle 270). Pick a wedge, then land on it.
	local seg = math.random(0, 7)
	local localAngle = seg * 45 + math.random(6, 39)
	local landing = (270 - localAngle) % 360
	local current = wheel.Rotation
	local target = math.ceil(current / 360) * 360 + 360 * 5 + landing

	local tween = TweenService:Create(
		wheel,
		TweenInfo.new(4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Rotation = target }
	)
	tween:Play()
	tween.Completed:Wait()
	local result = (seg % 2 == 0) and "Light" or "Dark"
	local correct = nil
	if guessWheel then
		correct = (guessWheel == result)
	end
	resultLabel.Text = ((result == "Light") and "LIGHT ☀️" or "DARK 🌙") .. "\n" .. verdict(correct)
end

rollButton.Activated:Connect(function()
	if rolling then
		return
	end
	rolling = true
	resultLabel.Text = "Rolling..."
	if mode == "Wheel" then
		spinWheel()
	else
		rollDice()
	end
	rollButton.Text = "ROLL AGAIN !"
	rolling = false
end)

for name, b in pairs(modeButtons) do
	b.Activated:Connect(function()
		if rolling then
			return
		end
		mode = name
		refresh()
	end)
end

dropdownButton.Activated:Connect(function()
	if not rolling then
		dropdownList.Visible = not dropdownList.Visible
	end
end)

for i, b in ipairs(countButtons) do
	b.Activated:Connect(function()
		if rolling then
			return
		end
		count = i
		refresh()
	end)
end

refresh()
