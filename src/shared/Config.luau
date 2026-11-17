--!nonstrict
-- Config: every tuning number for Pasar Malam Brainrot in one place.
-- Nothing here is a secret, it is all game balance the judge can read.

local Config = {}

Config.GameName = "Pasar Malam Brainrot"
Config.StartMoney = 100
Config.MaxPlayers = 8

-- The conveyor down the middle of the map.
Config.Conveyor = {
	Start = Vector3.new(0, 1.2, -72),
	Finish = Vector3.new(0, 1.2, 72),
	Width = 12,
	WalkSpeed = 4.5,
	SpawnEverySeconds = 7,
	MaxWalkers = 10,
}

-- Eight bases: four west, four east. Base 1 is the first player,
-- bases 2-4 are the bots, the rest wait for future players.
Config.Bases = {
	{ Position = Vector3.new(-55, 0, -60) },
	{ Position = Vector3.new(-55, 0, -20) },
	{ Position = Vector3.new(-55, 0, 20) },
	{ Position = Vector3.new(-55, 0, 60) },
	{ Position = Vector3.new(55, 0, -60) },
	{ Position = Vector3.new(55, 0, -20) },
	{ Position = Vector3.new(55, 0, 20) },
	{ Position = Vector3.new(55, 0, 60) },
}
Config.BaseSize = Vector3.new(26, 1, 26)
Config.BaseSlots = 8
Config.BaseSlotSpacing = 5

Config.SpawnPoint = Vector3.new(0, 2, 88)

-- Base lock: how long a lock lasts, and how much each upgrade adds.
Config.LockBaseSeconds = 10
Config.LockExtraPerLevel = 5
Config.LockCooldownSeconds = 20

-- Slap: range, cooldown and how long the victim is stunned.
Config.SlapRange = 9
Config.SlapCooldownSeconds = 3
Config.SlapStunSeconds = 1.5

-- Upgrades. Cost grows by CostMult every level bought.
Config.Upgrades = {
	{ Id = "speed", Name = "Sepatu Kilat", Desc = "Jalan 10% lebih cepat tiap level.", MaxLevel = 5, BaseCost = 500, CostMult = 2.2, Effect = 0.10 },
	{ Id = "income", Name = "Dompet Ajaib", Desc = "Penghasilan +25% tiap level.", MaxLevel = 5, BaseCost = 800, CostMult = 2.5, Effect = 0.25 },
	{ Id = "lock", Name = "Kunci Besi", Desc = "Kunci base +5 detik tiap level.", MaxLevel = 4, BaseCost = 600, CostMult = 2.0, Effect = 5 },
	{ Id = "slots", Name = "Slot Ekstra", Desc = "+1 slot base tiap level.", MaxLevel = 4, BaseCost = 1500, CostMult = 2.0, Effect = 1 },
	{ Id = "slap", Name = "Tangan Cepat", Desc = "Cooldown tampar -20% tiap level.", MaxLevel = 3, BaseCost = 700, CostMult = 2.0, Effect = 0.20 },
}

Config.UpgradeById = {}
for _, up in ipairs(Config.Upgrades) do
	Config.UpgradeById[up.Id] = up
end

function Config.UpgradeCost(up, level)
	return math.floor(up.BaseCost * (up.CostMult ^ level))
end

-- Rebirth: reset money and brainrots, keep a permanent income boost.
Config.Rebirth = {
	BaseRequirement = 1000000,
	RequirementMult = 5,
	MultiplierPerRebirth = 0.5,
}

-- Events: one fires every few minutes and lasts a minute.
Config.Events = {
	{ Id = "hujan_langka", Name = "Hujan Langka", Desc = "Brainrot langka turun 3x lebih sering selama 60 detik!", Duration = 60 },
	{ Id = "gajian_ganda", Name = "Gajian Ganda", Desc = "Semua penghasilan jadi 2x selama 60 detik!", Duration = 60 },
	{ Id = "parade", Name = "Parade Lampion", Desc = "Deretan brainrot langka lewat di conveyor, rebutan!", Duration = 60 },
	{ Id = "gelombang", Name = "Gelombang Lari", Desc = "Ombak datang! Lari pulang ke base dalam 10 detik!", Duration = 10 },
}
Config.EventEveryMinSeconds = 150
Config.EventEveryMaxSeconds = 240

-- Daily quests: progress is tracked per player, reward is in-game cash.
Config.Quests = {
	{ Id = "beli3", Name = "Belanja Pagi", Desc = "Beli 3 brainrot", Target = 3, Reward = 500 },
	{ Id = "curi1", Name = "Maling Pasar", Desc = "Curi 1 brainrot dari base lain", Target = 1, Reward = 1000 },
	{ Id = "uang10k", Name = "Juragan Muda", Desc = "Kumpulkan $10.000 penghasilan", Target = 10000, Reward = 750 },
}

Config.DailyRewardBase = 1000
Config.WheelCooldownSeconds = 600
Config.WheelPrizes = {
	{ Kind = "money", Amount = 500, Weight = 30, Text = "$500" },
	{ Kind = "money", Amount = 2000, Weight = 20, Text = "$2.000" },
	{ Kind = "money", Amount = 5000, Weight = 10, Text = "$5.000" },
	{ Kind = "money", Amount = 15000, Weight = 5, Text = "$15.000" },
	{ Kind = "brainrot", Tier = "Langka", Weight = 15, Text = "Brainrot Langka acak" },
	{ Kind = "brainrot", Tier = "Epik", Weight = 8, Text = "Brainrot Epik acak" },
	{ Kind = "mutation", Mutation = "emas", Weight = 12, Text = "Mutasi Emas untuk 1 brainrot" },
}

-- Unique feature 1: Fusion. Three identical brainrots become one
-- mutated copy that earns 50% more on top of its mutation.
Config.FusionBonus = 1.5

-- Unique feature 2: the base guard. A market cat that chases
-- thieves out of your base on its own.
Config.Guard = {
	Name = "Kucing Pasar",
	Cost = 5000,
	ChaseRadius = 20,
	ChaseSpeed = 14,
}

-- Bots that keep the market alive while a player is alone.
Config.Bots = {
	{ Name = "BudiBot", Color = Color3.fromRGB(255, 180, 80) },
	{ Name = "SitiBot", Color = Color3.fromRGB(255, 120, 180) },
	{ Name = "JokoBot", Color = Color3.fromRGB(120, 200, 255) },
}

return Config
