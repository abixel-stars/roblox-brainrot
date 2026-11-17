--!nonstrict
-- Game client: boots the UI, asks the server for the first state,
-- and keeps the HUD fresh from the server's updates. Lock (L) and
-- slap (F) are bound through ContextActionService so the default
-- camera scripts never swallow them.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiBuilder = require(script.Parent.UiBuilder)
local ClientFx = require(script.Parent.ClientFx)

local remotes = ReplicatedStorage:WaitForChild("BrainrotRemotes")
local GameAction = remotes:WaitForChild("GameAction")
local GameUpdate = remotes:WaitForChild("GameUpdate")
local GetState = remotes:WaitForChild("GetState")

ClientFx.Init()

local function sendAction(name, args)
	GameAction:FireServer(name, args or {})
end

UiBuilder.Build(sendAction)

-- First state, with retries while the server is still waking up.
task.spawn(function()
	local snap = nil
	for _ = 1, 20 do
		local ok, result = pcall(function()
			return GetState:InvokeServer()
		end)
		if ok and result then
			snap = result
			break
		end
		task.wait(0.5)
	end
	if snap then
		UiBuilder.Refresh(snap)
	else
		UiBuilder.Toast("Server belum menjawab, coba lagi sebentar lagi.")
	end
end)

GameUpdate.OnClientEvent:Connect(function(payload)
	if not payload then
		return
	end
	if payload.Type == "State" then
		UiBuilder.Refresh(payload)
	elseif payload.Type == "Toast" then
		UiBuilder.Toast(payload.Text)
		ClientFx.PlayCoin()
	end
end)

ContextActionService:BindAction("LockBase", function(_, inputState, _)
	if inputState == Enum.UserInputState.Begin then
		sendAction("LockBase", {})
	end
end, false, Enum.KeyCode.L)

ContextActionService:BindAction("Slap", function(_, inputState, _)
	if inputState == Enum.UserInputState.Begin then
		sendAction("Slap", {})
	end
end, false, Enum.KeyCode.F)

Players.LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	local snap = nil
	local ok, result = pcall(function()
		return GetState:InvokeServer()
	end)
	if ok and result then
		snap = result
		UiBuilder.Refresh(snap)
	end
end)

print("Pasar Malam Brainrot: client siap.")
