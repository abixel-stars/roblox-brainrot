--!nonstrict
-- BrainrotFactory: turns a catalog entry into a walking 3D model.
-- Every character looks different: body shape, size, trim colour and
-- accessory come from BrainrotData, mutations tint the whole model.

local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)

local BrainrotFactory = {}

local function bodySize(shape)
	if shape == "Round" then
		return Vector3.new(3.2, 3, 3.2)
	elseif shape == "Tall" then
		return Vector3.new(2.6, 4.2, 2.6)
	elseif shape == "Flat" then
		return Vector3.new(4.4, 1.8, 3.4)
	else
		return Vector3.new(3.4, 3.2, 3.4)
	end
end

local function makeEyes(parent, size, frontZ)
	for _, side in ipairs({ -1, 1 }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(0.45, 0.55, 0.3)
		eye.Position = Vector3.new(side * 0.7, size.Y * 0.15, frontZ)
		eye.Color = Color3.fromRGB(20, 20, 25)
		eye.Material = Enum.Material.SmoothPlastic
		eye.Anchored = true
		eye.CanCollide = false
		eye.Parent = parent
	end
end

local function makeAccessory(parent, kind, size, bodyColor)
	if kind == "Hat" then
		local hat = Instance.new("Part")
		hat.Name = "Hat"
		hat.Size = Vector3.new(size.X * 0.9, 0.5, size.Z * 0.9)
		hat.Position = Vector3.new(0, size.Y / 2 + 0.4, 0)
		hat.Color = Color3.fromRGB(200, 50, 60)
		hat.Material = Enum.Material.Fabric
		hat.Anchored = true
		hat.CanCollide = false
		hat.Parent = parent
		local brim = Instance.new("Part")
		brim.Name = "HatBrim"
		brim.Size = Vector3.new(size.X * 1.2, 0.25, size.Z * 1.2)
		brim.Position = Vector3.new(0, size.Y / 2 + 0.15, 0)
		brim.Color = Color3.fromRGB(150, 30, 40)
		brim.Material = Enum.Material.Fabric
		brim.Anchored = true
		brim.CanCollide = false
		brim.Parent = parent
	elseif kind == "Crown" then
		for i = -1, 1 do
			local spike = Instance.new("Part")
			spike.Name = "CrownSpike"
			spike.Size = Vector3.new(0.5, 1, 0.5)
			spike.Position = Vector3.new(i * 0.9, size.Y / 2 + 0.7, 0)
			spike.Color = Color3.fromRGB(255, 215, 0)
			spike.Material = Enum.Material.Neon
			spike.Anchored = true
			spike.CanCollide = false
			spike.Parent = parent
		end
		local band = Instance.new("Part")
		band.Name = "CrownBand"
		band.Size = Vector3.new(size.X * 0.8, 0.4, size.Z * 0.8)
		band.Position = Vector3.new(0, size.Y / 2 + 0.2, 0)
		band.Color = Color3.fromRGB(255, 215, 0)
		band.Material = Enum.Material.Metal
		band.Anchored = true
		band.CanCollide = false
		band.Parent = parent
	elseif kind == "Wings" then
		for _, side in ipairs({ -1, 1 }) do
			local wing = Instance.new("Part")
			wing.Name = "Wing"
			wing.Size = Vector3.new(0.3, 1.6, 2.2)
			wing.Position = Vector3.new(side * (size.X / 2 + 0.4), size.Y * 0.1, -0.4)
			wing.Orientation = Vector3.new(0, 0, side * -25)
			wing.Color = Color3.fromRGB(255, 245, 220)
			wing.Material = Enum.Material.Fabric
			wing.Anchored = true
			wing.CanCollide = false
			wing.Parent = parent
		end
	end
end

-- Build the model. The model is anchored and moved by the server, so
-- it never needs a Humanoid; the label and click detector ride along.
function BrainrotFactory.Create(charId, mutationId)
	local char = BrainrotData.GetCharacter(charId)
	if not char then
		return nil
	end
	local mut = BrainrotData.MutationById[mutationId] or BrainrotData.MutationById.none

	local model = Instance.new("Model")
	model.Name = char.Name

	local size = bodySize(char.Shape)
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Size = size
	body.Color = char.Body
	body.Material = Enum.Material.SmoothPlastic
	body.Anchored = true
	body.CanCollide = false
	body.Parent = model
	if char.Shape == "Round" then
		body.Shape = Enum.PartType.Ball
	end

	-- Mutation tint: a glowing shell around the body.
	if mut.Id ~= "none" then
		local shell = Instance.new("Part")
		shell.Name = "MutationShell"
		shell.Size = size + Vector3.new(0.5, 0.5, 0.5)
		shell.Color = mut.Color
		shell.Material = Enum.Material.Neon
		shell.Transparency = 0.55
		shell.Anchored = true
		shell.CanCollide = false
		shell.Parent = model
		if char.Shape == "Round" then
			shell.Shape = Enum.PartType.Ball
		end
	end

	-- Trim stripe across the body.
	local trim = Instance.new("Part")
	trim.Name = "Trim"
	trim.Size = Vector3.new(size.X + 0.1, 0.5, size.Z + 0.1)
	trim.Position = Vector3.new(0, -size.Y * 0.2, 0)
	trim.Color = char.Trim
	trim.Material = Enum.Material.SmoothPlastic
	trim.Anchored = true
	trim.CanCollide = false
	trim.Parent = model

	makeEyes(model, size, size.Z / 2 + 0.1)
	makeAccessory(model, char.Accessory, size, char.Body)

	-- Floating label: name, rarity and income per second, readable
	-- from across the market.
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "BrainrotLabel"
	billboard.Size = UDim2.new(0, 200, 0, 70)
	billboard.StudsOffset = Vector3.new(0, size.Y / 2 + 2.2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = body

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = BrainrotData.LabelOf(charId, mutationId)
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.2
	nameLabel.Parent = billboard

	local tier = BrainrotData.GetTier(char.Tier)
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(1, 0, 0.3, 0)
	rarityLabel.Position = UDim2.new(0, 0, 0.4, 0)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = char.Tier
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.TextScaled = true
	rarityLabel.TextColor3 = tier.Color
	rarityLabel.TextStrokeTransparency = 0.2
	rarityLabel.Parent = billboard

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "RateLabel"
	rateLabel.Size = UDim2.new(1, 0, 0.3, 0)
	rateLabel.Position = UDim2.new(0, 0, 0.7, 0)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = "$" .. tostring(BrainrotData.RateOf(charId, mutationId)) .. "/detik"
	rateLabel.Font = Enum.Font.GothamBold
	rateLabel.TextScaled = true
	rateLabel.TextColor3 = Color3.fromRGB(140, 255, 140)
	rateLabel.TextStrokeTransparency = 0.2
	rateLabel.Parent = billboard

	-- Clicking the brainrot buys it (server checks the money).
	local click = Instance.new("ClickDetector")
	click.Name = "BuyClick"
	click.MaxActivationDistance = 40
	click.Parent = body

	model.PrimaryPart = body
	return model
end

return BrainrotFactory
