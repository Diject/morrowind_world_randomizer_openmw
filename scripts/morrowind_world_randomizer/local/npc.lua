local objectType = require("scripts.morrowind_world_randomizer.generator.types").objectStrType

local self = require('openmw.self')
local Actor = require('openmw.types').Actor
local core = require('openmw.core')

local actor = require("scripts.morrowind_world_randomizer.local.actor")(objectType.npc)

return {
    eventHandlers = {
        mwr_actor_setEquipment = actor.setEquipment,
        mwr_actor_randomizeInventory = actor.randomizeInventory,
        mwr_actor_setDynamicStats = actor.setDynamicStats,
        mwr_actor_setAttributeBase = actor.setAttributeBase,
        mwr_actor_randomizeSkillBaseValues = actor.randomizeSkillBaseValues,
    },
}
