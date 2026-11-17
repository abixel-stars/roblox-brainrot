--!nonstrict
-- WorldBuilder: builds the whole night market in 3D at server start.
-- Ground, the conveyor down the middle, eight fenced bases with slots,
-- food stalls, lantern posts, the welcome arch and the night sky.
-- Returns the layout (base positions, slot spots, conveyor ends) the
-- other server modules walk on.

local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local WorldBuilder = {}

local function makePart(parent, name, size, pos, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = pos
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = true
	part.Parent = parent
	return part
end

local function makeNeon(parent, name, size, pos, color)
	local part = makePart(parent, name, size, pos, color, Enum.Material.Neon)
	return part
end

function WorldBuilder.Build()
	local workspace = game:GetService("Workspace")
	local lighting = game:GetService("Lighting")

	-- Warm night-market light.
	lighting.ClockTime = 19.5
	lighting.Brightness = 2
	lighting.Ambient = Color3.fromRGB(60, 45, 90)
	lighting.OutdoorAmbient = Color3.fromRGB(120, 80, 90)
	lighting.GlobalShadows = true
	lighting.Technology = Enum.Technology.Future
	local sky = Instance.new("Sky")
	sky.CelestialBodiesShown = true
	sky.Parent = lighting

	local root = Instance.new("Folder")
	root.Name = "PasarMalam"
	root.Parent = workspace

	-- Ground: dark cobblestone square.
	makePart(root, "Ground", Vector3.new(220, 2, 220), Vector3.new(0, -1, 0), Color3.fromRGB(70, 60, 80), Enum.Material.Cobblestone)

	-- The moon, high over the market.
	local moon = makePart(root, "Moon", Vector3.new(18, 18, 2), Vector3.new(-70, 90, -80), Color3.fromRGB(255, 240, 190), Enum.Material.Neon)
	moon.CanCollide = false
	-- A few clouds drifting above the stalls.
	for i, spot in ipairs({ Vector3.new(-40, 55, -30), Vector3.new(30, 62, 10), Vector3.new(60, 58, -50), Vector3.new(-10, 66, 50) }) do
		local cloud = makePart(root, "Cloud" .. i, Vector3.new(26, 4, 12), spot, Color3.fromRGB(235, 225, 255), Enum.Material.SmoothPlastic)
		cloud.CanCollide = false
	end

	-- The conveyor: a glowing belt down the middle.
	local belt = makePart(root, "ConveyorBelt", Vector3.new(Config.Conveyor.Width, 1, 150), Vector3.new(0, 0.5, 0), Color3.fromRGB(40, 35, 55), Enum.Material.Metal)
	belt.CanCollide = false
	for _, edge in ipairs({ -1, 1 }) do
		makeNeon(root, "ConveyorEdge", Vector3.new(0.6, 0.4, 150), Vector3.new(edge * (Config.Conveyor.Width / 2), 1.1, 0), Color3.fromRGB(255, 170, 60))
	end
	-- Chevron arrows on the belt so players read the direction.
	for z = -60, 60, 20 do
		local arrow = makePart(root, "Arrow", Vector3.new(4, 0.2, 5), Vector3.new(0, 1.05, z), Color3.fromRGB(255, 200, 90), Enum.Material.Neon)
		arrow.CanCollide = false
	end

	-- Food stalls along both sides of the belt.
	local stallColors = { Color3.fromRGB(220, 80, 80), Color3.fromRGB(90, 180, 120), Color3.fromRGB(90, 140, 230), Color3.fromRGB(230, 170, 60) }
	local stallIndex = 0
	for _, side in ipairs({ -1, 1 }) do
		for z = -55, 55, 22 do
			stallIndex += 1
			local color = stallColors[(stallIndex - 1) % #stallColors + 1]
			local x = side * 16
			makePart(root, "StallCounter", Vector3.new(6, 3, 5), Vector3.new(x, 1.5, z), Color3.fromRGB(120, 85, 55), Enum.Material.Wood)
			local roof = makePart(root, "StallRoof", Vector3.new(8, 0.6, 7), Vector3.new(x, 4.4, z), color, Enum.Material.Fabric)
			roof.Orientation = Vector3.new(0, 0, side * 6)
			makeNeon(root, "StallLamp", Vector3.new(1, 1, 1), Vector3.new(x, 3.6, z), Color3.fromRGB(255, 220, 140))
		end
	end

	-- Lantern posts lighting the walkways.
	for _, side in ipairs({ -1, 1 }) do
		for z = -65, 65, 26 do
			local x = side * 10
			makePart(root, "LanternPole", Vector3.new(0.5, 7, 0.5), Vector3.new(x, 3.5, z), Color3.fromRGB(60, 45, 35), Enum.Material.Wood)
			makeNeon(root, "Lantern", Vector3.new(1.6, 2, 1.6), Vector3.new(x, 7.4, z), Color3.fromRGB(255, 120, 80))
		end
	end

	-- Welcome arch over the spawn walkway.
	makePart(root, "ArchPillar", Vector3.new(2, 12, 2), Vector3.new(-8, 6, 82), Color3.fromRGB(180, 50, 50), Enum.Material.Wood)
	makePart(root, "ArchPillar", Vector3.new(2, 12, 2), Vector3.new(8, 6, 82), Color3.fromRGB(180, 50, 50), Enum.Material.Wood)
	makePart(root, "ArchBeam", Vector3.new(20, 2, 2), Vector3.new(0, 12.5, 82), Color3.fromRGB(180, 50, 50), Enum.Material.Wood)
	local sign = makePart(root, "ArchSign", Vector3.new(16, 3, 0.6), Vector3.new(0, 10.5, 82), Color3.fromRGB(255, 200, 60), Enum.Material.Neon)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "PASAR MALAM BRAINROT"
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.fromRGB(80, 20, 20)
	label.Parent = gui

	-- Spawn pad.
	makeNeon(root, "SpawnPad", Vector3.new(10, 0.4, 10), Vector3.new(0, 0.2, 88), Color3.fromRGB(90, 200, 120))

	-- The eight bases, with fences, a lock gate and eight slots each.
	local bases = {}
	for i, def in ipairs(Config.Bases) do
		local center = def.Position
		local folder = Instance.new("Folder")
		folder.Name = "Base" .. i
		folder.Parent = root

		local pad = makePart(folder, "Pad", Config.BaseSize, Vector3.new(center.X, 0.5, center.Z), Color3.fromRGB(95, 80, 120), Enum.Material.Concrete)
		-- A coloured rim so each base reads as its own plot.
		local rimColor = Color3.fromRGB(255, 170, 60)
		if i > 4 then
			rimColor = Color3.fromRGB(90, 180, 255)
		end
		makeNeon(folder, "Rim", Vector3.new(Config.BaseSize.X, 0.3, 0.6), Vector3.new(center.X, 1.1, center.Z - Config.BaseSize.Z / 2), rimColor)
		makeNeon(folder, "Rim", Vector3.new(Config.BaseSize.X, 0.3, 0.6), Vector3.new(center.X, 1.1, center.Z + Config.BaseSize.Z / 2), rimColor)

		-- Fences on three sides; the side facing the conveyor stays open.
		local facing = 1
		if center.X < 0 then
			facing = -1
		end
		local wallHeight = 4
		local half = Config.BaseSize.X / 2
		-- Back wall (away from the conveyor).
		makePart(folder, "FenceBack", Vector3.new(1, wallHeight, Config.BaseSize.Z), Vector3.new(center.X + facing * half, 2, center.Z), Color3.fromRGB(140, 100, 60), Enum.Material.WoodPlanks)
		-- Side walls.
		makePart(folder, "FenceSide", Vector3.new(Config.BaseSize.X, wallHeight, 1), Vector3.new(center.X, 2, center.Z - half), Color3.fromRGB(140, 100, 60), Enum.Material.WoodPlanks)
		makePart(folder, "FenceSide", Vector3.new(Config.BaseSize.X, wallHeight, 1), Vector3.new(center.X, 2, center.Z + half), Color3.fromRGB(140, 100, 60), Enum.Material.WoodPlanks)

		-- Lock gate: a red transparent wall that appears while locked.
		local gate = makePart(folder, "LockGate", Vector3.new(1, wallHeight, Config.BaseSize.Z), Vector3.new(center.X - facing * half, 2, center.Z), Color3.fromRGB(255, 60, 60), Enum.Material.Glass)
		gate.Transparency = 0.4
		gate.CanCollide = false
		gate.CanQuery = false

		-- Base name sign.
		local signPart = makePart(folder, "BaseSign", Vector3.new(10, 2.5, 0.6), Vector3.new(center.X - facing * (half + 1), 5.5, center.Z), Color3.fromRGB(40, 35, 55), Enum.Material.SmoothPlastic)
		local signGui = Instance.new("SurfaceGui")
		signGui.Face = if facing < 0 then Enum.NormalId.Right else Enum.NormalId.Left
		signGui.Parent = signPart
		local signLabel = Instance.new("TextLabel")
		signLabel.Size = UDim2.fromScale(1, 1)
		signLabel.BackgroundTransparency = 1
		signLabel.Text = "BASE " .. i
		signLabel.TextScaled = true
		signLabel.Font = Enum.Font.FredokaOne
		signLabel.TextColor3 = Color3.fromRGB(255, 220, 120)
		signLabel.Parent = signGui

		-- Eight slots in two rows of four.
		local slots = {}
		for row = 0, 1 do
			for col = 0, 3 do
				local sx = center.X + (col - 1.5) * Config.BaseSlotSpacing
				local sz = center.Z + (row - 0.5) * Config.BaseSlotSpacing
				local slotPad = makePart(folder, "SlotPad", Vector3.new(3.4, 0.3, 3.4), Vector3.new(sx, 1.15, sz), Color3.fromRGB(160, 140, 190), Enum.Material.SmoothPlastic)
				slotPad.CanCollide = false
				table.insert(slots, Vector3.new(sx, 1.3, sz))
			end
		end

		bases[i] = {
			Index = i,
			Center = center,
			Folder = folder,
			Pad = pad,
			Gate = gate,
			Slots = slots,
			Facing = facing,
		}
	end

	WorldBuilder.Bases = bases
	WorldBuilder.Root = root
	return WorldBuilder
end

return WorldBuilder
