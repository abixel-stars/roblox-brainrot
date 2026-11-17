--!nonstrict
-- ClientFx: the little sounds and bursts the client plays. Every
-- sound id is a built-in Roblox sound, no outside asset is needed.

local SoundService = game:GetService("SoundService")

local ClientFx = {}

local function makeSound(name, soundId, volume)
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = soundId
	sound.Volume = volume
	sound.Parent = SoundService
	return sound
end

function ClientFx.Init()
	ClientFx.BuySound = makeSound("BuyPing", "rbxasset://sounds/electronicpingshort.wav", 0.6)
	ClientFx.CoinSound = makeSound("CoinPing", "rbxasset://sounds/electronicpingshort.wav", 0.35)
	ClientFx.ErrorSound = makeSound("ErrorBuzz", "rbxasset://sounds/electronicpingshort.wav", 0.5)
	ClientFx.ErrorSound.PlaybackSpeed = 0.6
end

function ClientFx.PlayBuy()
	if ClientFx.BuySound then
		ClientFx.BuySound:Play()
	end
end

function ClientFx.PlayCoin()
	if ClientFx.CoinSound then
		ClientFx.CoinSound:Play()
	end
end

function ClientFx.PlayError()
	if ClientFx.ErrorSound then
		ClientFx.ErrorSound:Play()
	end
end

-- A small gold burst at a world position (buy, steal, event).
function ClientFx.Burst(position)
	local attachment = Instance.new("Attachment")
	attachment.WorldPosition = position
	attachment.Parent = game:GetService("Workspace").Terrain
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 210, 80))
	emitter.Size = NumberSequence.new(0.6)
	emitter.Lifetime = NumberRange.new(0.4, 0.8)
	emitter.Rate = 60
	emitter.Speed = NumberRange.new(6, 12)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Parent = attachment
	emitter:Emit(24)
	task.delay(1.5, function()
		attachment:Destroy()
	end)
end

return ClientFx
