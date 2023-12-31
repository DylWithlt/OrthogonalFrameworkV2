local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Globals = require(ReplicatedStorage.Shared.Globals)
local Net = require(Globals.Packages.Net)

local Schedules = require(Globals.Shared.Modules.Schedules)

local ClicksComponent = require(Globals.Server.Components.ClicksComponent)

local Profiles = require(Globals.Server.Modules.Profiles)

local ClicksSystem = {
	id = "clicks",
	defaultData = {
		clicks = 0,
	},
}

local function onPlayerClicked(player)
	local component = ClicksComponent.get(player)

	if not component then
		return
	end

	component.clicks += 1
	if component.clicks > 40 then
		ClicksComponent.remove(player)
	end
end

local function onInit()
	Profiles.addDefaultData(ClicksSystem.id, ClicksSystem.defaultData)
end

local function onBoot()
	Net:Connect("Clicked", onPlayerClicked)
end

return {
	init = Schedules.init.job(onInit),
	boot = Schedules.boot.job(onBoot),
}
