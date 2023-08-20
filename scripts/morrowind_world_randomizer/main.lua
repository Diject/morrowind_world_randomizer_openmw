local core = require("openmw.core")
if not core.contentFiles.has(require("scripts.morrowind_world_randomizer.scriptName")) then
    return
end

local log = require("scripts.morrowind_world_randomizer.utils.log")

local generatorData = require("scripts.morrowind_world_randomizer.generator.data")

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
local time = require('openmw_aux.time')
local storage = require('openmw.storage')
local Activation = require('openmw.interfaces').Activation

local objectType = require("scripts.morrowind_world_randomizer.generator.types").objectStrType

local cellLib = require("scripts.morrowind_world_randomizer.cell")

---@type mwr.globalStorageData
local globalData = nil

local function isReadyForRandomization(ref, once)
    local tm = localStorage.getRefRandomizationTimestamp(ref)
    if tm and once then
        return false
    elseif tm and (localConfig.data.randomizeOnce or (tm + localConfig.data.randomizeAfter > world.getSimulationTime())) then
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

local function rebuildStorageData()
    globalStorage.data.version = globalStorage.version
    local statics = require("scripts.morrowind_world_randomizer.generator.statics")
    globalStorage.data.treesData = statics.rebuildRocksTreesData(require("scripts.morrowind_world_randomizer.data.TreesData_TR"))
    globalStorage.data.rocksData = statics.rebuildRocksTreesData(require("scripts.morrowind_world_randomizer.data.RocksData_TR"))
    local itemSafeMode = storage.globalSection(globalStorage.storageName):get("itemSafeMode")
    globalStorage.data.itemsData = require("scripts.morrowind_world_randomizer.generator.items").generateData(itemSafeMode)
    globalStorage.data.floraData = statics.generateFloraData()
    globalStorage.data.herbsData = require("scripts.morrowind_world_randomizer.generator.containers").generateHerbData()
    local creatureSafeMode = storage.globalSection(globalStorage.storageName):get("creatureSafeMode")
    globalStorage.data.creaturesData = require("scripts.morrowind_world_randomizer.generator.creatures").generateCreatureData(creatureSafeMode)
    globalStorage.data.spellsData = require("scripts.morrowind_world_randomizer.generator.spells").generateSpellData()
    globalStorage.data.lightsData = require("scripts.morrowind_world_randomizer.generator.lights").generateData()
    globalStorage.saveGameFilesDataToStorage()
    globalStorage.save()
end

local function initData()
    if globalStorage.init() then
        rebuildStorageData()
    end
    globalData = globalStorage.data
end

local function onActorActive(actor)
    if not localConfig.data.enabled then return end
    async:newUnsavableSimulationTimer(0.2, function()
        if not actor or not actor:isValid() then return end
        local actorSavedData = localStorage.saveActorData(actor)
        if not actorSavedData then return end
        local config = localConfig.getConfigTableByObjectType(actor.type)
        if not config then return end
        local firstRandomization = isReadyForRandomization(actor, true)
        local isAlive = types.Actor.stats.dynamic.health(actor).current > 0

        if firstRandomization then
            if actor.type == types.Creature and config.randomize and not actor.contentFile and
                    globalStorage.data.creaturesData.objects[actor.recordId] and isAlive then
                local actorData = globalStorage.data.creaturesData.objects[actor.recordId]
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

        if firstRandomization or (isAlive and isReadyForRandomization(actor)) then
            if config.item.randomize then
                localStorage.setRefRandomizationTimestamp(actor)
                actor:sendEvent("mwr_actor_randomizeInventory", {itemsData = globalData.itemsData, config = config})
            end

            if config.stat.dynamic.randomize and isAlive then
                local health = actorSavedData.health
                local magicka = actorSavedData.magicka
                local fatigue = actorSavedData.fatigue
                if config.stat.dynamic.additive then
                    health = math.max(1, health + random.getBetween(config.stat.dynamic.health.vregion.min, config.stat.dynamic.health.vregion.max))
                    magicka = math.max(1, magicka + random.getBetween(config.stat.dynamic.magicka.vregion.min, config.stat.dynamic.magicka.vregion.max))
                    fatigue = math.max(1, fatigue + random.getBetween(config.stat.dynamic.fatigue.vregion.min, config.stat.dynamic.fatigue.vregion.max))
                else
                    health = math.max(1, health * random.getBetween(config.stat.dynamic.health.vregion.min, config.stat.dynamic.health.vregion.max))
                    magicka = math.max(1, magicka * random.getBetween(config.stat.dynamic.magicka.vregion.min, config.stat.dynamic.magicka.vregion.max))
                    fatigue = math.max(1, fatigue * random.getBetween(config.stat.dynamic.fatigue.vregion.min, config.stat.dynamic.fatigue.vregion.max))
                end
                actor:sendEvent("mwr_actor_setDynamicStats", {health = health, magicka = magicka, fatigue = fatigue})
            end

            if config.stat.attributes and config.stat.attributes.randomize then
                local attributes = actorSavedData.attributes
                local attrConfig = config.stat.attributes
                local getVal = function(val)
                    if attrConfig.additive then
                        return math.floor(math.max(0, math.min(attrConfig.limit, val + random.getBetween(attrConfig.vregion.min, attrConfig.vregion.max))))
                    else
                        return math.floor(math.max(0, math.min(attrConfig.limit, val * random.getBetween(attrConfig.vregion.min, attrConfig.vregion.max))))
                    end
                end
                local data = {}
                data.agility = getVal(attributes.agility)
                data.endurance = getVal(attributes.endurance)
                data.intelligence = getVal(attributes.intelligence)
                data.luck = getVal(attributes.luck)
                data.personality = getVal(attributes.personality)
                data.speed = getVal(attributes.speed)
                data.strength = getVal(attributes.strength)
                data.willpower = getVal(attributes.willpower)
                actor:sendEvent("mwr_actor_setAttributeBase", data)
            end

            if config.stat.skills and config.stat.skills.randomize then
                actor:sendEvent("mwr_actor_randomizeSkillBaseValues", {config = config, actorData = actorSavedData})
            end

            if config.spell then
                async:newUnsavableSimulationTimer(0.2, function()
                    actor:sendEvent("mwr_actor_randomizeSpells", {config = config, spellsData = globalData.spellsData, actorData = actorSavedData})
                end)
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
end, 30 * time.second, { initialDelay = math.random() * 10 * time.second })

local function onObjectActive(object)
    if not localConfig.data.enabled then return end
    cellLib.randomize(object.cell)
    cellsForCheck[object.cell] = true
end

local function onInit()
    math.randomseed(os.time())
    initData()
    cellLib.init(globalData, localConfig, localStorage)
end

local function onSave()
    return {config = localConfig.data, storage = localStorage.data}
end

local function onLoad(data)
    localConfig.loadData(data.config)
    world.players[1]:sendEvent("mwrbd_updateSettings", {configData = localConfig.data})
    localStorage.loadData(data.storage)
    if not globalData then
        initData()
        cellLib.init(globalData, localConfig, localStorage)
    end
end

local function onNewGame()
    world.players[1]:sendEvent("mwrbd_updateSettings", {configData = localConfig.data})
end

local function onActivate(object, actor)
    if localConfig.data.doNot.activatedContainers and object.type == types.Container and not types.Lockable.isLocked(object) then
        localStorage.setRefRandomizationTimestamp(object, 9999999999)
    end
end

local function mwr_updateInventory(data)
    local config = localConfig.getConfigTableByObjectType(data.objectType)
    if config then
        local equipment = (data.objectType == objectType.npc or data.objectType == objectType.creature) and types.Actor.getEquipment(data.object) or {}
        for _, itemData in pairs(data.items) do
            if itemData.item.count == 0 then goto continue end
            local isArtifact = generatorData.obtainableArtifacts[itemData.item.recordId]
            local newId
            if isArtifact then
                if not localStorage.data.other.artifacts or #localStorage.data.other.artifacts == 0 then
                    localStorage.data.other.artifacts = {}
                    for id, _ in pairs(generatorData.obtainableArtifacts) do
                        table.insert(localStorage.data.other.artifacts, id)
                    end
                end
                local pos = math.random(1, #localStorage.data.other.artifacts)
                newId = localStorage.data.other.artifacts[pos]
                table.remove(localStorage.data.other.artifacts, pos)
            else
                ---@type mwr.itemPosData
                local advData = itemData.advData or globalData.itemsData.items[itemData.item.recordId]
                if not advData then goto continue end
                local grp = globalData.itemsData.groups[advData.type][advData.subType]
                newId = grp[random.getRandom(advData.pos, #grp, config.item.rregion.min, config.item.rregion.max)]
                local i = 10
                while (data.objectType == objectType.npc or data.objectType == objectType.creature) and
                        i > 0 and globalData.itemsData.items[newId] and globalData.itemsData.items[newId].isDangerous do
                    newId = grp[random.getRandom(advData.pos, #grp, config.item.rregion.min, config.item.rregion.max)]
                    i = i - 1
                end
                if i == 0 then goto continue end
            end
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
        if data.objectType == objectType.npc or data.objectType == objectType.creature then
            data.object:sendEvent("mwr_actor_setEquipment", equipment)
        end
    end
end

local function mwr_moveToPoint(data)
    if not data.params or not data.params.object then return end
    local object = data.params.object
    object:teleport(data.params.cell, data.res or data.params.pos, {onGround = data.res and false or true, rotation = data.params.rotation})
end

local function mwr_deactivateObject(data)
    local object = data.object
    if localStorage.isIdInDeletionList(object.id) then
        localStorage.removeIdFromDeletionList(object.id)
        log("Parent actor removed", object)
        object:remove()
    end
    localStorage.clearRefRandomizationTimestamp(object)
    log("Deactivated", object)
end

local function mwr_loadLocalConfigData(data)
    localConfig.loadData(data)
end

local function mwr_updateGeneratorSettings(data)
    local global = storage.globalSection(globalStorage.storageName)
    for name, val in pairs(data) do
        globalStorage.data[name] = val
        global:set(name, val)
    end
    rebuildStorageData()
end

return {
    engineHandlers = {
        onActorActive = async:callback(onActorActive),
        onObjectActive = async:callback(onObjectActive),
        onInit = async:callback(onInit),
        onSave = async:callback(onSave),
        onLoad = async:callback(onLoad),
        onNewGame = async:callback(onNewGame),
        onActivate = async:callback(onActivate),
    },
    eventHandlers = {
        mwr_updateInventory = async:callback(mwr_updateInventory),
        mwr_loadLocalConfigData = mwr_loadLocalConfigData,
        mwr_moveToPoint = async:callback(mwr_moveToPoint),
        mwr_deactivateObject = async:callback(mwr_deactivateObject),
        mwr_updateGeneratorSettings = async:callback(mwr_updateGeneratorSettings),
    },
}