local types = require('openmw.types')

local advTable = require("scripts.morrowind_world_randomizer.utils.table")
local stringLib = require("scripts.morrowind_world_randomizer.utils.string")

local objectIds = require("scripts.morrowind_world_randomizer.generator.types").objectStrType

---@class mwr.config
local this = {}

local delimiter = "."

this.storageName = "Settings_MWR_By_Diject"

---@class mwr.configData
this.default = {
    version = 1,
    enabled = true,
    randomizeAfter = 1,
    randomizeOnce = true,
    world = {
        item = {
            randomize = true,
            rregion = {
                min = 1,
                max = 1,
            },
        },
        static = {
            tree = {
                randomize = true,
                typesPerCell = 2,
            },
            rock = {
                randomize = true,
                typesPerCell = 2,
            },
            flora = {
                randomize = true,
                typesPerCell = 4,
            },
        },
        herb = {
            randomize = true,
            item = {
                randomize = true,
                rregion = {
                    min = 1,
                    max = 1,
                },
            },
            typesPerCell = 4,
        },
    },
    npc = {
        item = {
            randomize = true,
            rregion = {
                min = 1,
                max = 1,
            },
        },
        stat = {
            dynamic = {
                randomize = true,
                additive = false,
                health = {
                    vregion = {
                        min = 0.75,
                        max = 1.25,
                    },
                },
                fatigue = {
                    vregion = {
                        min = 0.75,
                        max = 1.25,
                    },
                },
                magicka = {
                    vregion = {
                        min = 0.75,
                        max = 1.25,
                    },
                },
            },
            attributes = {
                randomize = true,
                additive = false,
                vregion = {
                    min = 0.75,
                    max = 1.25,
                },
                limit = 255,
            },
            skills = {
                randomize = true,
                additive = true,
                vregion = {
                    min = -100,
                    max = 100,
                },
                limit = 100,
            },
        },
    },
    creature = {
        randomize = true,
        byType = false,
        rregion = {
            min = 1,
            max = 1,
        },
        item = {
            randomize = true,
            rregion = {
                min = 1,
                max = 1,
            },
        },
        stat = {
            dynamic = {
                randomize = true,
                additive = false,
                health = {
                    vregion = {
                        min = 0.75,
                        max = 1.25,
                    },
                },
                fatigue = {
                    vregion = {
                        min = 0.75,
                        max = 1.25,
                    },
                },
                magicka = {
                    vregion = {
                        min = 0.75,
                        max = 1.25,
                    },
                },
            },
        },
    },
    container = {
        item = {
            randomize = true,
            rregion = {
                min = 1,
                max = 1,
            },
        },
    },
}

---@type mwr.configData
this.data = advTable.deepcopy(this.default)

function this.loadData(data)
    if not data then return end
    advTable.applyChanges(this.data, data)
end

---@param objectType any
function this.getConfigTableByObjectType(objectType)
    if objectType == nil then
        return this.data.world
    elseif objectType == objectIds.npc or objectType == types.NPC then
        return this.data.npc
    elseif objectType == objectIds.creature or objectType == types.Creature then
        return this.data.creature
    elseif objectType == objectIds.container or objectType == types.Container then
        return this.data.container
    elseif objectType == objectIds.static then
        return this.data.world.static
    elseif objectType == "HERB" then
        return this.data.world.herb
    end
    return nil
end

function this.setValueByString(val, str)
    local var = this.data
    local lastName
    local prevVar
    for _, varName in ipairs(stringLib.split(str, delimiter)) do
        if var[varName] then
            lastName = varName
            prevVar = var
            var = var[lastName]
        else
            return false
        end
    end
    if lastName then
        if prevVar then
            prevVar[lastName] = val
        else
            var[lastName] = val
        end
        return true
    end
    return false
end

function this.getValueByString(str)
    local var = this.data
    for _, varName in pairs(stringLib.split(str, delimiter)) do
        if var[varName] then
            var = var[varName]
        else
            return nil
        end
    end
    return var
end

function this.loadPlayerSettings(storageTable)
    for name, val in pairs(storageTable) do
        this.setValueByString(val, name)
    end
end

function this.savePlayerSettings(storage)
    local function saveData(var, str)
        if type(var) == "userdata" or type(var) == "table" then
            for valName, val in pairs(var) do
                saveData(val, str and str..delimiter..valName or valName)
            end
        else
            storage:set(str, var)
        end
    end
    saveData(this.data, nil)
end

return this