--!nonstrict
-- GameEvents: the market's weather. Every few minutes one event
-- fires for a minute: rare rain, double pay, a lantern parade, or a
-- wave that sends everyone running home.

local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)

local GameEvents = {}

local gameState = nil
local conveyor = nil
local rng = Random.new()
local running = false

local function announce(text)
	for _, state in pairs(gameState.Players) do
		gameState.Notify(state, text)
	end
end

local function startEvent(def)
	gameState.CurrentEvent = {
		Id = def.Id,
		Name = def.Name,
		Desc = def.Desc,
		EndsAt = os.time() + def.Duration,
	}
	announce("EVENT: " .. def.Name .. " - " .. def.Desc)
	if def.Id == "gajian_ganda" then
		gameState.EventIncomeMultiplier = 2
	elseif def.Id == "hujan_langka" then
		gameState.RareBoost = true
		-- A few rare walkers right away so the rain is visible.
		for _ = 1, 3 do
			local pool = {}
			for _, char in ipairs(BrainrotData.Characters) do
				local tier = BrainrotData.GetTier(char.Tier)
				if tier.Order >= 3 then
					table.insert(pool, char)
				end
			end
			local char = pool[rng:NextInteger(1, #pool)]
			conveyor.SpawnWalker(char.Id, BrainrotData.RollMutation(rng))
		end
	elseif def.Id == "parade" then
		-- Unique feature 3: a parade of rare brainrots everyone can buy.
		for _ = 1, 5 do
			local pool = {}
			for _, char in ipairs(BrainrotData.Characters) do
				local tier = BrainrotData.GetTier(char.Tier)
				if tier.Order >= 4 then
					table.insert(pool, char)
				end
			end
			local char = pool[rng:NextInteger(1, #pool)]
			conveyor.SpawnWalker(char.Id, BrainrotData.RollMutation(rng))
		end
	elseif def.Id == "gelombang" then
		-- Ten seconds to get home, then the wave sweeps the market.
		task.delay(def.Duration, function()
			for _, state in pairs(gameState.Players) do
				if state.IsBot then
					continue
				end
				local home = gameState.BaseCenter(state)
				local pos = gameState.CharacterPosition(state)
				if home and pos then
					local away = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(home.X, 0, home.Z)).Magnitude
					if away > 13 then
						if state.Carrying then
							local walker = gameState.WalkerById[state.Carrying]
							gameState.DropCarried(state, walker)
							gameState.Notify(state, "Ombak datang! Brainrot curianmu jatuh di jalan.")
						end
						local player = Players:GetPlayerByUserId(state.UserId)
						local character = player and player.Character
						local root = character and character:FindFirstChild("HumanoidRootPart")
						if root then
							root.CFrame = CFrame.new(Config.SpawnPoint + Vector3.new(0, 2, 0))
						end
						gameState.Notify(state, "Ombak menyapumu pulang ke titik spawn!")
					end
				end
			end
		end)
	end
end

local function endEvent()
	local event = gameState.CurrentEvent
	if not event then
		return
	end
	gameState.CurrentEvent = nil
	gameState.EventIncomeMultiplier = 1
	gameState.RareBoost = false
	announce("Event " .. event.Name .. " selesai.")
end

function GameEvents.Init(gameStateModule, conveyorModule)
	gameState = gameStateModule
	conveyor = conveyorModule
	if running then
		return
	end
	running = true
	task.spawn(function()
		task.wait(45) -- let the first players settle in
		while true do
			local def = Config.Events[rng:NextInteger(1, #Config.Events)]
			startEvent(def)
			task.wait(def.Duration)
			endEvent()
			task.wait(rng:NextInteger(Config.EventEveryMinSeconds, Config.EventEveryMaxSeconds))
		end
	end)
end

return GameEvents
