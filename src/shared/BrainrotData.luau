--!nonstrict
-- BrainrotData: the whole cast of Pasar Malam Brainrot.
-- Every character, rarity tier and mutation lives here so the server
-- and the client always agree on names, prices and income rates.

local BrainrotData = {}

-- Rarity ladder, cheapest to rarest. Weight controls how often a
-- character of this tier shows up on the conveyor.
BrainrotData.Tiers = {
	{ Name = "Biasa", Color = Color3.fromRGB(150, 200, 120), Weight = 34, Order = 1 },
	{ Name = "Lumayan", Color = Color3.fromRGB(110, 190, 230), Weight = 24, Order = 2 },
	{ Name = "Langka", Color = Color3.fromRGB(90, 140, 255), Weight = 16, Order = 3 },
	{ Name = "Epik", Color = Color3.fromRGB(170, 110, 240), Weight = 11, Order = 4 },
	{ Name = "Legendaris", Color = Color3.fromRGB(250, 190, 60), Weight = 7, Order = 5 },
	{ Name = "Mistis", Color = Color3.fromRGB(255, 90, 160), Weight = 4, Order = 6 },
	{ Name = "Dewa", Color = Color3.fromRGB(255, 230, 120), Weight = 2, Order = 7 },
	{ Name = "Kosmik", Color = Color3.fromRGB(120, 240, 255), Weight = 1, Order = 8 },
	{ Name = "Rahasia", Color = Color3.fromRGB(255, 80, 80), Weight = 1, Order = 9 },
}

BrainrotData.TierByName = {}
for _, tier in ipairs(BrainrotData.Tiers) do
	BrainrotData.TierByName[tier.Name] = tier
end

-- The cast. Body is the main colour of the 3D model, Shape picks the
-- body silhouette the factory builds, Trim is the accent colour,
-- Accessory is the extra part the factory sticks on top.
-- Id, Name, Tier, Cost, RatePerSecond, Body, Trim, Shape, Accessory
BrainrotData.Characters = {
	{ Id = "tahu_goyang", Name = "Tahu Bulat Goyang", Tier = "Biasa", Cost = 50, Rate = 1, Body = Color3.fromRGB(250, 240, 200), Trim = Color3.fromRGB(230, 180, 60), Shape = "Round", Accessory = "None" },
	{ Id = "es_teh_nangis", Name = "Es Teh Manis Menangis", Tier = "Biasa", Cost = 100, Rate = 2, Body = Color3.fromRGB(200, 120, 60), Trim = Color3.fromRGB(240, 240, 240), Shape = "Tall", Accessory = "None" },
	{ Id = "gorengan_terbang", Name = "Gorengan Terbang", Tier = "Lumayan", Cost = 300, Rate = 6, Body = Color3.fromRGB(210, 140, 40), Trim = Color3.fromRGB(255, 220, 120), Shape = "Flat", Accessory = "Wings" },
	{ Id = "sate_galau", Name = "Sate Ayam Galau", Tier = "Lumayan", Cost = 500, Rate = 10, Body = Color3.fromRGB(180, 110, 50), Trim = Color3.fromRGB(90, 60, 30), Shape = "Tall", Accessory = "Hat" },
	{ Id = "bakso_beranak", Name = "Bakso Beranak", Tier = "Langka", Cost = 1200, Rate = 25, Body = Color3.fromRGB(200, 150, 110), Trim = Color3.fromRGB(255, 120, 120), Shape = "Round", Accessory = "None" },
	{ Id = "mie_sakti", Name = "Mie Ayam Sakti", Tier = "Langka", Cost = 2000, Rate = 40, Body = Color3.fromRGB(250, 210, 90), Trim = Color3.fromRGB(200, 60, 60), Shape = "Tall", Accessory = "Hat" },
	{ Id = "nasi_padang", Name = "Nasi Padang Raksasa", Tier = "Epik", Cost = 5000, Rate = 100, Body = Color3.fromRGB(245, 235, 210), Trim = Color3.fromRGB(220, 60, 50), Shape = "Block", Accessory = "Crown" },
	{ Id = "kerupuk_naga", Name = "Kerupuk Naga Api", Tier = "Epik", Cost = 8000, Rate = 160, Body = Color3.fromRGB(255, 120, 60), Trim = Color3.fromRGB(255, 220, 80), Shape = "Flat", Accessory = "Wings" },
	{ Id = "rendang_emas", Name = "Rendang Emas 24 Karat", Tier = "Legendaris", Cost = 20000, Rate = 400, Body = Color3.fromRGB(255, 215, 90), Trim = Color3.fromRGB(150, 90, 20), Shape = "Block", Accessory = "Crown" },
	{ Id = "soto_terbang", Name = "Soto Ayam Terbang", Tier = "Legendaris", Cost = 30000, Rate = 600, Body = Color3.fromRGB(255, 230, 150), Trim = Color3.fromRGB(120, 200, 90), Shape = "Round", Accessory = "Wings" },
	{ Id = "durian_hantu", Name = "Durian Raja Hantu", Tier = "Mistis", Cost = 75000, Rate = 1500, Body = Color3.fromRGB(120, 200, 70), Trim = Color3.fromRGB(200, 40, 200), Shape = "Round", Accessory = "Crown" },
	{ Id = "cendol_waktu", Name = "Es Cendol Waktu", Tier = "Mistis", Cost = 120000, Rate = 2400, Body = Color3.fromRGB(80, 200, 150), Trim = Color3.fromRGB(255, 255, 255), Shape = "Tall", Accessory = "Hat" },
	{ Id = "kopi_dewa", Name = "Kopi Tubruk Dewa", Tier = "Dewa", Cost = 300000, Rate = 6000, Body = Color3.fromRGB(90, 55, 30), Trim = Color3.fromRGB(255, 230, 120), Shape = "Tall", Accessory = "Crown" },
	{ Id = "martabak_abadi", Name = "Martabak Manis Abadi", Tier = "Dewa", Cost = 500000, Rate = 10000, Body = Color3.fromRGB(200, 140, 60), Trim = Color3.fromRGB(255, 200, 220), Shape = "Flat", Accessory = "Crown" },
	{ Id = "bintang_goreng", Name = "Bintang Goreng Galaksi", Tier = "Kosmik", Cost = 1200000, Rate = 24000, Body = Color3.fromRGB(140, 200, 255), Trim = Color3.fromRGB(255, 240, 140), Shape = "Round", Accessory = "Wings" },
	{ Id = "komet_cilok", Name = "Komet Cilok Angkasa", Tier = "Kosmik", Cost = 2000000, Rate = 40000, Body = Color3.fromRGB(180, 140, 255), Trim = Color3.fromRGB(255, 140, 200), Shape = "Round", Accessory = "Wings" },
	{ Id = "nasi_pangeran", Name = "Nasi Goreng Pangeran Malam", Tier = "Rahasia", Cost = 5000000, Rate = 100000, Body = Color3.fromRGB(60, 40, 90), Trim = Color3.fromRGB(255, 200, 60), Shape = "Block", Accessory = "Crown" },
	{ Id = "ratu_lampion", Name = "Ratu Lampion Terakhir", Tier = "Rahasia", Cost = 10000000, Rate = 250000, Body = Color3.fromRGB(255, 90, 90), Trim = Color3.fromRGB(255, 220, 120), Shape = "Tall", Accessory = "Crown" },
}

BrainrotData.ById = {}
for _, char in ipairs(BrainrotData.Characters) do
	BrainrotData.ById[char.Id] = char
end

-- Mutations. Chance is the percent rolled when a brainrot spawns.
BrainrotData.Mutations = {
	{ Id = "none", Name = "Biasa", Multiplier = 1, Color = Color3.fromRGB(255, 255, 255), Chance = 0 },
	{ Id = "emas", Name = "Emas", Multiplier = 2, Color = Color3.fromRGB(255, 215, 0), Chance = 12 },
	{ Id = "beku", Name = "Beku", Multiplier = 4, Color = Color3.fromRGB(150, 220, 255), Chance = 4 },
	{ Id = "api", Name = "Api", Multiplier = 3, Color = Color3.fromRGB(255, 100, 30), Chance = 6 },
	{ Id = "pelangi", Name = "Pelangi", Multiplier = 5, Color = Color3.fromRGB(255, 120, 220), Chance = 2 },
}

BrainrotData.MutationById = {}
for _, mut in ipairs(BrainrotData.Mutations) do
	BrainrotData.MutationById[mut.Id] = mut
end

function BrainrotData.GetCharacter(id)
	return BrainrotData.ById[id]
end

function BrainrotData.GetTier(name)
	return BrainrotData.TierByName[name]
end

-- Weighted random pick of a character for the conveyor.
function BrainrotData.RollCharacter(rng)
	local total = 0
	for _, tier in ipairs(BrainrotData.Tiers) do
		total += tier.Weight
	end
	local roll = rng:NextNumber(0, total)
	local acc = 0
	local pickedTier = BrainrotData.Tiers[1]
	for _, tier in ipairs(BrainrotData.Tiers) do
		acc += tier.Weight
		if roll <= acc then
			pickedTier = tier
			break
		end
	end
	local pool = {}
	for _, char in ipairs(BrainrotData.Characters) do
		if char.Tier == pickedTier.Name then
			table.insert(pool, char)
		end
	end
	return pool[rng:NextInteger(1, #pool)]
end

-- Roll a mutation for a fresh spawn. Returns the mutation id.
function BrainrotData.RollMutation(rng)
	local roll = rng:NextNumber(0, 100)
	local acc = 0
	for _, mut in ipairs(BrainrotData.Mutations) do
		if mut.Id == "none" then
			continue
		end
		acc += mut.Chance
		if roll <= acc then
			return mut.Id
		end
	end
	return "none"
end

-- The income a brainrot earns per second with its mutation applied.
function BrainrotData.RateOf(charId, mutationId)
	local char = BrainrotData.ById[charId]
	if not char then
		return 0
	end
	local mut = BrainrotData.MutationById[mutationId] or BrainrotData.MutationById.none
	return char.Rate * mut.Multiplier
end

function BrainrotData.LabelOf(charId, mutationId)
	local char = BrainrotData.ById[charId]
	if not char then
		return "?"
	end
	local mut = BrainrotData.MutationById[mutationId] or BrainrotData.MutationById.none
	if mut.Id == "none" then
		return char.Name
	end
	return mut.Name .. " " .. char.Name
end

return BrainrotData
