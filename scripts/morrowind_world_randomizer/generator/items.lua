local types = require('openmw.types')
local world = require('openmw.world')
local core = require('openmw.core')
local log = require("scripts.morrowind_world_randomizer.utils.log")
local generatorData = require("scripts.morrowind_world_randomizer.generator.data")
local tableLib = require("scripts.morrowind_world_randomizer.utils.table")
local objectIds = require("scripts.morrowind_world_randomizer.generator.types").objectStrType

---@class mwr.itemPosData
---@field pos integer
---@field type string
---@field subType string
---@field isArtifact boolean|nil
---@field isDangerous boolean|nil

---@class mwr.itemsData
---@field items table<string, mwr.itemPosData>
---@field groups table<string, table<string>>

local this = {}

local dangerousEnchantIds = {}

for _, enchant in pairs(core.magic.enchantments) do
    if enchant.type == core.magic.ENCHANTMENT_TYPE.ConstantEffect then
        for _, eff in pairs(enchant.effects) do
            if generatorData.forbiddenEffectsIds[eff.effect.id] then
                dangerousEnchantIds[enchant.id:lower()] = true
                break
            end
        end
    end
end

local function checkMajorRequirements(id, scriptId)
    if (scriptId == "" or generatorData.scriptWhiteList[scriptId]) and not generatorData.forbiddenIds[id] then
        return true
    end
    return false
end

local function checkMinorRequirements(item, objectType)
    if not generatorData.forbiddenModels[item.model:lower() or "0"] and item.icon ~= "" and
            not (objectType == objectIds.book and item.enchant == "") then
        return true
    end
    return false
end

---@param smart boolean
---@return mwr.itemsData
function this.generateData(smart)
    ---@type mwr.itemsData
    local out = {groups = {}, items = {}}

    local recordData = {
        [objectIds.alchemy] = {types.Potion, "value"},
        [objectIds.apparatus] = {types.Apparatus, "value"},
        [objectIds.armor] = {types.Armor, "value"},
        [objectIds.clothing] = {types.Clothing, "value"},
        [objectIds.ingredient] = {types.Ingredient, "value"},
        [objectIds.lockpick] = {types.Lockpick, "value"},
        [objectIds.probe] = {types.Probe, "value"},
        [objectIds.weapon] = {types.Weapon, "value"},
        [objectIds.book] = {types.Book, "value"},
        -- [objectIds.miscItem] = {types.Miscellaneous, "value"},
    }

    local dangerousItems = {}

    if smart then
        local itemCount = {}
        local processItems = function(data)
            for _, item in pairs(data) do
                local id = item.recordId:lower()
                if not itemCount[id] then
                    itemCount[id] = 1
                else
                    itemCount[id] = itemCount[id] + 1
                end
            end
        end
        for _, cell in pairs(world.cells) do
            local npcs = cell:getAll(types.NPC) or {}
            local creatures = cell:getAll(types.Creature) or {}
            local containers = cell:getAll(types.Container) or {}
            for groupId, records in pairs(recordData) do
                processItems(cell:getAll(records[1]))
                for _, actor in pairs(npcs) do
                    processItems(types.Actor.inventory(actor):getAll(records[1]))
                end
                for _, actor in pairs(creatures) do
                    processItems(types.Actor.inventory(actor):getAll(records[1]))
                end
                for _, container in pairs(containers) do
                    processItems(types.Container.content(container):getAll(records[1]))
                end
            end
        end
        for groupId, records in pairs(recordData) do
            if not out.groups[groupId] then out.groups[groupId] = {} end
            local data = out.groups[groupId]
            for _, item in pairs(records[1].records) do
                local scriptId = item.mwscript:lower()
                local itemId = item.id:lower()
                local count = itemCount[itemId]
                if checkMajorRequirements(itemId, scriptId) and checkMinorRequirements(item, groupId) and count then
                    local type = tostring(item.type or "0")
                    if not data[type] then data[type] = {} end
                    table.insert(data[type], itemId)
                    if item.enchant and item.enchant ~= "" and dangerousEnchantIds[item.enchant:lower()] then
                        dangerousItems[itemId] = true
                    end
                end
            end
            table.sort(data, function(a, b) return a[records[2]] < b[records[2]] end)
        end
    else
        for groupId, records in pairs(recordData) do
            if not out.groups[groupId] then out.groups[groupId] = {} end
            local data = out.groups[groupId]
            for _, item in pairs(records[1].records) do
                local scriptId = item.mwscript:lower()
                local itemId = item.id:lower()
                if checkMajorRequirements(itemId, scriptId) and checkMinorRequirements(item, groupId) then
                    local type = tostring(item.type or "0")
                    if not data[type] then data[type] = {} end
                    table.insert(data[type], itemId)
                    if item.enchant and item.enchant ~= "" and dangerousEnchantIds[item.enchant:lower()] then
                        dangerousItems[itemId] = true
                    end
                end
            end
            table.sort(data, function(a, b) return a[records[2]] < b[records[2]] end)
        end
    end

    for groupId, group in pairs(out.groups) do
        local count = 0
        for subType, ids in pairs(group) do
            for pos, id in pairs(ids) do
                count = count + 1
                ---@type mwr.itemPosData
                local data = {pos = pos, type = groupId, subType = subType}
                if generatorData.obtainableArtifacts[id] then data.isArtifact = true end
                if dangerousItems[id] then data.isDangerous = true end
                out.items[id] = data
            end
        end
        log(groupId, count)
    end

    return out
end

return this