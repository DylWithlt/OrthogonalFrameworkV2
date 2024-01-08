local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TableValue = require(ReplicatedStorage.Packages.TableValue)

local Globals = require(ReplicatedStorage.Shared.Globals)
local LemonSignal = require(Globals.Packages.LemonSignal)
local World = require(ReplicatedStorage.Shared.Modules.World)
local Schedules = require(ReplicatedStorage.Shared.Modules.Schedules)
local Profiles = require(Globals.Local.Modules.Profiles)

local profileId = "Money"
Schedules.init.job(function(profileTemplate)
	Profiles.setDefaultData(profileId, {
		amount = 0,
	})
end)

local MoneyComponent = {}
MoneyComponent.addedSignal = LemonSignal.new()
MoneyComponent.changedSignal = LemonSignal.new()
MoneyComponent.removedSignal = LemonSignal.new()

function MoneyComponent:add(entity: number, profile: {})
	local component = TableValue.new(profile.Data[profileId])

	function component.Changed(index, value)
		self.changedSignal:Fire(entity, component)
	end

	self.addedSignal:Fire(entity, component)

	return component
end

function MoneyComponent:remove(entity: number)
	self.removedSignal:Fire(entity)
end

export type Type = typeof(MoneyComponent.add(...))
MoneyComponent.Id = "Money"

return World.factory(MoneyComponent)
