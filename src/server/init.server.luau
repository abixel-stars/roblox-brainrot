--!nonstrict
-- init: boots Pasar Malam Brainrot. Remotes first, then the world,
-- then the conveyor, the state store, the bots, the events and the
-- guards, in that order, so every module can find the one before it.

local Remotes = require(script.Parent.Remotes)
local WorldBuilder = require(script.Parent.WorldBuilder)
local Conveyor = require(script.Parent.Conveyor)
local GameState = require(script.Parent.GameState)
local Bots = require(script.Parent.Bots)
local GameEvents = require(script.Parent.GameEvents)
local Guards = require(script.Parent.Guards)

local remotes = Remotes.Create()
local world = WorldBuilder.Build()

Conveyor.Init(GameState, world)
GameState.Init(remotes, world, Conveyor)
Bots.Init(GameState, world, Conveyor)
GameEvents.Init(GameState, Conveyor)
Guards.Init(GameState, world)

print("Pasar Malam Brainrot siap: conveyor jalan, 3 bot di pasar, event tiap beberapa menit.")
