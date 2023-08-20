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
    randomizeAfter = 10,
    randomizeOnce = false,
    doNot = {
        activatedContainers = true,
    },
    world = {
        item = {
            randomize = true,
            rregion = {
                min = 100,
                max = 100,
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
                    min = 100,
                    max = 100,
                },
            },
            typesPerCell = 4,
        },
        light = {
            randomize = true,
        },
    },
    npc = {
        item = {
            randomize = true,
            rregion = {
                min = 100,
                max = 100,
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
                        min = 1,
                        max = 2,
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
                    min = -40,
                    max = 40,
                },
                limit = 100,
            },
        },
        spell = {
            randomize = true,
            bySchool = true,
            bySkill = false,
            levelReference = 20,
            bySkillMax = 2,
            rregion = {
                min = 100,
                max = 100,
            },
            add = {
                count = 10,
                bySkill = true,
                bySkillMax = 2,
                levelReference = 20,
                rregion = {
                    min = 100,
                    max = 100,
                },
            },
            remove = {
                count = 20,
            },
        },
    },
    creature = {
        randomize = true,
        byType = false,
        rregion = {
            min = 100,
            max = 100,
        },
        item = {
            randomize = true,
            rregion = {
                min = 100,
                max = 100,
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
                        min = 1,
                        max = 2,
                    },
                },
            },
        },
        spell = {
            randomize = true,
            bySchool = true,
            rregion = {
                min = 100,
                max = 100,
            },
            add = {
                count = 10,
                levelReference = 20,
                rregion = {
                    min = 100,
                    max = 100,
                },
            },
            remove = {
                count = 20,
            },
        },
    },
    container = {
        item = {
            randomize = true,
            rregion = {
                min = 100,
                max = 100,
            },
        },
        lock = {
            chance = 100,
            maxValue = 100,
            rregion = {
                min = 100,
                max = 100,
            },
            add = {
                chance = 15,
                levelReference = 1,
            },
            remove = {
                chance = 25,
            },
        },
        trap = {
            chance = 100,
            levelReference = 1,
            add = {
                chance = 25,
                levelReference = 1,
            },
            remove = {
                chance = 25,
            },
        },
    },
    door = {
        lock = {
            chance = 100,
            maxValue = 100,
            rregion = {
                min = 100,
                max = 100,
            },
            add = {
                chance = 15,
                levelReference = 1,
            },
            remove = {
                chance = 25,
            },
        },
        trap = {
            chance = 100,
            levelReference = 1,
            add = {
                chance = 100,
                levelReference = 1,
            },
            remove = {
                chance = 25,
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
    elseif objectType == objectIds.door or objectType == types.Door then
        return this.data.door
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
        if var[varName] ~= nil then
            lastName = varName
            prevVar = var
            var = var[lastName]
        else
            return false
        end
    end
    if lastName then
        if prevVar ~= nil then
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
        if var[varName] ~= nil then
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