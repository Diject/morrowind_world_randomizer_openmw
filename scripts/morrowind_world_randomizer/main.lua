local log = require("scripts.morrowind_world_randomizer.utils.log")

local localConfig = require("scripts.morrowind_world_randomizer.config.local")
local localStorage = require("scripts.morrowind_world_randomizer.storage.local")
local globalStorage = require("scripts.morrowind_world_randomizer.storage.global")

local random = require("scripts.morrowind_world_randomizer.utils.random")
local advString = require("scripts.morrowind_world_randomizer.utils.string")
local tableLib = require("scripts.morrowind_world_randomizer.utils.table")

local async = require('openmw.async')
local types = require('openmw.types')
local world = require("openmw.world")
local util = require("openmw.util")
local core = require("openmw.core")
local time = require('openmw_aux.time')
local Activation = require('openmw.interfaces').Activation

local objectType = require("scripts.morrowind_world_randomizer.generator.types").objectStrType

local cellLib = require("scripts.morrowind_world_randomizer.cell")

---@type mwr.globalStorageData
local globalData = nil

local function isReadyForRandomization(ref, once)
    local tm = localStorage.getRefRandomizationTimestamp(ref)
    if tm and once then
        return false
    elseif tm and (localConfig.data.randomizeOnce or tm + localConfig.data.randomizeAfter > world.getSimulationTime()) then
        return false
    end
    return true
end

local function createItem(id, oldItem, advData, skipOwner)
    local new = world.createObject(id, advData and advData.count or oldItem.count)
    if not skipOwner then
        new.ownerFactionId = oldItem.ownerFactionId
        new.ownerFactionRank = oldItem.ownerFactionRank
        new.ownerRecordId = oldItem.ownerRecordId
    end
    return new
end

local function initData()
    if globalStorage.init() then
        globalStorage.data.version = globalStorage.version
        local statics = require("scripts.morrowind_world_randomizer.generator.statics")
        globalStorage.data.treesData = statics.rebuildRocksTreesData(require("scripts.morrowind_world_randomizer.data.TreesData_TR"))
        globalStorage.data.rocksData = statics.rebuildRocksTreesData(require("scripts.morrowind_world_randomizer.data.RocksData_TR"))
        -- globalStorage.data.treesData = require("scripts.morrowind_world_randomizer.generator.statics").generateTreeData()
        -- globalStorage.data.rocksData = require("scripts.morrowind_world_randomizer.generator.statics").generateRockData()
        globalStorage.data.itemsData = require("scripts.morrowind_world_randomizer.generator.items").generateData(false)
        globalStorage.data.floraData = statics.generateFloraData()
        globalStorage.data.herbsData = require("scripts.morrowind_world_randomizer.generator.container").generateHerbData()
        globalStorage.data.creaturesData = require("scripts.morrowind_world_randomizer.generator.creature").generateCreatureData()
        globalStorage.saveGameFilesDataToStorage()
        globalStorage.save()
    end
    globalData = globalStorage.data
end

local function onActorActive(actor)
    async:newUnsavableSimulationTimer(1, function()
        if not actor or not actor:isValid() then return end
        local readyForRandomization = isReadyForRandomization(actor, true)
        if actor.type == types.Creature and localConfig.data.creature.randomize and not actor.contentFile and
                globalStorage.data.creaturesData.objects[actor.recordId] and readyForRandomization and
                types.Actor.stats.dynamic.health(actor).current > 0 then
            local config = localConfig.getConfigTableByObjectType(objectType.creature)
            local actorData = globalStorage.data.creaturesData.objects[actor.recordId]
            if config then
                local group
                if config.byType then
                    group = globalStorage.data.creaturesData.groups[actorData.type]
                else
                    group = {}
                    for _, grp in pairs(globalStorage.data.creaturesData.groups) do
                        tableLib.addTableValuesToTable(group, grp)
                    end
                end
                local newActor = group[random.getRandom(actorData.pos, #group, config.rregion.min, config.rregion.max)]
                local new = world.createObject(newActor)
                localStorage.setRefRandomizationTimestamp(new)
                new:teleport(actor.cell, actor.position, {onGround = true, rotation = actor.rotation})
                localStorage.setCreatureParentIdData(new, actor)
                actor.enabled = false
            end
        end
        if readyForRandomization or isReadyForRandomization(actor) then
            if actor.type == types.NPC and localConfig.data.npc.item.randomize then
                local config = localConfig.getConfigTableByObjectType(objectType.npc)
                localStorage.setRefRandomizationTimestamp(actor)
                actor:sendEvent("mwr_npc_randomizeInventory", {itemsData = globalData.itemsData, config = config})
            elseif actor.type == types.Creature and localConfig.data.creature.item.randomize then
                local config = localConfig.getConfigTableByObjectType(objectType.creature)
                localStorage.setRefRandomizationTimestamp(actor)
                actor:sendEvent("mwr_creature_randomizeInventory", {itemsData = globalData.itemsData, config = config})
            end
        end
    end)
end

-- fix for created creatures
local cellsForCheck = {}
time.runRepeatedly(function()
    for cell, _ in pairs(cellsForCheck) do
        for _, actor in pairs(cell:getAll(types.Creature)) do
            if localStorage.isIdInDeletionList(actor.id) then
                localStorage.removeIdFromDeletionList(actor.id)
                log("Parent actor removed", actor)
                actor:remove()
            end
        end
        cellsForCheck[cell] = nil
    end
end, 30 * time.second, { initialDelay = 10 * time.second })

local function onObjectActive(object)
    cellLib.randomize(object.cell)
    cellsForCheck[object.cell] = true
end

local function onInit()
    initData()
    cellLib.init(globalData, localConfig, localStorage)
end

local function onSave()
    return {config = localConfig.data, storage = localStorage.data}
end

local function onLoad(data)
    -- localConfig.loadData(data.config)
    localStorage.loadData(data.storage)
    if not globalData then
        initData()
        cellLib.init(globalData, localConfig, localStorage)
    end
end

return {
    engineHandlers = {
        onActorActive = async:callback(onActorActive),
        onObjectActive = onObjectActive,
        onInit = onInit,
        onSave = onSave,
        onLoad = onLoad,
    },
    eventHandlers = {
        mwr_updateInventory = async:callback(function(data)
            local config = localConfig.getConfigTableByObjectType(data.objectType)
            if config then
                local equipment = (data.objectType == objectType.npc or data.objectType == objectType.creature) and types.Actor.getEquipment(data.object) or {}
                for _, itemData in pairs(data.items) do
                    ---@type mwr.itemPosData
                    local advData = itemData.advData or globalData.itemsData.items[itemData.item.recordId]
                    if not advData then goto continue end
                    local grp = globalData.itemsData.groups[advData.type][advData.subType]
                    local newId = grp[random.getRandom(advData.pos, #grp, config.item.rregion.min, config.item.rregion.max)]
                    local obj = createItem(newId, itemData.item, itemData, data.objectType == objectType.creature)
                    log("object ", data.object, "new item ", obj, "old item ", itemData.item, "count ", obj.count)
                    localStorage.setRefRandomizationTimestamp(obj)
                    local inventory = (data.objectType == objectType.npc or data.objectType == objectType.creature) and
                        types.Actor.inventory(data.object) or types.Container.content(data.object)
                    obj:moveInto(inventory)
                    localStorage.removeObjectData(itemData.item)
                    itemData.item:remove()
                    if itemData.slot then
                        equipment[itemData.slot] = obj
                    end
                    ::continue::
                end
                if data.objectType == objectType.npc then
                    data.object:sendEvent("mwr_npc_setEquipment", equipment)
                elseif data.objectType == objectType.creature then
                    data.object:sendEvent("mwr_creature_setEquipment", equipment)
                end
            end
        end),
        mwr_loadLocalConfigData = function(data)
            localConfig.loadData(data)
        end,
        mwr_moveToPoint = function(data)
            if not data.params or not data.params.object then return end
            local object = data.params.object
            object:teleport(data.params.cell, data.res or data.params.pos, {onGround = data.res and false or true, rotation = data.params.rotation})
        end,
    },
}