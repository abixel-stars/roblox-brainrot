--!nonstrict
-- Guards: the market cat. A player who buys Kucing Pasar gets a cat
-- that patrols their base and chases any thief out on its own
-- (unique feature 2).

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local Guards = {}

local gameState = nil
local world = nil
local cats = {} -- [userId] -> {Model, Position, Target}
local running = false

local function makeCatModel(ownerName)
	local model = Instance.new("Model")
	model.Name = "KucingPasar_" .. ownerName

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = Vector3.new(2, 1.4, 3)
	body.Color = Color3.fromRGB(255, 170, 60)
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.6, 1.6, 1.6)
	head.Color = Color3.fromRGB(255, 170, 60)
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.Position = Vector3.new(0, 0.8, 1.8)
	head.Parent = model

	for _, side in ipairs({ -1, 1 }) do
		local ear = Instance.new("Part")
		ear.Name = "Ear"
		ear.Size = Vector3.new(0.5, 0.7, 0.3)
		ear.Color = Color3.fromRGB(230, 130, 40)
		ear.Anchored = true
		ear.CanCollide = false
		ear.Position = Vector3.new(side * 0.6, 1.8, 1.8)
		ear.Parent = model
	end

	local tail = Instance.new("Part")
	tail.Name = "Tail"
	tail.Size = Vector3.new(0.4, 0.4, 2)
	tail.Color = Color3.fromRGB(230, 130, 40)
	tail.Anchored = true
	tail.CanCollide = false
	tail.Position = Vector3.new(0, 0.6, -2.2)
	tail.Orientation = Vector3.new(-30, 0, 0)
	tail.Parent = model

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "GuardLabel"
	billboard.Size = UDim2.new(0, 120, 0, 26)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = body
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "Kucing Pasar"
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255, 220, 120)
	label.TextStrokeTransparency = 0.2
	label.Parent = billboard

	model.PrimaryPart = body
	model.Parent = game:GetService("Workspace")
	return model
end

local function ensureCat(state)
	local cat = cats[state.UserId]
	if cat then
		return cat
	end
	local base = world.Bases[state.BaseIndex]
	if not base then
		return nil
	end
	local model = makeCatModel(state.Name)
	local start = base.Center + Vector3.new(0, 1.5, 0)
	model:PivotTo(CFrame.new(start))
	cat = { Model = model, Position = start, Home = base.Center, Target = nil }
	cats[state.UserId] = cat
	return cat
end

function Guards.Init(gameStateModule, worldModule)
	gameState = gameStateModule
	world = worldModule
	if running then
		return
	end
	running = true

	game:GetService("RunService").Heartbeat:Connect(function(dt)
		for _, state in pairs(gameState.Players) do
			if not state.Guard then
				continue
			end
			local cat = ensureCat(state)
			if not cat then
				continue
			end
			-- Find a thief inside this base: anyone who is not the
			-- owner and is standing on the base plot.
			local intruder = nil
			local intruderPos = nil
			for _, other in pairs(gameState.Players) do
				if other.UserId ~= state.UserId then
					local pos = gameState.CharacterPosition(other)
					if pos then
						local away = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(cat.Home.X, 0, cat.Home.Z)).Magnitude
						if away < Config.Guard.ChaseRadius then
							intruder = other
							intruderPos = pos
							break
						end
					end
				end
			end
			local target = nil
			if intruder then
				target = intruderPos
			else
				-- Patrol: drift around the base.
				if not cat.PatrolTarget or (cat.Position - cat.PatrolTarget).Magnitude < 1 then
					cat.PatrolTarget = cat.Home + Vector3.new(math.random(-8, 8), 1.5, math.random(-8, 8))
				end
				target = cat.PatrolTarget
			end
			local speed = intruder and Config.Guard.ChaseSpeed or 4
			local step = target - cat.Position
			local distance = step.Magnitude
			if distance > 0.5 then
				local next = cat.Position + step.Unit * math.min(speed * dt, distance)
				cat.Position = Vector3.new(next.X, 1.5, next.Z)
				cat.Model:PivotTo(CFrame.new(cat.Position))
			end
			-- Caught the thief: knock the stolen brainrot out of them.
			if intruder and intruder.Carrying and intruderPos and (cat.Position - intruderPos).Magnitude < 3.5 then
				local walker = gameState.WalkerById[intruder.Carrying]
				gameState.DropCarried(intruder, walker)
				gameState.Stun(intruder)
				gameState.Notify(intruder, "Kucing Pasar mengusirmu dari base " .. state.Name .. "!")
				gameState.Notify(state, "Kucing Pasarmu mengusir pencuri!")
			end
		end
	end)
end

return Guards
