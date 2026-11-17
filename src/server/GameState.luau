--!nonstrict
-- GameState: the one place player state lives. Money, owned
-- brainrots, upgrades, rebirths, quests, daily rewards, the wheel,
-- fusion, locks and slaps are all decided here. The conveyor moves
-- the models; this module decides who owns them and who can pay.

local Players = game:GetService("Players")

local BrainrotData = require(game:GetService("ReplicatedStorage").Shared.BrainrotData)
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

local GameState = {}

GameState.Players = {} -- [userId] -> player state
GameState.WalkerById = {} -- filled by the conveyor, for lookups
GameState.CurrentEvent = nil -- {Id, Name, EndsAt}
GameState.EventIncomeMultiplier = 1
GameState.RareBoost = false

local remotes = nil
local world = nil
local conveyor = nil
local nextWalkerId = 1

local function now()
	return os.time()
end

local function todayString()
	return os.date("%Y-%m-%d")
end

function GameState.NextWalkerId()
	nextWalkerId += 1
	return nextWalkerId - 1
end

function GameState.NewPlayerState(userId, name, isBot)
	local state = {
		UserId = userId,
		Name = name,
		IsBot = isBot or false,
		Money = Config.StartMoney,
		LifetimeEarned = 0,
		Rebirths = 0,
		Upgrades = { speed = 0, income = 0, lock = 0, slots = 0, slap = 0 },
		Owned = {}, -- [walkerId] -> walker record
		Quests = {},
		LastDaily = "",
		LastWheel = 0,
		Guard = false,
		BaseIndex = 0,
		LockUntil = 0,
		LockCooldownUntil = 0,
		SlapCooldownUntil = 0,
		Carrying = nil, -- walkerId carried by this player
	}
	for _, quest in ipairs(Config.Quests) do
		state.Quests[quest.Id] = { Progress = 0, Claimed = false }
	end
	return state
end

function GameState.GetPlayer(userId)
	return GameState.Players[userId]
end

function GameState.MaxSlots(state)
	return Config.BaseSlots + state.Upgrades.slots
end

function GameState.FreeSlot(state)
	local used = {}
	for _, walker in pairs(state.Owned) do
		used[walker.SlotIndex] = true
	end
	for i = 1, GameState.MaxSlots(state) do
		if not used[i] then
			return i
		end
	end
	return nil
end

function GameState.RebirthMultiplier(state)
	return 1 + Config.Rebirth.MultiplierPerRebirth * state.Rebirths
end

function GameState.IncomePerSecond(state)
	local total = 0
	for _, walker in pairs(state.Owned) do
		-- Only brainrots sitting on their slot earn; ones being
		-- carried or walking home do not.
		if walker.State == "Owned" then
			total += walker.Rate
		end
	end
	total *= GameState.RebirthMultiplier(state)
	total *= 1 + Config.UpgradeById.income.Effect * state.Upgrades.income
	total *= GameState.EventIncomeMultiplier
	return math.floor(total)
end

function GameState.WalkSpeed(state)
	return 16 * (1 + Config.UpgradeById.speed.Effect * state.Upgrades.speed)
end

function GameState.IsBaseLocked(state)
	return now() < state.LockUntil
end

-- -- buying ---------------------------------------------------------------

function GameState.BuyWalker(playerState, walker)
	if not walker or walker.State ~= "Walking" then
		return false, "Brainrot itu sudah tidak di conveyor."
	end
	local char = BrainrotData.GetCharacter(walker.CharId)
	if not char then
		return false, "Brainrot tidak dikenal."
	end
	if playerState.Money < char.Cost then
		return false, "Uangmu belum cukup."
	end
	local slot = GameState.FreeSlot(playerState)
	if not slot then
		return false, "Base kamu penuh, upgrade slot dulu."
	end
	playerState.Money -= char.Cost
	walker.State = "ToBase"
	walker.Owner = playerState.UserId
	walker.SlotIndex = slot
	playerState.Owned[walker.Id] = walker
	playerState.Quests.beli3.Progress += 1
	conveyor.SendToBase(walker, playerState.BaseIndex, slot)
	GameState.Notify(playerState, "Kamu membeli " .. BrainrotData.LabelOf(walker.CharId, walker.Mutation) .. "!")
	return true, "OK"
end

-- Called by the conveyor when a bought brainrot reaches its slot.
function GameState.ArriveAtBase(walker)
	local owner = GameState.Players[walker.Owner]
	if not owner then
		return
	end
	walker.State = "Owned"
	conveyor.PlaceInSlot(walker, owner.BaseIndex, walker.SlotIndex)
end

-- -- stealing -------------------------------------------------------------

function GameState.TrySteal(thiefState, walker)
	if not walker or walker.State ~= "Owned" then
		return false
	end
	if walker.Owner == thiefState.UserId then
		return false
	end
	if thiefState.Carrying then
		return false
	end
	local owner = GameState.Players[walker.Owner]
	if owner and GameState.IsBaseLocked(owner) then
		return false
	end
	walker.State = "Carried"
	walker.CarriedBy = thiefState.UserId
	walker.OriginalOwner = walker.Owner
	thiefState.Carrying = walker.Id
	conveyor.Carry(walker, thiefState)
	return true
end

-- Called when a carrier steps inside their own base.
function GameState.DepositCarried(playerState)
	local walker = playerState.Carrying and GameState.WalkerById[playerState.Carrying]
	if not walker or walker.State ~= "Carried" then
		return
	end
	local slot = GameState.FreeSlot(playerState)
	if not slot then
		GameState.DropCarried(playerState, walker)
		GameState.Notify(playerState, "Base penuh, brainrot curian kembali ke pemiliknya.")
		return
	end
	local oldOwner = GameState.Players[walker.OriginalOwner]
	if oldOwner then
		oldOwner.Owned[walker.Id] = nil
	end
	walker.Owner = playerState.UserId
	walker.SlotIndex = slot
	walker.State = "Owned"
	walker.CarriedBy = nil
	walker.OriginalOwner = nil
	playerState.Owned[walker.Id] = walker
	playerState.Carrying = nil
	playerState.Quests.curi1.Progress += 1
	conveyor.PlaceInSlot(walker, playerState.BaseIndex, slot)
	GameState.Notify(playerState, "Berhasil mencuri " .. BrainrotData.LabelOf(walker.CharId, walker.Mutation) .. "!")
end

function GameState.DropCarried(playerState, walker)
	walker = walker or (playerState.Carrying and GameState.WalkerById[playerState.Carrying])
	if not walker then
		return
	end
	playerState.Carrying = nil
	walker.State = "Returning"
	walker.CarriedBy = nil
	local owner = GameState.Players[walker.OriginalOwner or walker.Owner]
	conveyor.ReturnHome(walker, owner and owner.BaseIndex or 1, walker.SlotIndex)
end

-- -- slap -----------------------------------------------------------------

function GameState.Slap(playerState)
	if now() < playerState.SlapCooldownUntil then
		return false, "Tamparan masih cooldown."
	end
	local cooldown = Config.SlapCooldownSeconds * (1 - Config.UpgradeById.slap.Effect * playerState.Upgrades.slap)
	playerState.SlapCooldownUntil = now() + math.max(1, math.floor(cooldown))
	local origin = GameState.CharacterPosition(playerState)
	if not origin then
		return false, "Karaktermu belum siap."
	end
	-- nearest carrier found below
	local victimState = nil
	for userId, other in pairs(GameState.Players) do
		if userId ~= playerState.UserId and other.Carrying then
			local pos = GameState.CharacterPosition(other)
			if pos and (pos - origin).Magnitude <= Config.SlapRange then
				victimState = other
				break
			end
		end
	end
	if not victimState then
		return false, "Tidak ada pencuri di dekatmu."
	end
	local walker = GameState.WalkerById[victimState.Carrying]
	GameState.DropCarried(victimState, walker)
	GameState.Stun(victimState)
	GameState.Notify(playerState, "Kamu menampar " .. victimState.Name .. ", brainrotnya jatuh!")
	GameState.Notify(victimState, playerState.Name .. " menamparmu! Brainrot curianmu jatuh.")
	return true, "OK"
end

function GameState.Stun(state)
	if state.IsBot then
		state.StunnedUntil = now() + Config.SlapStunSeconds
		return
	end
	local player = Players:GetPlayerByUserId(state.UserId)
	if not player then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 0
		task.delay(Config.SlapStunSeconds, function()
			if humanoid.Parent then
				humanoid.WalkSpeed = GameState.WalkSpeed(state)
			end
		end)
	end
end

-- -- lock -----------------------------------------------------------------

function GameState.LockBase(playerState)
	if now() < playerState.LockCooldownUntil then
		return false, "Kunci base masih cooldown."
	end
	local seconds = Config.LockBaseSeconds + Config.LockExtraPerLevel * playerState.Upgrades.lock
	playerState.LockUntil = now() + seconds
	playerState.LockCooldownUntil = now() + seconds + Config.LockCooldownSeconds
	GameState.SetGate(playerState, true)
	task.delay(seconds, function()
		GameState.SetGate(playerState, false)
	end)
	return true, "Base dikunci " .. seconds .. " detik!"
end

function GameState.SetGate(playerState, locked)
	local base = world.Bases[playerState.BaseIndex]
	if not base then
		return
	end
	base.Gate.Transparency = locked and 0.4 or 1
	base.Gate.CanCollide = locked
end

-- -- upgrades, rebirth ----------------------------------------------------

function GameState.BuyUpgrade(playerState, upgradeId)
	local up = Config.UpgradeById[upgradeId]
	if not up then
		return false, "Upgrade tidak dikenal."
	end
	local level = playerState.Upgrades[upgradeId] or 0
	if level >= up.MaxLevel then
		return false, "Upgrade sudah maksimal."
	end
	local cost = Config.UpgradeCost(up, level)
	if playerState.Money < cost then
		return false, "Uangmu belum cukup."
	end
	playerState.Money -= cost
	playerState.Upgrades[upgradeId] = level + 1
	GameState.ApplyWalkSpeed(playerState)
	return true, up.Name .. " naik ke level " .. (level + 1) .. "!"
end

function GameState.ApplyWalkSpeed(playerState)
	if playerState.IsBot then
		return
	end
	local player = Players:GetPlayerByUserId(playerState.UserId)
	if not player then
		return
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = GameState.WalkSpeed(playerState)
	end
end

function GameState.RebirthRequirement(state)
	return math.floor(Config.Rebirth.BaseRequirement * (Config.Rebirth.RequirementMult ^ state.Rebirths))
end

function GameState.DoRebirth(playerState)
	local need = GameState.RebirthRequirement(playerState)
	if playerState.LifetimeEarned < need then
		return false, "Butuh penghasilan total $" .. tostring(need) .. " untuk rebirth."
	end
	for walkerId, walker in pairs(playerState.Owned) do
		conveyor.Despawn(walker)
		playerState.Owned[walkerId] = nil
	end
	playerState.Money = Config.StartMoney
	playerState.LifetimeEarned = 0
	playerState.Rebirths += 1
	return true, "Rebirth! Penghasilanmu sekarang x" .. tostring(GameState.RebirthMultiplier(playerState)) .. "."
end

-- -- fusion (unique feature 1) --------------------------------------------

function GameState.Fuse(playerState, charId)
	local char = BrainrotData.GetCharacter(charId)
	if not char then
		return false, "Brainrot tidak dikenal."
	end
	local matches = {}
	for walkerId, walker in pairs(playerState.Owned) do
		if walker.CharId == charId and walker.State == "Owned" then
			table.insert(matches, walker)
		end
	end
	if #matches < 3 then
		return false, "Butuh 3 " .. char.Name .. " untuk fusion."
	end
	-- Fusion frees two slots net (3 in, 1 out), so even a full base
	-- has room for the result once the three are removed.
	local rng = Random.new()
	local mutations = { "emas", "beku", "api", "pelangi" }
	local mutation = mutations[rng:NextInteger(1, #mutations)]
	for i = 1, 3 do
		local walker = matches[i]
		playerState.Owned[walker.Id] = nil
		conveyor.Despawn(walker)
	end
	local fused = conveyor.SpawnOwned(playerState, charId, mutation, Config.FusionBonus)
	if not fused then
		return false, "Fusion gagal, coba lagi."
	end
	GameState.Notify(playerState, "Fusion! " .. BrainrotData.LabelOf(charId, mutation) .. " lahir, penghasilannya x" .. tostring(Config.FusionBonus) .. " lebih besar!")
	return true, "OK"
end

-- -- wheel (unique feature: Roda Keberuntungan) ----------------------------

function GameState.SpinWheel(playerState)
	if now() - playerState.LastWheel < Config.WheelCooldownSeconds then
		return false, "Roda keberuntungan masih cooldown."
	end
	playerState.LastWheel = now()
	local rng = Random.new()
	local total = 0
	for _, prize in ipairs(Config.WheelPrizes) do
		total += prize.Weight
	end
	local roll = rng:NextNumber(0, total)
	local acc = 0
	local picked = Config.WheelPrizes[1]
	for _, prize in ipairs(Config.WheelPrizes) do
		acc += prize.Weight
		if roll <= acc then
			picked = prize
			break
		end
	end
	if picked.Kind == "money" then
		playerState.Money += picked.Amount
		GameState.Notify(playerState, "Roda keberuntungan: kamu dapat " .. picked.Text .. "!")
	elseif picked.Kind == "brainrot" then
		local pool = {}
		for _, char in ipairs(BrainrotData.Characters) do
			if char.Tier == picked.Tier then
				table.insert(pool, char)
			end
		end
		local char = pool[rng:NextInteger(1, #pool)]
		local walker = conveyor.SpawnOwned(playerState, char.Id, "none", 1)
		if walker then
			GameState.Notify(playerState, "Roda keberuntungan: kamu dapat " .. char.Name .. "!")
		else
			playerState.Money += 2000
			GameState.Notify(playerState, "Base penuh, hadiah diganti $2.000.")
		end
	elseif picked.Kind == "mutation" then
		local owned = {}
		for _, walker in pairs(playerState.Owned) do
			table.insert(owned, walker)
		end
		if #owned == 0 then
			playerState.Money += 2000
			GameState.Notify(playerState, "Belum ada brainrot untuk dimutasi, hadiah diganti $2.000.")
		else
			local walker = owned[rng:NextInteger(1, #owned)]
			walker.Mutation = picked.Mutation
			walker.Rate = BrainrotData.RateOf(walker.CharId, picked.Mutation) * (walker.FusionBonus or 1)
			conveyor.RefreshLabel(walker)
			GameState.Notify(playerState, "Roda keberuntungan: " .. BrainrotData.LabelOf(walker.CharId, walker.Mutation) .. "!")
		end
	end
	return true, "OK"
end

-- -- daily reward and quests -----------------------------------------------

function GameState.ClaimDaily(playerState)
	if playerState.LastDaily == todayString() then
		return false, "Hadiah harian sudah diklaim hari ini."
	end
	playerState.LastDaily = todayString()
	local reward = Config.DailyRewardBase + 500 * playerState.Rebirths
	playerState.Money += reward
	return true, "Hadiah harian $" .. tostring(reward) .. " masuk!"
end

function GameState.ClaimQuest(playerState, questId)
	local quest = nil
	for _, q in ipairs(Config.Quests) do
		if q.Id == questId then
			quest = q
			break
		end
	end
	if not quest then
		return false, "Misi tidak dikenal."
	end
	local progress = playerState.Quests[questId]
	if not progress then
		return false, "Misi tidak dikenal."
	end
	if progress.Claimed then
		return false, "Misi ini sudah diklaim."
	end
	if progress.Progress < quest.Target then
		return false, "Misi belum selesai."
	end
	progress.Claimed = true
	playerState.Money += quest.Reward
	return true, "Misi selesai! Hadiah $" .. tostring(quest.Reward) .. "."
end

-- -- guard pet (unique feature 2) ------------------------------------------

function GameState.BuyGuard(playerState)
	if playerState.Guard then
		return false, "Kamu sudah punya Kucing Pasar."
	end
	if playerState.Money < Config.Guard.Cost then
		return false, "Uangmu belum cukup untuk Kucing Pasar."
	end
	playerState.Money -= Config.Guard.Cost
	playerState.Guard = true
	return true, "Kucing Pasar sekarang menjaga basemu!"
end

-- -- positions --------------------------------------------------------------

function GameState.CharacterPosition(state)
	if state.IsBot then
		return state.BotPosition
	end
	local player = Players:GetPlayerByUserId(state.UserId)
	if not player then
		return nil
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	return root.Position
end

function GameState.BaseCenter(state)
	local base = world.Bases[state.BaseIndex]
	if not base then
		return nil
	end
	return base.Center
end

-- -- snapshots for the client -----------------------------------------------

function GameState.SnapshotFor(playerState)
	local owned = {}
	for _, walker in pairs(playerState.Owned) do
		table.insert(owned, {
			Id = walker.Id,
			CharId = walker.CharId,
			Mutation = walker.Mutation,
			Slot = walker.SlotIndex,
			Rate = walker.Rate,
		})
	end
	table.sort(owned, function(a, b)
		return a.Slot < b.Slot
	end)

	local walkers = {}
	for _, walker in pairs(GameState.WalkerById) do
		if walker.State == "Walking" then
			local char = BrainrotData.GetCharacter(walker.CharId)
			table.insert(walkers, {
				Id = walker.Id,
				CharId = walker.CharId,
				Mutation = walker.Mutation,
				Cost = char and char.Cost or 0,
				Rate = walker.Rate,
			})
		end
	end

	local board = {}
	for _, other in pairs(GameState.Players) do
		table.insert(board, { Name = other.Name, Money = other.Money, IsBot = other.IsBot })
	end
	table.sort(board, function(a, b)
		return a.Money > b.Money
	end)

	local quests = {}
	for _, q in ipairs(Config.Quests) do
		local p = playerState.Quests[q.Id]
		table.insert(quests, {
			Id = q.Id,
			Name = q.Name,
			Desc = q.Desc,
			Target = q.Target,
			Reward = q.Reward,
			Progress = p and p.Progress or 0,
			Claimed = p and p.Claimed or false,
		})
	end

	return {
		Money = playerState.Money,
		IncomePerSecond = GameState.IncomePerSecond(playerState),
		Rebirths = playerState.Rebirths,
		RebirthMultiplier = GameState.RebirthMultiplier(playerState),
		RebirthRequirement = GameState.RebirthRequirement(playerState),
		LifetimeEarned = playerState.LifetimeEarned,
		Upgrades = playerState.Upgrades,
		Owned = owned,
		MaxSlots = GameState.MaxSlots(playerState),
		Walkers = walkers,
		Leaderboard = board,
		Quests = quests,
		DailyAvailable = playerState.LastDaily ~= todayString(),
		WheelAvailableIn = math.max(0, Config.WheelCooldownSeconds - (now() - playerState.LastWheel)),
		Guard = playerState.Guard,
		BaseIndex = playerState.BaseIndex,
		LockedUntil = playerState.LockUntil,
		LockCooldownUntil = playerState.LockCooldownUntil,
		CurrentEvent = GameState.CurrentEvent and {
			Id = GameState.CurrentEvent.Id,
			Name = GameState.CurrentEvent.Name,
			Desc = GameState.CurrentEvent.Desc,
			EndsIn = math.max(0, GameState.CurrentEvent.EndsAt - now()),
		} or nil,
	}
end

function GameState.Notify(playerState, text)
	if playerState.IsBot then
		return
	end
	local player = Players:GetPlayerByUserId(playerState.UserId)
	if player then
		remotes.GameUpdate:FireClient(player, { Type = "Toast", Text = text })
	end
end

function GameState.Broadcast()
	for _, state in pairs(GameState.Players) do
		if not state.IsBot then
			local player = Players:GetPlayerByUserId(state.UserId)
			if player then
				local snap = GameState.SnapshotFor(state)
				snap.Type = "State"
				remotes.GameUpdate:FireClient(player, snap)
			end
		end
	end
end

-- -- joining and leaving ----------------------------------------------------

local function takeFreeBase()
	local taken = {}
	for _, state in pairs(GameState.Players) do
		taken[state.BaseIndex] = true
	end
	for i = 1, #Config.Bases do
		if not taken[i] then
			return i
		end
	end
	return 1
end

function GameState.PlayerAdded(player)
	local state = GameState.NewPlayerState(player.UserId, player.Name, false)
	state.BaseIndex = takeFreeBase()
	GameState.Players[player.UserId] = state
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.WalkSpeed = GameState.WalkSpeed(state)
		local root = character:WaitForChild("HumanoidRootPart")
		root.CFrame = CFrame.new(Config.SpawnPoint + Vector3.new(0, 2, 0))
	end)
	if player.Character then
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = GameState.WalkSpeed(state)
		end
	end
	task.spawn(function()
		GameState.Broadcast()
	end)
end

function GameState.PlayerRemoving(player)
	local state = GameState.Players[player.UserId]
	if not state then
		return
	end
	for walkerId, walker in pairs(state.Owned) do
		conveyor.Despawn(walker)
		state.Owned[walkerId] = nil
	end
	if state.Carrying then
		local walker = GameState.WalkerById[state.Carrying]
		if walker then
			GameState.DropCarried(state, walker)
		end
	end
	GameState.Players[player.UserId] = nil
	GameState.Broadcast()
end

-- -- action router ----------------------------------------------------------

local function handleAction(player, action, args)
	local state = GameState.Players[player.UserId]
	if not state then
		return
	end
	args = args or {}
	local ok, message = false, "Aksi tidak dikenal."
	if action == "BuyWalker" then
		local walker = GameState.WalkerById[args.WalkerId]
		ok, message = GameState.BuyWalker(state, walker)
	elseif action == "BuyUpgrade" then
		ok, message = GameState.BuyUpgrade(state, args.UpgradeId)
	elseif action == "Rebirth" then
		ok, message = GameState.DoRebirth(state)
	elseif action == "LockBase" then
		ok, message = GameState.LockBase(state)
	elseif action == "Slap" then
		ok, message = GameState.Slap(state)
	elseif action == "Fuse" then
		ok, message = GameState.Fuse(state, args.CharId)
	elseif action == "SpinWheel" then
		ok, message = GameState.SpinWheel(state)
	elseif action == "ClaimDaily" then
		ok, message = GameState.ClaimDaily(state)
	elseif action == "ClaimQuest" then
		ok, message = GameState.ClaimQuest(state, args.QuestId)
	elseif action == "BuyGuard" then
		ok, message = GameState.BuyGuard(state)
	end
	if not ok and message then
		GameState.Notify(state, message)
	end
	GameState.Broadcast()
end

-- -- main loops --------------------------------------------------------------

function GameState.Init(remotesModule, worldModule, conveyorModule)
	remotes = remotesModule
	world = worldModule
	conveyor = conveyorModule

	remotes.GameAction.OnServerEvent:Connect(handleAction)
	remotes.GetState.OnServerInvoke = function(player)
		local state = GameState.Players[player.UserId]
		if not state then
			return nil
		end
		local snap = GameState.SnapshotFor(state)
		snap.Type = "State"
		return snap
	end

	Players.PlayerAdded:Connect(GameState.PlayerAdded)
	Players.PlayerRemoving:Connect(GameState.PlayerRemoving)
	for _, player in ipairs(Players:GetPlayers()) do
		GameState.PlayerAdded(player)
	end

	-- One-second money tick.
	task.spawn(function()
		while true do
			task.wait(1)
			for _, state in pairs(GameState.Players) do
				local income = GameState.IncomePerSecond(state)
				if income > 0 then
					state.Money += income
					state.LifetimeEarned += income
					local quest = state.Quests.uang10k
					if quest and not quest.Claimed then
						quest.Progress += income
					end
				end
			end
			GameState.Broadcast()
		end
	end)

	-- Steal and deposit checks, four times a second.
	task.spawn(function()
		while true do
			task.wait(0.25)
			GameState.StealTick()
		end
	end)
end

function GameState.StealTick()
	for _, thief in pairs(GameState.Players) do
		local thiefPos = GameState.CharacterPosition(thief)
		if thiefPos then
			-- Deposit a carried brainrot when home.
			if thief.Carrying then
				local home = GameState.BaseCenter(thief)
				if home and (Vector3.new(thiefPos.X, 0, thiefPos.Z) - Vector3.new(home.X, 0, home.Z)).Magnitude < 13 then
					GameState.DepositCarried(thief)
				end
			else
				-- Try to grab a brainrot from somebody else's base.
				for _, walker in pairs(GameState.WalkerById) do
					if walker.State == "Owned" and walker.Owner ~= thief.UserId and walker.Model then
						local owner = GameState.Players[walker.Owner]
						local locked = owner and GameState.IsBaseLocked(owner)
						if not locked then
							local root = walker.Model.PrimaryPart
							if root and (root.Position - thiefPos).Magnitude < 4 then
								GameState.TrySteal(thief, walker)
								break
							end
						end
					end
				end
			end
		end
	end
end

return GameState
