local objectType = require("scripts.morrowind_world_randomizer.generator.types").objectStrType

local self = require('openmw.self')
local Actor = require('openmw.types').Actor
local core = require('openmw.core')

local this = {}
this.objectType = nil

function this.randomizeInventory(data)
    if not data or not data.config then return end
    if data.config.item.randomize then
        local equipment = Actor.getEquipment(self)
        local slotById = {}
        for i, item in pairs(equipment) do
            slotById[item.id] = i
        end
        local items = {}
        for i, item in pairs(Actor.inventory(self):getAll()) do
            local advItemData = data.itemsData.items[item.recordId]
            if advItemData then
                table.insert(items, {item = item, advData = advItemData})
                local slot = slotById[item.id]
                if slot then
                    equipment[slot] = nil
                    items[#items].slot = slot
                end
            end
        end
        Actor.setEquipment(self, equipment)
        core.sendGlobalEvent("mwr_updateInventory", {items = items, object = self.object, objectType = this.objectType})
    end
end

function this.setEquipment(equipment)
    Actor.setEquipment(self, equipment)
end

return function(type)
    this.objectType = type
    return this
end
