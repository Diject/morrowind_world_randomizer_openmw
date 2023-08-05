local types = require('openmw.types')
local world = require('openmw.world')
local log = require("scripts.morrowind_world_randomizer.utils.log")
local generatorData = require("scripts.morrowind_world_randomizer.generator.data")

local this = {}

---@class mwr.creatureParameters
---@field type number|nil
---@field pos number|nil

---@class mwr.creaturesData
---@field objects table<string, mwr.creatureParameters>
---@field groups table<string>

---@return mwr.creaturesData
function this.generateCreatureData()
    ---@type mwr.creaturesData
    local out = {objects = {}, groups = {}}

    local tempData = {}
    -- for _, record in pairs(types.CreatureLevelledList.records) do
    --     for _, crea in pairs(record.creatures) do
    --         tempData[crea.id:lower()] = true
    --     end
    -- end
    for _, cell in pairs(world.cells) do
        local levLists = cell:getAll() or {}
        for _, levList in pairs(levLists) do
            if tostring(levList.type) == "LevelledCreature" then
                local record = types.LevelledCreature.record(levList)
                local creatures = {}
                for _, crea in pairs(record.creatures) do
                    creatures[crea.id:lower()] = true
                end
                tempData[record.id:lower()] = {creatures = creatures}
            end
        end
    end
    local function findCreature(creaList, grp)
        for id, crea in pairs(creaList) do
            if tempData[id] then
                findCreature(tempData[id].creatures, grp)
            else
                grp[id] = true
                print(id)
            end
        end
    end
    local creaTable = {}
    for _, data in pairs(tempData) do
        findCreature(data.creatures, creaTable)
    end
    local tempGroups = {}
    for _, crea in pairs(types.Creature.records) do
        local id = crea.id:lower()
        if creaTable[id] then
            if not tempGroups[crea.type] then tempGroups[crea.type] = {} end
            table.insert(tempGroups[crea.type], {id = id, soul = crea.soulValue})
        end
    end
    for i, tb in pairs(tempGroups) do
        table.sort(tb, function(a, b) return a.soul < b.soul end)
    end

    for groupId, group in pairs(tempGroups) do
        for i, data in pairs(group) do
            out.objects[data.id] = {type = groupId, pos = i}
            if not out.groups[groupId] then out.groups[groupId] = {} end
            table.insert(out.groups[groupId], data.id)
        end
    end

    for id, _ in pairs(out.objects) do
        log("test", id)
    end

    return out
end

return this