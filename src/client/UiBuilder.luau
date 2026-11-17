--!nonstrict
-- UiBuilder: every menu of Pasar Malam Brainrot, built in code.
-- Main menu, how to play, shop, base, index, upgrades, rebirth,
-- fusion, event, leaderboard, settings, daily reward, quests and
-- the wheel. The HUD stays clear of the top-left corner, where
-- Roblox puts its own menu buttons.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local UiBuilder = {}

local gui = nil
local panels = {}
local hudMoney = nil
local hudIncome = nil
local hudRebirth = nil
local eventBanner = nil
local toastLabel = nil
local toastUntil = 0
local actionFn = nil
local state = nil
local volumeLevel = 1 -- 0, 1, 2 cycle: mute, half, full
local shadowsOn = true

local GOLD = Color3.fromRGB(255, 200, 60)
local PANEL_BG = Color3.fromRGB(45, 32, 66)
local PANEL_EDGE = Color3.fromRGB(255, 170, 60)
local CREAM = Color3.fromRGB(255, 244, 214)
local GREEN = Color3.fromRGB(140, 255, 140)

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness or 2
	s.Parent = parent
	return s
end

local function makeButton(parent, text, size, pos, color)
	local button = Instance.new("TextButton")
	button.Size = size
	button.Position = pos
	button.BackgroundColor3 = color or Color3.fromRGB(180, 60, 60)
	button.Text = text
	button.Font = Enum.Font.GothamBold
	button.TextSize = 16
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.AutoButtonColor = true
	button.Parent = parent
	corner(button, 8)
	return button
end

local function makeLabel(parent, text, size, pos, textSize, color, font)
	local label = Instance.new("TextLabel")
	label.Size = size
	label.Position = pos
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = font or Enum.Font.GothamBold
	label.TextSize = textSize or 16
	label.TextColor3 = color or CREAM
	label.TextWrapped = true
	label.Parent = parent
	return label
end

local function makePanel(name, title)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = UDim2.new(0, 560, 0, 420)
	frame.Position = UDim2.new(0.5, -280, 0.5, -210)
	frame.BackgroundColor3 = PANEL_BG
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = gui
	corner(frame, 14)
	stroke(frame, PANEL_EDGE, 2)

	makeLabel(frame, title, UDim2.new(1, -90, 0, 40), UDim2.new(0, 16, 0, 8), 22, GOLD, Enum.Font.FredokaOne)
	local close = makeButton(frame, "Tutup", UDim2.new(0, 70, 0, 32), UDim2.new(1, -82, 0, 10), Color3.fromRGB(120, 60, 60))
	close.TextSize = 14
	close.MouseButton1Click:Connect(function()
		frame.Visible = false
	end)

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -24, 1, -60)
	content.Position = UDim2.new(0, 12, 0, 50)
	content.BackgroundTransparency = 1
	content.Parent = frame

	panels[name] = { Frame = frame, Content = content }
	return panels[name]
end

local function openPanel(name)
	for _, panel in pairs(panels) do
		panel.Frame.Visible = false
	end
	local panel = panels[name]
	if panel then
		panel.Frame.Visible = true
		UiBuilder.RefreshPanel(name)
	end
end

local function clearContent(content)
	for _, child in ipairs(content:GetChildren()) do
		child:Destroy()
	end
end

local function row(parent, y, height)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 0, height)
	frame.Position = UDim2.new(0, 0, 0, y)
	frame.BackgroundColor3 = Color3.fromRGB(60, 45, 85)
	frame.BorderSizePixel = 0
	frame.Parent = parent
	corner(frame, 8)
	return frame
end

local function formatMoney(n)
	return "$" .. tostring(math.floor(n))
end

-- -- panel builders ---------------------------------------------------------

local function buildShop(content)
	local y = 0
	if not state or #state.Walkers == 0 then
		makeLabel(content, "Conveyor sedang kosong, tunggu brainrot berikutnya lewat...", UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, y), 16, CREAM)
		return
	end
	local walkers = {}
	for _, w in ipairs(state.Walkers) do
		table.insert(walkers, w)
	end
	table.sort(walkers, function(a, b)
		return a.Cost < b.Cost
	end)
	for _, walker in ipairs(walkers) do
		local char = BrainrotData.GetCharacter(walker.CharId)
		local tier = char and BrainrotData.GetTier(char.Tier)
		local r = row(content, y, 52)
		y += 58
		makeLabel(r, BrainrotData.LabelOf(walker.CharId, walker.Mutation), UDim2.new(0.55, 0, 1, 0), UDim2.new(0, 10, 0, 0), 15, CREAM)
		makeLabel(r, (tier and tier.Name or "") .. "  |  " .. formatMoney(walker.Rate) .. "/detik", UDim2.new(0.55, 0, 0, 18), UDim2.new(0, 10, 0, 28), 13, tier and tier.Color or CREAM)
		local buy = makeButton(r, "Beli " .. formatMoney(walker.Cost), UDim2.new(0, 120, 0, 36), UDim2.new(1, -130, 0, 8), Color3.fromRGB(60, 160, 80))
		buy.TextSize = 14
		local id = walker.Id
		buy.MouseButton1Click:Connect(function()
			actionFn("BuyWalker", { WalkerId = id })
		end)
	end
end

local function buildBase(content)
	local y = 0
	makeLabel(content, "Penghasilan total: " .. formatMoney(state.IncomePerSecond) .. "/detik   |   Slot terisi: " .. #state.Owned .. "/" .. state.MaxSlots, UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 0, y), 15, GREEN)
	y += 36
	local ownedBySlot = {}
	for _, w in ipairs(state.Owned) do
		ownedBySlot[w.Slot] = w
	end
	for slot = 1, state.MaxSlots do
		local r = row(content, y, 44)
		y += 50
		local w = ownedBySlot[slot]
		if w then
			makeLabel(r, "Slot " .. slot .. ": " .. BrainrotData.LabelOf(w.CharId, w.Mutation), UDim2.new(0.6, 0, 1, 0), UDim2.new(0, 10, 0, 0), 15, CREAM)
			makeLabel(r, formatMoney(w.Rate) .. "/detik", UDim2.new(0, 120, 0, 30), UDim2.new(1, -130, 0, 7), 14, GREEN)
		else
			makeLabel(r, "Slot " .. slot .. ": kosong", UDim2.new(0.6, 0, 1, 0), UDim2.new(0, 10, 0, 0), 15, Color3.fromRGB(170, 150, 190))
		end
	end
end

local function buildIndex(content)
	local ownedIds = {}
	for _, w in ipairs(state.Owned) do
		ownedIds[w.CharId] = true
	end
	local y = 0
	for _, char in ipairs(BrainrotData.Characters) do
		local tier = BrainrotData.GetTier(char.Tier)
		local r = row(content, y, 44)
		y += 50
		local owned = ownedIds[char.Id]
		makeLabel(r, char.Name .. (owned and "  ✓" or ""), UDim2.new(0.55, 0, 1, 0), UDim2.new(0, 10, 0, 0), 15, owned and CREAM or Color3.fromRGB(150, 130, 170))
		makeLabel(r, char.Tier .. "  |  " .. formatMoney(char.Rate) .. "/detik  |  " .. formatMoney(char.Cost), UDim2.new(0.45, -10, 0, 18), UDim2.new(0.55, 0, 0, 12), 13, tier.Color)
	end
end

local function buildUpgrades(content)
	local y = 0
	for _, up in ipairs(Config.Upgrades) do
		local level = state.Upgrades[up.Id] or 0
		local maxed = level >= up.MaxLevel
		local cost = maxed and 0 or Config.UpgradeCost(up, level)
		local r = row(content, y, 60)
		y += 66
		makeLabel(r, up.Name .. "  Lv " .. level .. "/" .. up.MaxLevel, UDim2.new(0.6, 0, 0, 24), UDim2.new(0, 10, 0, 4), 15, CREAM)
		makeLabel(r, up.Desc, UDim2.new(0.6, 0, 0, 20), UDim2.new(0, 10, 0, 28), 12, Color3.fromRGB(190, 170, 210))
		if maxed then
			makeLabel(r, "MAKSIMAL", UDim2.new(0, 110, 0, 30), UDim2.new(1, -120, 0, 15), 14, GOLD)
		else
			local buy = makeButton(r, "Beli " .. formatMoney(cost), UDim2.new(0, 110, 0, 36), UDim2.new(1, -120, 0, 12), Color3.fromRGB(60, 120, 200))
			buy.TextSize = 14
			local id = up.Id
			buy.MouseButton1Click:Connect(function()
				actionFn("BuyUpgrade", { UpgradeId = id })
			end)
		end
	end
	-- Guard pet lives here too: it guards the base.
	local r = row(content, y, 60)
	y += 66
	makeLabel(r, "Kucing Pasar (Penjaga Base)", UDim2.new(0.6, 0, 0, 24), UDim2.new(0, 10, 0, 4), 15, CREAM)
	makeLabel(r, "Kucing ini mengusir pencuri dari basemu secara otomatis.", UDim2.new(0.6, 0, 0, 20), UDim2.new(0, 10, 0, 28), 12, Color3.fromRGB(190, 170, 210))
	if state.Guard then
		makeLabel(r, "SUDAH PUNYA", UDim2.new(0, 110, 0, 30), UDim2.new(1, -120, 0, 15), 14, GOLD)
	else
		local buy = makeButton(r, "Beli " .. formatMoney(Config.Guard.Cost), UDim2.new(0, 110, 0, 36), UDim2.new(1, -120, 0, 12), Color3.fromRGB(200, 140, 40))
		buy.TextSize = 14
		buy.MouseButton1Click:Connect(function()
			actionFn("BuyGuard", {})
		end)
	end
end

local function buildRebirth(content)
	local y = 0
	makeLabel(content, "Rebirth mengulang progresmu dari nol, tapi penghasilanmu naik permanen.", UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, y), 15, CREAM)
	y += 50
	makeLabel(content, "Rebirth sekarang: " .. state.Rebirths .. "  |  Pengali: x" .. tostring(state.RebirthMultiplier), UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 0, y), 16, GOLD)
	y += 36
	makeLabel(content, "Syarat rebirth berikut: penghasilan total " .. formatMoney(state.RebirthRequirement), UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 0, y), 15, CREAM)
	y += 36
	makeLabel(content, "Penghasilan totalmu: " .. formatMoney(state.LifetimeEarned), UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 0, y), 15, GREEN)
	y += 44
	local ready = state.LifetimeEarned >= state.RebirthRequirement
	local button = makeButton(content, ready and "REBIRTH SEKARANG" or "BELUM CUKUP", UDim2.new(0, 240, 0, 44), UDim2.new(0.5, -120, 0, y), ready and Color3.fromRGB(200, 60, 160) or Color3.fromRGB(90, 80, 110))
	button.TextSize = 17
	button.MouseButton1Click:Connect(function()
		actionFn("Rebirth", {})
	end)
end

local function buildFusion(content)
	local y = 0
	makeLabel(content, "Gabungkan 3 brainrot yang sama menjadi 1 brainrot mutasi yang penghasilannya x1.5 lebih besar.", UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, y), 15, CREAM)
	y += 50
	local counts = {}
	for _, w in ipairs(state.Owned) do
		counts[w.CharId] = (counts[w.CharId] or 0) + 1
	end
	local any = false
	for _, char in ipairs(BrainrotData.Characters) do
		local count = counts[char.Id] or 0
		if count > 0 then
			any = true
			local r = row(content, y, 48)
			y += 54
			makeLabel(r, char.Name, UDim2.new(0.5, 0, 1, 0), UDim2.new(0, 10, 0, 0), 15, CREAM)
			makeLabel(r, "Punya: " .. count .. "/3", UDim2.new(0, 120, 0, 30), UDim2.new(0.5, 0, 0, 9), 14, count >= 3 and GREEN or CREAM)
			if count >= 3 then
				local fuse = makeButton(r, "Fusion!", UDim2.new(0, 100, 0, 34), UDim2.new(1, -110, 0, 7), Color3.fromRGB(200, 60, 160))
				fuse.TextSize = 14
				local id = char.Id
				fuse.MouseButton1Click:Connect(function()
					actionFn("Fuse", { CharId = id })
				end)
			end
		end
	end
	if not any then
		makeLabel(content, "Kamu belum punya brainrot. Beli dulu di conveyor!", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, y), 15, CREAM)
	end
end

local function buildEvent(content)
	local y = 0
	if state.CurrentEvent then
		makeLabel(content, "SEDANG BERJALAN: " .. state.CurrentEvent.Name, UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, y), 18, GOLD)
		y += 36
		makeLabel(content, state.CurrentEvent.Desc, UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, y), 15, CREAM)
		y += 50
		makeLabel(content, "Berakhir dalam " .. state.CurrentEvent.EndsIn .. " detik.", UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 0, y), 15, GREEN)
	else
		makeLabel(content, "Tidak ada event sekarang. Event muncul otomatis tiap beberapa menit.", UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, y), 15, CREAM)
		y += 50
	end
	y += 20
	makeLabel(content, "Event yang bisa muncul:", UDim2.new(1, 0, 0, 28), UDim2.new(0, 0, 0, y), 16, GOLD)
	y += 34
	for _, event in ipairs(Config.Events) do
		makeLabel(content, "• " .. event.Name .. " - " .. event.Desc, UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, y), 14, CREAM)
		y += 42
	end
end

local function buildLeaderboard(content)
	local y = 0
	for i, entry in ipairs(state.Leaderboard) do
		local r = row(content, y, 40)
		y += 46
		makeLabel(r, "#" .. i .. "  " .. entry.Name .. (entry.IsBot and " (BOT)" or ""), UDim2.new(0.6, 0, 1, 0), UDim2.new(0, 10, 0, 0), 15, i == 1 and GOLD or CREAM)
		makeLabel(r, formatMoney(entry.Money), UDim2.new(0, 140, 0, 30), UDim2.new(1, -150, 0, 5), 15, GREEN)
	end
end

local function buildDaily(content)
	local y = 0
	makeLabel(content, "Klaim sekali sehari. Hadiah bertambah kalau kamu sudah rebirth.", UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, y), 15, CREAM)
	y += 50
	if state.DailyAvailable then
		local claim = makeButton(content, "KLAIM HADIAH HARIAN", UDim2.new(0, 260, 0, 44), UDim2.new(0.5, -130, 0, y), Color3.fromRGB(60, 160, 80))
		claim.TextSize = 16
		claim.MouseButton1Click:Connect(function()
			actionFn("ClaimDaily", {})
		end)
	else
		makeLabel(content, "Sudah diklaim hari ini. Balik lagi besok!", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, y), 15, GREEN)
	end
	y += 60
	makeLabel(content, "Roda Keberuntungan: putaran gratis tiap 10 menit.", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, y), 15, CREAM)
	y += 36
	if state.WheelAvailableIn <= 0 then
		local spin = makeButton(content, "PUTAR RODA!", UDim2.new(0, 200, 0, 44), UDim2.new(0.5, -100, 0, y), Color3.fromRGB(200, 140, 40))
		spin.TextSize = 16
		spin.MouseButton1Click:Connect(function()
			actionFn("SpinWheel", {})
		end)
	else
		makeLabel(content, "Roda bisa diputar lagi dalam " .. state.WheelAvailableIn .. " detik.", UDim2.new(1, 0, 0, 30), UDim2.new(0, 0, 0, y), 15, CREAM)
	end
end

local function buildQuests(content)
	local y = 0
	for _, quest in ipairs(state.Quests) do
		local r = row(content, y, 64)
		y += 70
		makeLabel(r, quest.Name, UDim2.new(0.6, 0, 0, 24), UDim2.new(0, 10, 0, 4), 15, CREAM)
		makeLabel(r, quest.Desc .. "  (" .. math.min(quest.Progress, quest.Target) .. "/" .. quest.Target .. ")", UDim2.new(0.6, 0, 0, 20), UDim2.new(0, 10, 0, 28), 12, Color3.fromRGB(190, 170, 210))
		if quest.Claimed then
			makeLabel(r, "DIKLAIM", UDim2.new(0, 110, 0, 30), UDim2.new(1, -120, 0, 17), 14, GREEN)
		elseif quest.Progress >= quest.Target then
			local claim = makeButton(r, "Klaim " .. formatMoney(quest.Reward), UDim2.new(0, 110, 0, 36), UDim2.new(1, -120, 0, 14), Color3.fromRGB(60, 160, 80))
			claim.TextSize = 13
			local id = quest.Id
			claim.MouseButton1Click:Connect(function()
				actionFn("ClaimQuest", { QuestId = id })
			end)
		else
			makeLabel(r, "Hadiah " .. formatMoney(quest.Reward), UDim2.new(0, 110, 0, 30), UDim2.new(1, -120, 0, 17), 13, GOLD)
		end
	end
end

local function buildHowTo(content)
	local lines = {
		"1. Brainrot berjalan di conveyor tengah. Klik brainrotnya (atau beli dari menu Beli) untuk membelinya.",
		"2. Brainrot yang dibeli jalan ke basemu dan menghasilkan uang tiap detik.",
		"3. Pakai uangmu untuk beli brainrot tier berikutnya yang lebih mahal dan lebih menghasilkan.",
		"4. Pemain lain bisa mencuri brainrot dari basemu. Kunci basemu dengan tombol Kunci (L) dan tampar pencuri dengan tombol Tampar (F).",
		"5. Gabungkan 3 brainrot yang sama di menu Fusion jadi 1 mutasi yang lebih kuat.",
		"6. Beli Kucing Pasar di menu Upgrade: dia mengusir pencuri sendiri.",
		"7. Rebirth kalau penghasilan totalmu cukup, pengalimu naik permanen.",
		"8. Putar Roda Keberuntungan tiap 10 menit dan klaim hadiah harianmu.",
	}
	local y = 0
	for _, line in ipairs(lines) do
		makeLabel(content, line, UDim2.new(1, 0, 0, 40), UDim2.new(0, 0, 0, y), 14, CREAM)
		y += 44
	end
end

local function buildSettings(content)
	local y = 0
	local volumeNames = { "Mati", "Setengah", "Penuh" }
	local volumeButton = makeButton(content, "Volume suara: " .. volumeNames[volumeLevel + 1], UDim2.new(0, 260, 0, 40), UDim2.new(0, 0, 0, y), Color3.fromRGB(60, 120, 200))
	volumeButton.MouseButton1Click:Connect(function()
		volumeLevel = (volumeLevel + 1) % 3
		volumeButton.Text = "Volume suara: " .. volumeNames[volumeLevel + 1]
		local volume = volumeLevel == 0 and 0 or volumeLevel == 1 and 0.5 or 1
		for _, sound in ipairs(game:GetService("SoundService"):GetChildren()) do
			if sound:IsA("Sound") then
				sound.Volume = sound.Volume * 0 + volume * 0.6
			end
		end
	end)
	y += 50
	local shadowButton = makeButton(content, "Bayangan: " .. (shadowsOn and "Nyala" or "Mati"), UDim2.new(0, 260, 0, 40), UDim2.new(0, 0, 0, y), Color3.fromRGB(60, 120, 200))
	shadowButton.MouseButton1Click:Connect(function()
		shadowsOn = not shadowsOn
		Lighting.GlobalShadows = shadowsOn
		shadowButton.Text = "Bayangan: " .. (shadowsOn and "Nyala" or "Mati")
	end)
	y += 50
	local cameraButton = makeButton(content, "Reset Kamera", UDim2.new(0, 260, 0, 40), UDim2.new(0, 0, 0, y), Color3.fromRGB(120, 60, 160))
	cameraButton.MouseButton1Click:Connect(function()
		local player = Players.LocalPlayer
		local character = player and player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local camera = game:GetService("Workspace").CurrentCamera
		if humanoid and camera then
			camera.CameraSubject = humanoid
			camera.CameraType = Enum.CameraType.Custom
		end
	end)
end

local builders = {
	Shop = buildShop,
	Base = buildBase,
	Index = buildIndex,
	Upgrades = buildUpgrades,
	Rebirth = buildRebirth,
	Fusion = buildFusion,
	Event = buildEvent,
	Leaderboard = buildLeaderboard,
	Daily = buildDaily,
	Quests = buildQuests,
	HowTo = buildHowTo,
	Settings = buildSettings,
}

function UiBuilder.RefreshPanel(name)
	local panel = panels[name]
	if not panel or not state then
		return
	end
	clearContent(panel.Content)
	local builder = builders[name]
	if builder then
		builder(panel.Content)
	end
end

function UiBuilder.Refresh(newState)
	state = newState
	if hudMoney then
		hudMoney.Text = formatMoney(state.Money)
	end
	if hudIncome then
		hudIncome.Text = "+" .. formatMoney(state.IncomePerSecond) .. "/detik"
	end
	if hudRebirth then
		hudRebirth.Text = "Rebirth x" .. tostring(state.RebirthMultiplier) .. "  (" .. state.Rebirths .. "x)"
	end
	if eventBanner then
		if state.CurrentEvent then
			eventBanner.Visible = true
			eventBanner.Text = state.CurrentEvent.Name .. " - berakhir " .. state.CurrentEvent.EndsIn .. " dtk"
		else
			eventBanner.Visible = false
		end
	end
	for name, panel in pairs(panels) do
		if panel.Frame.Visible then
			UiBuilder.RefreshPanel(name)
		end
	end
	if os.clock() > toastUntil and toastLabel then
		toastLabel.Visible = false
	end
end

function UiBuilder.Toast(text)
	if not toastLabel then
		return
	end
	toastLabel.Text = text
	toastLabel.Visible = true
	toastUntil = os.clock() + 3
end

function UiBuilder.Build(action)
	actionFn = action
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	gui = Instance.new("ScreenGui")
	gui.Name = "PasarMalamGui"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	-- HUD top-right: money, income, rebirth. Clear of the top-left.
	local hud = Instance.new("Frame")
	hud.Name = "Hud"
	hud.Size = UDim2.new(0, 250, 0, 96)
	hud.Position = UDim2.new(1, -262, 0, 12)
	hud.BackgroundColor3 = Color3.fromRGB(35, 25, 55)
	hud.BackgroundTransparency = 0.2
	hud.BorderSizePixel = 0
	hud.Parent = gui
	corner(hud, 12)
	stroke(hud, PANEL_EDGE, 2)

	hudMoney = makeLabel(hud, "$0", UDim2.new(1, -16, 0, 34), UDim2.new(0, 8, 0, 6), 24, GOLD, Enum.Font.FredokaOne)
	hudIncome = makeLabel(hud, "+$0/detik", UDim2.new(1, -16, 0, 24), UDim2.new(0, 8, 0, 42), 15, GREEN)
	hudRebirth = makeLabel(hud, "Rebirth x1 (0x)", UDim2.new(1, -16, 0, 22), UDim2.new(0, 8, 0, 68), 13, CREAM)

	-- Event banner, top-center.
	eventBanner = makeLabel(gui, "", UDim2.new(0, 420, 0, 34), UDim2.new(0.5, -210, 0, 12), 16, GOLD)
	eventBanner.BackgroundColor3 = Color3.fromRGB(35, 25, 55)
	eventBanner.BackgroundTransparency = 0.2
	eventBanner.Visible = false
	corner(eventBanner, 10)

	-- Bottom menu bar.
	local bar = Instance.new("Frame")
	bar.Name = "MenuBar"
	bar.Size = UDim2.new(1, -24, 0, 52)
	bar.Position = UDim2.new(0, 12, 1, -64)
	bar.BackgroundColor3 = Color3.fromRGB(35, 25, 55)
	bar.BackgroundTransparency = 0.2
	bar.BorderSizePixel = 0
	bar.Parent = gui
	corner(bar, 12)
	stroke(bar, PANEL_EDGE, 2)

	local menuButtons = {
		{ "Beli", "Shop" },
		{ "Base", "Base" },
		{ "Koleksi", "Index" },
		{ "Upgrade", "Upgrades" },
		{ "Rebirth", "Rebirth" },
		{ "Fusion", "Fusion" },
		{ "Event", "Event" },
		{ "Juara", "Leaderboard" },
		{ "Hadiah", "Daily" },
		{ "Misi", "Quests" },
		{ "Cara Main", "HowTo" },
		{ "Pengaturan", "Settings" },
	}
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 6)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Parent = bar
	for _, entry in ipairs(menuButtons) do
		local button = makeButton(bar, entry[1], UDim2.new(0, 0, 0, 40), UDim2.new(0, 0, 0, 0), Color3.fromRGB(90, 55, 130))
		button.Size = UDim2.new(0, 0, 0, 40)
		button.AutomaticSize = Enum.AutomaticSize.X
		button.TextSize = 13
		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 8)
		pad.PaddingRight = UDim.new(0, 8)
		pad.Parent = button
		local panelName = entry[2]
		button.MouseButton1Click:Connect(function()
			openPanel(panelName)
		end)
	end

	-- Quick action buttons: lock and slap, right side above the bar.
	local quick = Instance.new("Frame")
	quick.Size = UDim2.new(0, 220, 0, 52)
	quick.Position = UDim2.new(1, -232, 1, -124)
	quick.BackgroundTransparency = 1
	quick.Parent = gui
	local lockButton = makeButton(quick, "Kunci Base (L)", UDim2.new(0, 104, 0, 44), UDim2.new(0, 0, 0, 4), Color3.fromRGB(60, 120, 200))
	lockButton.TextSize = 13
	lockButton.MouseButton1Click:Connect(function()
		actionFn("LockBase", {})
	end)
	local slapButton = makeButton(quick, "Tampar (F)", UDim2.new(0, 104, 0, 44), UDim2.new(1, -104, 0, 4), Color3.fromRGB(200, 80, 60))
	slapButton.TextSize = 13
	slapButton.MouseButton1Click:Connect(function()
		actionFn("Slap", {})
	end)

	-- Toast, bottom-center above the menu bar.
	toastLabel = makeLabel(gui, "", UDim2.new(0, 520, 0, 36), UDim2.new(0.5, -260, 1, -170), 15, CREAM)
	toastLabel.BackgroundColor3 = Color3.fromRGB(35, 25, 55)
	toastLabel.BackgroundTransparency = 0.15
	toastLabel.Visible = false
	corner(toastLabel, 10)

	-- All panels.
	makePanel("Shop", "Beli Brainrot")
	makePanel("Base", "Basemu")
	makePanel("Index", "Koleksi Brainrot")
	makePanel("Upgrades", "Upgrade")
	makePanel("Rebirth", "Rebirth")
	makePanel("Fusion", "Fusion")
	makePanel("Event", "Event")
	makePanel("Leaderboard", "Leaderboard")
	makePanel("Daily", "Hadiah Harian & Roda")
	makePanel("Quests", "Misi Harian")
	makePanel("HowTo", "Cara Bermain")
	makePanel("Settings", "Pengaturan")

	-- Main menu, shown on join.
	local main = Instance.new("Frame")
	main.Name = "MainMenu"
	main.Size = UDim2.new(0, 520, 0, 300)
	main.Position = UDim2.new(0.5, -260, 0.5, -150)
	main.BackgroundColor3 = PANEL_BG
	main.BorderSizePixel = 0
	main.Parent = gui
	corner(main, 16)
	stroke(main, PANEL_EDGE, 3)
	panels.MainMenu = { Frame = main, Content = main }

	makeLabel(main, "PASAR MALAM", UDim2.new(1, 0, 0, 54), UDim2.new(0, 0, 0, 24), 40, GOLD, Enum.Font.FredokaOne)
	makeLabel(main, "BRAINROT", UDim2.new(1, 0, 0, 54), UDim2.new(0, 0, 0, 72), 40, Color3.fromRGB(255, 110, 110), Enum.Font.FredokaOne)
	makeLabel(main, "Beli brainrot, isi basemu, curi punya orang lain!", UDim2.new(1, -32, 0, 30), UDim2.new(0, 16, 0, 132), 15, CREAM)
	local play = makeButton(main, "MAIN", UDim2.new(0, 220, 0, 52), UDim2.new(0.5, -110, 0, 180), Color3.fromRGB(60, 160, 80))
	play.TextSize = 22
	play.MouseButton1Click:Connect(function()
		main.Visible = false
	end)
	local howto = makeButton(main, "Cara Bermain", UDim2.new(0, 220, 0, 40), UDim2.new(0.5, -110, 0, 240), Color3.fromRGB(90, 55, 130))
	howto.TextSize = 15
	howto.MouseButton1Click:Connect(function()
		main.Visible = false
		openPanel("HowTo")
	end)
end

return UiBuilder
