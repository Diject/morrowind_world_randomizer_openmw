local this = {}

local generatorData = require("scripts.morrowind_world_randomizer.generator.data")

local log = require("scripts.morrowind_world_randomizer.utils.log")
local random = require("scripts.morrowind_world_randomizer.utils.random")
local advString = require("scripts.morrowind_world_randomizer.utils.string")
local tableLib = require("scripts.morrowind_world_randomizer.utils.table")

local types = require('openmw.types')
local world = require("openmw.world")
local util = require("openmw.util")
local async = require('openmw.async')

local objectType = require("scripts.morrowind_world_randomizer.generator.types").objectStrType

require("scripts.morrowind_world_randomizer.generator.items")

---@type mwr.itemsData
this.itemsData = nil
---@type mwr.staticsData
this.treesData = nil
---@type mwr.staticsData
this.rocksData = nil
---@type mwr.staticsData
this.floraData = nil
---@type mwr.containersData
this.herbsData = nil
---@type mwr.config
this.config = nil
---@type mwr.localStorage
this.storage = nil

function this.isReadyForRandomization(cellName)
    local time = this.storage.getCellRandomizationTimestamp(cellName)
    if time and (this.config.data.randomizeOnce or time + this.config.data.randomizeAfter > world.getSimulationTime()) then
        return false
    end
    return true
end

function this.createItem(id, oldItemData)
    local new = world.createObject(id, oldItemData.count)
    new.ownerFactionId = oldItemData.ownerFactionId
    new.ownerFactionRank = oldItemData.ownerFactionRank
    new.ownerRecordId = oldItemData.ownerRecordId
    return new
end

---@param globalStorage mwr.globalStorageData
---@param config mwr.config
---@param storage mwr.localStorage
function this.init(globalStorage, config, storage)
    this.itemsData = globalStorage.itemsData
    this.treesData = globalStorage.treesData
    this.rocksData = globalStorage.rocksData
    this.floraData = globalStorage.floraData
    this.herbsData = globalStorage.herbsData
    this.config = config
    this.storage = storage
end

local function createNewStatic(oldObj, group)
    local newObj = world.createObject(group[math.random(1, #group)], 1)
    local box1 = oldObj:getBoundingBox()
    local box2 = newObj:getBoundingBox()
    local scale = math.huge
    local radius = 0
    for i, vert in pairs(box1.vertices) do
        scale = math.min(math.abs(vert.x) / math.abs(box2.vertices[i].x), scale)
        scale = math.min(math.abs(vert.y) / math.abs(box2.vertices[i].y), scale)
        radius = math.max(math.abs(vert.x), radius)
        radius = math.max(math.abs(vert.y), radius)
    end
    -- local pos = util.vector3(oldObj.position.x, oldObj.position.y, oldObj.position.z + box1.vertices[1].z - box2.vertices[1].z * scale)
    -- local pos = util.vector3(oldObj.position.x, oldObj.position.y, oldObj.position.z + box1.vertices[1].z / oldObj.scale - box2.vertices[1].z * scale)
    local offset = (box2.vertices[1].z + math.abs(box2.vertices[8].z - box2.vertices[1].z) * 0.15) * scale
    world.players[1]:sendEvent("mwr_lowestPosInCircle", {
        object = newObj,
        cell = oldObj.cell.name,
        pos = util.vector3(oldObj.position.x, oldObj.position.y, oldObj.position.z + 1000),
        rotation = oldObj.rotation,
        radius = radius,
        offset = -offset,
        callbackName = "mwr_moveToPoint",
    })
    -- newObj:teleport(oldObj.cell, pos, {onGround = true, rotation = oldObj.rotation})
    newObj:setScale(scale)
    oldObj:remove()
end

this.randomize = async:callback(function(cell)
    if not cell then return end
    local cellName = advString.getCellName(cell)
    if this.isReadyForRandomization(cellName) then
        log("cell randomization", cellName)

        this.randomizeStatics(cell)

        this.storage.setCellRandomizationTimestamp(cellName)
        local config = this.config.getConfigTableByObjectType(nil)
        local items = cell:getAll()
        for _, item in pairs(items or {}) do
            ---@type mwr.itemPosData
            local advItemData = this.itemsData.items[item.recordId]
            local isArtifact = generatorData.obtainableArtifacts[item.recordId]
            local newId
            if isArtifact then
                if not this.storage.data.other.artifacts or #this.storage.data.other.artifacts == 0 then
                    this.storage.data.other.artifacts = {}
                    for id, _ in pairs(generatorData.obtainableArtifacts) do
                        table.insert(this.storage.data.other.artifacts, id)
                    end
                end
                local pos = math.random(1, #this.storage.data.other.artifacts)
                newId = this.storage.data.other.artifacts[pos]
                table.remove(this.storage.data.other.artifacts, pos)
            elseif advItemData and config then
                local grp = this.itemsData.groups[advItemData.type][advItemData.subType]
                newId = grp[random.getRandom(advItemData.pos, #grp, config.item.rregion.min, config.item.rregion.max)]
            end

            if newId then
                local new = this.createItem(newId, item)
                local pos = item.position
                local rot = item.rotation
                log("world", item, "new item", new, "count ", new.count)
                item:remove()
                new:teleport(cell, pos, {onGround = true, rotation = rot})
            end
        end

        local containers = cell:getAll(types.Container)
        config = this.config.getConfigTableByObjectType(objectType.container)
        for _, container in pairs(containers or {}) do
            if types.Container.record(container).weight == 0 then -- for herbs
                if this.config.data.world.herb.item.randomize then
                    local inventory = types.Container.content(container)
                    if not inventory:isResolved() then
                        inventory:resolve()
                    end
                    container:sendEvent("mwr_container_randomizeInventory", {itemsData = this.itemsData, config = this.config.getConfigTableByObjectType("HERB")})
                end
                if this.config.data.world.herb.randomize then
                    local group = {}
                    for i = 1, this.config.data.world.herb.typesPerCell do
                        table.insert(group, this.herbsData.list[math.random(1, #this.herbsData.list)])
                    end
                    createNewStatic(container, group)
                end
            else
                local inventory = types.Container.content(container)
                if not inventory:isResolved() then
                    inventory:resolve()
                end
                container:sendEvent("mwr_container_randomizeInventory", {itemsData = this.itemsData, config = config})
            end
        end
    end
end)

local function get2DDistance(vector1, vector2)
    if not vector1 or not vector2 then return 0 end
    return math.sqrt((vector2.x - vector1.x) ^ 2 + (vector2.y - vector1.y) ^ 2)
end

local function minDistanceBetweenVectors(vector, vectorArray)
    local distance = math.huge
    for i, vector2 in pairs(vectorArray) do
        distance = math.min(distance, get2DDistance(vector, vector2))
    end
    return distance
end

this.randomizeStatics = async:callback(function(cell)
    if not cell.isExterior then return end
    if this.config.data.world.static.tree.randomize then
        local statics = cell:getAll(types.Static)
        local groupTrees = {}
        if this.config.data.world.static.tree.randomize then
            for i = 1, this.config.data.world.static.tree.typesPerCell do
                tableLib.addTableValuesToTable(groupTrees, this.treesData.groups[math.random(1, #this.treesData.groups)])
            end
        end
        local groupRocks = {}
        if this.config.data.world.static.rock.randomize then
            for i = 1, this.config.data.world.static.rock.typesPerCell do
                tableLib.addTableValuesToTable(groupRocks, this.rocksData.groups[math.random(1, #this.rocksData.groups)])
            end
        end
        local groupFlora = {}
        if this.config.data.world.static.rock.randomize then
            for i = 1, this.config.data.world.static.flora.typesPerCell do
                tableLib.addTableValuesToTable(groupFlora, this.floraData.groups[math.random(1, #this.floraData.groups)])
            end
        end
        for i, obj in pairs(statics) do
            if obj.enabled then
                if this.config.data.world.static.tree.randomize and this.treesData.objects[obj.recordId] then
                    createNewStatic(obj, groupTrees)
                elseif this.config.data.world.static.rock.randomize and this.rocksData.objects[obj.recordId] then
                    createNewStatic(obj, groupRocks)
                elseif this.config.data.world.static.flora.randomize and this.floraData.objects[obj.recordId] then
                    createNewStatic(obj, groupFlora)
                end
            end
        end
    end
    -- if this.config.data.world.static.rock.randomize then
    --     local statics = cell:getAll(types.Static)
    --     local group = this.rocksData.groups[math.random(1, #this.rocksData.groups)]
    --     for i, obj in pairs(statics) do
    --         if this.rocksData.objects[obj.recordId] and obj.enabled then
    --             createNewStatic(obj, group)
    --         end
    --     end
    -- end
    -- if this.config.data.world.static.flora.randomize then
    --     local statics = cell:getAll(types.Static)
    --     local group = this.floraData.groups[math.random(1, #this.floraData.groups)]
    --     for i, obj in pairs(statics) do
    --         if this.floraData.objects[obj.recordId] and obj.enabled then
    --             createNewStatic(obj, group)
    --         end
    --     end
    -- end
end)

return this