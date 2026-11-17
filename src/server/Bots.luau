--!nonstrict
-- Bots: three market regulars who keep the world alive while a player
-- is alone. They walk to the belt, buy brainrots, carry them home,
-- and sometimes try to steal from the player's base, so the steal
-- loop is visible even in a solo screenshot.

local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Bots = {}

local gameState = nil
local world = nil
local conveyor = nil
local rng = Random.new()
local botList = {}

local function makeBotModel(def, baseIndex)
	local model = Instance.new("Model")
	model.Name = def.Name

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(3, 3.4, 3)
	body.Color = def.Color
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(2, 2, 2)
	head.Color = Color3.fromRGB(255, 220, 180)
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.Position = Vector3.new(0, 2.6, 0)
	head.Parent = model

	for _, side in ipairs({ -1, 1 }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(0.4, 0.5, 0.3)
		eye.Color = Color3.fromRGB(20, 20, 25)
		eye.Anchored = true
		eye.CanCollide = false
		eye.Position = Vector3.new(side * 0.6, 2.8, 0.95)
		eye.Parent = model
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BotLabel"
	billboard.Size = UDim2.new(0, 140, 0, 30)
	billboard.StudsOffset = Vector3.new(0, 4.4, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = body
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = def.Name .. " (BOT)"
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0.2
	label.Parent = billboard

	model.PrimaryPart = body
	model.Parent = game:GetService("Workspace")
	return model
end

local function botHome(bot)
	local base = world.Bases[bot.State.BaseIndex]
	return base and base.Center or Config.SpawnPoint
end

local function botTarget(bot)
	if bot.Mode == "Steal" and bot.StealTarget then
		local walker = bot.StealTarget
		if walker.Model and walker.Model.PrimaryPart then
			return walker.Model.PrimaryPart.Position
		end
		return nil
	elseif bot.Mode == "Buy" and bot.BuyTarget then
		local walker = bot.BuyTarget
		if walker.Model and walker.Model.PrimaryPart then
			return walker.Model.PrimaryPart.Position
		end
		return nil
	elseif bot.Mode == "Home" then
		return botHome(bot)
	elseif bot.Mode == "Wander" then
		return bot.WanderTarget
	end
	return nil
end

local function pickAffordableWalker(bot)
	local best = nil
	for _, walker in pairs(conveyor.Walkers) do
		if walker.State == "Walking" then
			local char = BrainrotData.GetCharacter(walker.CharId)
			if char and bot.State.Money >= char.Cost then
				if not best or char.Cost > BrainrotData.GetCharacter(best.CharId).Cost then
					best = walker
				end
			end
		end
	end
	return best
end

local function pickStealTarget(bot)
	-- Find a real player's base that is unlocked and holds brainrots.
	local candidates = {}
	for _, walker in pairs(gameState.WalkerById) do
		if walker.State == "Owned" and not gameState.Players[walker.Owner].IsBot then
			local owner = gameState.Players[walker.Owner]
			if owner and not gameState.IsBaseLocked(owner) then
				table.insert(candidates, walker)
			end
		end
	end
	if #candidates == 0 then
		return nil
	end
	return candidates[rng:NextInteger(1, #candidates)]
end

function Bots.Init(gameStateModule, worldModule, conveyorModule)
	gameState = gameStateModule
	world = worldModule
	conveyor = conveyorModule

	for i, def in ipairs(Config.Bots) do
		local state = gameState.NewPlayerState(-i, def.Name, true)
		state.BaseIndex = i + 1
		state.Money = 500
		gameState.Players[-i] = state
		local model = makeBotModel(def, state.BaseIndex)
		local home = botHome({ State = state })
		model:PivotTo(CFrame.new(home + Vector3.new(0, 2, 0)))
		local bot = {
			State = state,
			Model = model,
			Mode = "Wander",
			Position = home + Vector3.new(0, 2, 0),
			WanderTarget = home + Vector3.new(0, 2, 0),
			BuyTarget = nil,
			StealTarget = nil,
			NextDecision = 0,
		}
		state.BotPosition = bot.Position
		state.BotRef = bot
		table.insert(botList, bot)
	end

	-- Decisions, twice a second.
	task.spawn(function()
		while true do
			task.wait(0.5)
			for _, bot in ipairs(botList) do
				local state = bot.State
				if state.StunnedUntil and os.time() < state.StunnedUntil then
					bot.Mode = "Idle"
				elseif state.Carrying then
					bot.Mode = "Home"
					bot.BuyTarget = nil
					bot.StealTarget = nil
					-- Deposit when home.
					local home = botHome(bot)
					if (Vector3.new(bot.Position.X, 0, bot.Position.Z) - Vector3.new(home.X, 0, home.Z)).Magnitude < 10 then
						gameState.DepositCarried(state)
						bot.Mode = "Wander"
					end
				elseif bot.Mode == "Steal" and bot.StealTarget then
					local target = bot.StealTarget
					if target.State ~= "Owned" or not target.Model or not target.Model.PrimaryPart then
						bot.Mode = "Wander"
						bot.StealTarget = nil
					elseif (bot.Position - target.Model.PrimaryPart.Position).Magnitude < 4 then
						if gameState.TrySteal(state, target) then
							bot.Mode = "Home"
						else
							bot.Mode = "Wander"
						end
						bot.StealTarget = nil
					end
				elseif bot.Mode == "Buy" and bot.BuyTarget then
					local target = bot.BuyTarget
					if target.State ~= "Walking" or not target.Model or not target.Model.PrimaryPart then
						bot.Mode = "Wander"
						bot.BuyTarget = nil
					elseif (bot.Position - target.Model.PrimaryPart.Position).Magnitude < 5 then
						gameState.BuyWalker(state, target)
						bot.Mode = "Wander"
						bot.BuyTarget = nil
					end
				elseif os.time() >= bot.NextDecision then
					bot.NextDecision = os.time() + rng:NextInteger(4, 9)
					local roll = rng:NextNumber(0, 1)
					if roll < 0.3 then
						local target = pickStealTarget(bot)
						if target then
							bot.Mode = "Steal"
							bot.StealTarget = target
						else
							bot.Mode = "Wander"
							bot.WanderTarget = Vector3.new(rng:NextNumber(-8, 8), 2, rng:NextNumber(-60, 60))
						end
					elseif roll < 0.75 then
						local target = pickAffordableWalker(bot)
						if target then
							bot.Mode = "Buy"
							bot.BuyTarget = target
						else
							bot.Mode = "Wander"
							bot.WanderTarget = Vector3.new(rng:NextNumber(-8, 8), 2, rng:NextNumber(-60, 60))
						end
					else
						bot.Mode = "Wander"
						bot.WanderTarget = Vector3.new(rng:NextNumber(-8, 8), 2, rng:NextNumber(-60, 60))
					end
				end
			end
		end
	end)

	-- Movement, every frame.
	game:GetService("RunService").Heartbeat:Connect(function(dt)
		for _, bot in ipairs(botList) do
			local target = botTarget(bot)
			if target and bot.Mode ~= "Idle" then
				local current = bot.Position
				local step = target - current
				local distance = step.Magnitude
				if distance > 0.5 then
					local speed = 9 * dt
					local next = current + step.Unit * math.min(speed, distance)
					bot.Position = Vector3.new(next.X, 2, next.Z)
					bot.Model:PivotTo(CFrame.new(bot.Position))
					bot.State.BotPosition = bot.Position
				end
			end
		end
	end)
end

return Bots
