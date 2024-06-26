local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)

local InjectLifecycleSignals =
	require(Globals.Shared.Modules.InjectLifecycleSignals)

local Character = {}

function Character:add(entity, character)
	return character
end

return Globals.World.factory(InjectLifecycleSignals(Character))
