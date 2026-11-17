--!nonstrict
-- Conveyor: spawns brainrots, walks them down the middle belt, and
-- moves them again when they are bought, stolen, carried or dropped.
-- It owns every brainrot model in the world; GameState owns the money
-- and the ownership decisions.

local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local BrainrotFactory = require(script.Parent.BrainrotFactory)

local Conveyor = {}

Conveyor.Walkers = {} -- [walkerId] -> walker record
local gameState = nil
local world = nil
local folder = nil
local rng = Random.new()
local running = false

local function walkerRecord(id, charId, mutationId, model)
	return {
		Id = id,
		CharId = charId,
		Mutation = mutationId,
		Model = model,
		State = "Walking", -- Walking | ToBase | Owned | Carried | Returning
		Owner = nil,
		OriginalOwner = nil,
		CarriedBy = nil,
		SlotIndex = 0,
		Rate = BrainrotData.RateOf(charId, mutationId),
		FusionBonus = 1,
		Progress = 0, -- distance walked along the belt
		TargetSlot = nil,
	}
end

local function moveModel(model, position)
	if not model or not model.PrimaryPart then
		return
	end
	model:PivotTo(CFrame.new(position))
end

function Conveyor.SpawnWalker(charId, mutationId)
	local count = 0
	for _ in pairs(Conveyor.Walkers) do
		count += 1
	end
	if count >= 200 then
		return nil
	end
	charId = charId or BrainrotData.RollCharacter(rng).Id
	mutationId = mutationId or BrainrotData.RollMutation(rng)
	local model = BrainrotFactory.Create(charId, mutationId)
	if not model then
		return nil
	end
	local id = gameState.NextWalkerId()
	local walker = walkerRecord(id, charId, mutationId, model)
	model.Name = "Walker" .. id
	model.Parent = folder
	moveModel(model, Config.Conveyor.Start)
	-- Clicking a walker buys it; GameState checks the money.
	local click = model.Body:FindFirstChild("BuyClick")
	if click then
		click.MouseClick:Connect(function(player)
			local buyer = gameState.GetPlayer(player.UserId)
			if buyer then
				gameState.BuyWalker(buyer, walker)
			end
		end)
	end
	Conveyor.Walkers[id] = walker
	gameState.WalkerById[id] = walker
	return walker
end

-- Spawn a brainrot straight into a player's base (wheel and fusion).
function Conveyor.SpawnOwned(playerState, charId, mutationId, fusionBonus)
	local slot = gameState.FreeSlot(playerState)
	if not slot then
		return nil
	end
	local model = BrainrotFactory.Create(charId, mutationId)
	if not model then
		return nil
	end
	local id = gameState.NextWalkerId()
	local walker = walkerRecord(id, charId, mutationId, model)
	walker.FusionBonus = fusionBonus or 1
	walker.Rate = BrainrotData.RateOf(charId, mutationId) * walker.FusionBonus
	walker.State = "Owned"
	walker.Owner = playerState.UserId
	walker.SlotIndex = slot
	model.Name = "Owned" .. id
	model.Parent = folder
	playerState.Owned[id] = walker
	Conveyor.Walkers[id] = walker
	gameState.WalkerById[id] = walker
	Conveyor.PlaceInSlot(walker, playerState.BaseIndex, slot)
	return walker
end

-- A bought walker walks from the belt to its owner's base slot.
function Conveyor.SendToBase(walker, baseIndex, slotIndex)
	walker.State = "ToBase"
	walker.TargetBase = baseIndex
	walker.TargetSlot = slotIndex
end

-- Put an owned brainrot on its slot pad.
function Conveyor.PlaceInSlot(walker, baseIndex, slotIndex)
	local base = world.Bases[baseIndex]
	if not base or not walker.Model then
		return
	end
	local spot = base.Slots[slotIndex]
	if spot then
		moveModel(walker.Model, spot + Vector3.new(0, 1.6, 0))
	end
end

-- Lift a stolen brainrot above its carrier's head.
function Conveyor.Carry(walker, carrierState)
	if not walker.Model then
		return
	end
	local pos = gameState.CharacterPosition(carrierState)
	if pos then
		moveModel(walker.Model, pos + Vector3.new(0, 4.5, 0))
	end
	walker.CarriedBy = carrierState.UserId
end

-- A dropped brainrot walks back to its owner's slot.
function Conveyor.ReturnHome(walker, baseIndex, slotIndex)
	walker.State = "Returning"
	walker.TargetBase = baseIndex
	walker.TargetSlot = slotIndex
	local owner = gameState.GetPlayer(walker.OriginalOwner or walker.Owner)
	if owner then
		walker.Owner = owner.UserId
		owner.Owned[walker.Id] = walker
	end
end

function Conveyor.Despawn(walker)
	if not walker then
		return
	end
	Conveyor.Walkers[walker.Id] = nil
	gameState.WalkerById[walker.Id] = nil
	if walker.Model then
		walker.Model:Destroy()
		walker.Model = nil
	end
end

-- Rebuild the floating label after a mutation change (wheel prize).
function Conveyor.RefreshLabel(walker)
	if not walker.Model then
		return
	end
	local body = walker.Model:FindFirstChild("Body")
	local billboard = body and body:FindFirstChild("BrainrotLabel")
	if not billboard then
		return
	end
	local rateLabel = billboard:FindFirstChild("RateLabel")
	if rateLabel then
		rateLabel.Text = "$" .. tostring(walker.Rate) .. "/detik"
	end
	for _, label in ipairs(billboard:GetChildren()) do
		if label:IsA("TextLabel") and label.Text ~= "" and label.Name ~= "RateLabel" then
			label.Text = BrainrotData.LabelOf(walker.CharId, walker.Mutation)
		end
	end
end

local function beltPosition(progress)
	local start = Config.Conveyor.Start
	local finish = Config.Conveyor.Finish
	return start:Lerp(finish, progress)
end

local function slotPosition(baseIndex, slotIndex)
	local base = world.Bases[baseIndex]
	if not base then
		return Config.Conveyor.Start
	end
	local spot = base.Slots[slotIndex] or base.Center
	return spot + Vector3.new(0, 1.6, 0)
end

function Conveyor.Init(gameStateModule, worldModule)
	gameState = gameStateModule
	world = worldModule
	folder = Instance.new("Folder")
	folder.Name = "Brainrots"
	folder.Parent = game:GetService("Workspace")

	if running then
		return
	end
	running = true

	-- Spawn a fresh walker every few seconds, up to the cap.
	task.spawn(function()
		while true do
			task.wait(Config.Conveyor.SpawnEverySeconds)
			local walking = 0
			for _, walker in pairs(Conveyor.Walkers) do
				if walker.State == "Walking" then
					walking += 1
				end
			end
			if walking < Config.Conveyor.MaxWalkers then
				Conveyor.SpawnWalker()
			end
		end
	end)

	-- Move every walker a little, every frame.
	game:GetService("RunService").Heartbeat:Connect(function(dt)
		for _, walker in pairs(Conveyor.Walkers) do
			local model = walker.Model
			if not model or not model.PrimaryPart then
				continue
			end
			if walker.State == "Walking" then
				walker.Progress += (Config.Conveyor.WalkSpeed * dt) / (Config.Conveyor.Finish - Config.Conveyor.Start).Magnitude
				if walker.Progress >= 1 then
					Conveyor.Despawn(walker)
				else
					moveModel(model, beltPosition(walker.Progress))
				end
			elseif walker.State == "ToBase" then
				local target = slotPosition(walker.TargetBase, walker.TargetSlot)
				local current = model.PrimaryPart.Position
				local step = (target - current)
				local distance = step.Magnitude
				if distance < 1 then
					gameState.ArriveAtBase(walker)
				else
					local speed = Config.Conveyor.WalkSpeed * 2.5 * dt
					moveModel(model, current + step.Unit * math.min(speed, distance))
				end
			elseif walker.State == "Returning" then
				local target = slotPosition(walker.TargetBase, walker.TargetSlot)
				local current = model.PrimaryPart.Position
				local step = (target - current)
				local distance = step.Magnitude
				if distance < 1 then
					walker.State = "Owned"
					Conveyor.PlaceInSlot(walker, walker.TargetBase, walker.TargetSlot)
				else
					local speed = Config.Conveyor.WalkSpeed * 2 * dt
					moveModel(model, current + step.Unit * math.min(speed, distance))
				end
			elseif walker.State == "Carried" then
				local carrier = gameState.GetPlayer(walker.CarriedBy)
				if carrier then
					local pos = gameState.CharacterPosition(carrier)
					if pos then
						moveModel(model, pos + Vector3.new(0, 4.5, 0))
					end
				end
			end
		end
	end)
end

return Conveyor
