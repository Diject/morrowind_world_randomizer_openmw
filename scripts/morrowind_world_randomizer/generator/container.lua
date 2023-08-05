local types = require('openmw.types')
local log = require("scripts.morrowind_world_randomizer.utils.log")
local generatorData = require("scripts.morrowind_world_randomizer.generator.data")

local this = {}

---@class mwr.creatureParameters
---@field name string|nil
---@field weight number|nil

---@class mwr.containersData
---@field objects table<string, mwr.creatureParameters>
---@field list table<string>

---@return mwr.containersData
function this.generateHerbData()
    ---@type mwr.containersData
    local out = {objects = {}, list = {}}

    for  _, object in pairs(types.Container.records) do
        local id = object.id:lower()
        local name = object.name:lower()
        if not generatorData.forbiddenIds[id] and object.mwscript == "" and object.weight == 0 and not name:find("chest") and
                not id:find("test") and not id:find("bag") then
            out.objects[id] = {}
            table.insert(out.list, id)
        end
    end

    return out
end

return this