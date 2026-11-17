--!nonstrict
-- Remotes: the two RemoteEvents and one RemoteFunction the client
-- and the server talk through. Everything the client asks for goes
-- through GameAction; everything the server pushes goes through
-- GameUpdate; the first full state comes back from GetState.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

function Remotes.Create()
	local folder = Instance.new("Folder")
	folder.Name = "BrainrotRemotes"
	folder.Parent = ReplicatedStorage

	local action = Instance.new("RemoteEvent")
	action.Name = "GameAction"
	action.Parent = folder

	local update = Instance.new("RemoteEvent")
	update.Name = "GameUpdate"
	update.Parent = folder

	local getState = Instance.new("RemoteFunction")
	getState.Name = "GetState"
	getState.Parent = folder

	Remotes.Folder = folder
	Remotes.GameAction = action
	Remotes.GameUpdate = update
	Remotes.GetState = getState
	return Remotes
end

return Remotes
