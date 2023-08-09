local objectType = require("scripts.morrowind_world_randomizer.generator.types").objectStrType

local actor = require("scripts.morrowind_world_randomizer.local.actor")(objectType.creature)
local self = require('openmw.self')
local core = require('openmw.core')

local function deactivate()
    if self.object.count == 0 then
        core.sendGlobalEvent("mwr_deactivateObject", {object = self.object})
    end
end

return {
    engineHandlers = {
        onInactive = deactivate,
    },
    eventHandlers = {
        mwr_actor_setEquipment = actor.setEquipment,
        mwr_actor_randomizeInventory = actor.randomizeInventory,
        mwr_actor_setDynamicStats = actor.setDynamicStats,
        mwr_actor_randomizeSpells = actor.randmizeSpells,
    },
}
