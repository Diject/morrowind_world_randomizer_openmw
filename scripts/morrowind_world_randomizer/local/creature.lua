local objectType = require("scripts.morrowind_world_randomizer.generator.types").objectStrType

local actor = require("scripts.morrowind_world_randomizer.local.actor")(objectType.creature)

return {
    eventHandlers = {
        mwr_actor_setEquipment = actor.setEquipment,
        mwr_actor_randomizeInventory = actor.randomizeInventory,
        mwr_actor_setDynamicStats = actor.setDynamicStats,
        mwr_actor_randomizeSpells = actor.randmizeSpells,
    },
}
