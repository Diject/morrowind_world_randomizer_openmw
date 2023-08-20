local storage = require("openmw.storage")
local async = require("openmw.async")
local I = require("openmw.interfaces")
local ui = require('openmw.ui')
local core = require('openmw.core')
local util = require('openmw.util')

require("scripts.morrowind_world_randomizer.renderers.minmax")
require("scripts.morrowind_world_randomizer.renderers.label")

local config = require("scripts.morrowind_world_randomizer.config.local")

I.Settings.registerPage({
  key = "MorrowindWorldRandomizer",
  l10n = "morrowind_world_randomizer",
  name = "modName",
  description = "modDescription",
})

---@class mwr.settings.boolSetting
---@field key string
---@field name string l10n
---@field description string|nil l10n
---@field default boolean|nil
---@field trueLabel string|nil
---@field falseLabel string|nil
---@field disabled boolean|nil

---@class mwr.settings.numberSetting
---@field key string
---@field name string l10n
---@field description string|nil l10n
---@field default number|nil
---@field min number|nil
---@field max number|nil
---@field integer boolean|nil
---@field disabled boolean|nil

---@class mwr.settings.textLabel
---@field name string l10n
---@field description string|nil l10n
---@field disabled boolean|nil

local arguments = {}

---@param args mwr.settings.boolSetting
local function boolSetting(args)
    return {
        key = args.key,
        renderer = "checkbox",
        name = args.name,
        description = args.description,
        default = args.default or false,
        trueLabel = args.trueLabel,
        falseLabel = args.falseLabel,
        disabled = args.disabled,
    }
end

---@param args mwr.settings.numberSetting
local function numberSetting(args)
    local data = {
        key = args.key,
        renderer = "number",
        name = args.name,
        description = args.description,
        default = args.default or 0,
        min = args.min,
        max = args.max,
        integer = args.integer,
        disabled = args.disabled,
    }
    table.insert(arguments, data)
    return data
end

---@param args mwr.settings.minmaxSetting
local function minmaxSetting(args)
    local data = {
        key = args.key,
        renderer = "mwrbd_minmax",
        name = args.name,
        description = args.description,
        default = args.default or {min = 0, max = 1},
        independent = args.independent,
        min = args.min,
        max = args.max,
        integer = args.integer,
        disabled = args.disabled,
    }
    table.insert(arguments, data)
    return data
end

local lableId = 0
---@param args mwr.settings.textLabel
local function textLabel(args)
    local data = {
        renderer = "mwrbd_label",
        key = "__dummy__"..tostring(lableId),
        name = args.name,
        description = args.description,
        disabled = args.disabled,
    }
    lableId = lableId + 1
    return data
end

I.Settings.registerGroup({
    key = config.storageName.."_0",
    page = "MorrowindWorldRandomizer",
    l10n = "morrowind_world_randomizer",
    name = "mainSettings",
    permanentStorage = false,
    order = 0,
    settings = {
        boolSetting({key = "enabled", name = "enableRandomizer", default = config.default.enabled}),
        boolSetting({key = "randomizeOnce", name = "onlyOnce", default = config.default.randomizeOnce}),
        numberSetting({key = "randomizeAfter", name = "intervalBetweenRandomizations", default = config.default.randomizeAfter,
            integer = true, min = 0}),
    },
})

local storageName = config.storageName.."_0"
for _, arg in pairs(arguments) do
    I.Settings.updateRendererArgument(storageName, arg.key, arg)
end
lableId = 0
arguments = {}

I.Settings.registerGroup({
    key = config.storageName.."_generator",
    page = "MorrowindWorldRandomizer",
    l10n = "morrowind_world_randomizer",
    name = "dataGeneration",
    permanentStorage = true,
    order = 1,
    settings = {
        boolSetting({key = "logging", name = "logging", default = false}),
        boolSetting({key = "itemSafeMode", name = "itemSafeMode", default = false}),
        boolSetting({key = "creatureSafeMode", name = "creatureSafeMode", default = false}),
    },
})

I.Settings.registerGroup({
    key = config.storageName.."_1",
    page = "MorrowindWorldRandomizer",
    l10n = "morrowind_world_randomizer",
    name = "npc",
    permanentStorage = false,
    order = 2,
    settings = {
        textLabel{name = "empty", description = "items"},
        boolSetting{key = "npc.item.randomize", name = "randomizeItemsInInventory", default = config.default.npc.item.randomize},
        minmaxSetting{key = "npc.item.rregion", name = "rregion", default = config.default.npc.item.rregion, independent = true, min = -100, max = 100},
        textLabel{name = "empty", description = "stats"},
        boolSetting{key = "npc.stat.dynamic.randomize", name = "randomizeDynamicStats", default = config.default.npc.stat.dynamic.randomize},
        boolSetting{key = "npc.stat.dynamic.additive", name = "additive", default = config.default.npc.stat.dynamic.additive},
        minmaxSetting{key = "npc.stat.dynamic.health.vregion", name = "health", default = config.default.npc.stat.dynamic.health.vregion, independent = false},
        minmaxSetting{key = "npc.stat.dynamic.fatigue.vregion", name = "fatigue", default = config.default.npc.stat.dynamic.fatigue.vregion, independent = false},
        minmaxSetting{key = "npc.stat.dynamic.magicka.vregion", name = "magicka", default = config.default.npc.stat.dynamic.magicka.vregion, independent = false},
        textLabel{name = "empty", description = "attributes"},
        boolSetting{key = "npc.stat.attributes.randomize", name = "randomizeAttributes", default = config.default.npc.stat.attributes.randomize},
        boolSetting{key = "npc.stat.attributes.additive", name = "additive", default = config.default.npc.stat.attributes.additive},
        minmaxSetting{key = "npc.stat.attributes.vregion", name = "minmax", default = config.default.npc.stat.attributes.vregion, independent = false},
        numberSetting{key = "npc.stat.attributes.limit", name = "attributesLimit", default = config.default.npc.stat.attributes.limit, integer = true, min = 1},
        textLabel{name = "empty", description = "skills"},
        boolSetting{key = "npc.stat.skills.randomize", name = "randomizeSkills", default = config.default.npc.stat.skills.randomize},
        boolSetting{key = "npc.stat.skills.additive", name = "additive", default = config.default.npc.stat.skills.additive},
        minmaxSetting{key = "npc.stat.skills.vregion", name = "minmax", default = config.default.npc.stat.skills.vregion, independent = false},
        numberSetting{key = "npc.stat.skills.limit", name = "skillsLimit", default = config.default.npc.stat.skills.limit, integer = true, min = 1},
        textLabel{name = "empty", description = "spells"},
        boolSetting{key = "npc.spell.randomize", name = "randomizeSpells", default = config.default.npc.spell.randomize},
        boolSetting{key = "npc.spell.bySchool", name = "spellsBySchool", default = config.default.npc.spell.bySchool},
        minmaxSetting{key = "npc.spell.rregion", name = "rregion", default = config.default.npc.spell.rregion, independent = true, min = -100, max = 100},
        boolSetting{key = "npc.spell.bySkill", name = "spellsBySkill", default = config.default.npc.spell.bySkill},
        numberSetting{key = "npc.spell.bySkillMax", name = "bySkillMax", default = config.default.npc.spell.levelReference, integer = true, min = 1, max = 5},
        numberSetting{key = "npc.spell.levelReference", name = "levelReferenceSpells", default = config.default.npc.spell.levelReference, integer = true, min = 1},
        textLabel{name = "empty", description = "removeSpell"},
        numberSetting{key = "npc.spell.remove.count", name = "count", default = config.default.npc.spell.remove.count, integer = true, min = 0},
        textLabel{name = "empty", description = "addSpell"},
        numberSetting{key = "npc.spell.add.count", name = "count", default = config.default.npc.spell.add.count, integer = true, min = 0},
        boolSetting{key = "npc.spell.add.bySkill", name = "spellsBySkill", default = config.default.npc.spell.add.bySkill},
        numberSetting{key = "npc.spell.add.bySkillMax", name = "bySkillMax", default = config.default.npc.spell.add.levelReference, integer = true, min = 1, max = 5},
        numberSetting{key = "npc.spell.add.levelReference", name = "levelReferenceSpells", default = config.default.npc.spell.add.levelReference, integer = true, min = 1},
        minmaxSetting{key = "npc.spell.add.rregion", name = "rregion", default = config.default.npc.spell.add.rregion, independent = true, min = -100, max = 100},
    },
})

storageName = config.storageName.."_1"
for _, arg in pairs(arguments) do
    I.Settings.updateRendererArgument(storageName, arg.key, arg)
end
lableId = 0
arguments = {}

I.Settings.registerGroup({
    key = config.storageName.."_2",
    page = "MorrowindWorldRandomizer",
    l10n = "morrowind_world_randomizer",
    name = "creature",
    permanentStorage = false,
    order = 3,
    settings = {
        textLabel{name = "empty", description = "items"},
        boolSetting{key = "creature.item.randomize", name = "randomizeItemsInInventory", default = config.default.creature.item.randomize},
        minmaxSetting{key = "creature.item.rregion", name = "rregion", default = config.default.creature.item.rregion, independent = true, min = -100, max = 100},
        textLabel{name = "empty", description = "stats"},
        boolSetting{key = "creature.stat.dynamic.randomize", name = "randomizeDynamicStats", default = config.default.creature.stat.dynamic.randomize},
        boolSetting{key = "creature.stat.dynamic.additive", name = "additive", default = config.default.creature.stat.dynamic.additive},
        minmaxSetting{key = "creature.stat.dynamic.health.vregion", name = "health", default = config.default.creature.stat.dynamic.health.vregion, independent = false},
        minmaxSetting{key = "creature.stat.dynamic.fatigue.vregion", name = "fatigue", default = config.default.creature.stat.dynamic.fatigue.vregion, independent = false},
        minmaxSetting{key = "creature.stat.dynamic.magicka.vregion", name = "magicka", default = config.default.creature.stat.dynamic.magicka.vregion, independent = false},
        textLabel{name = "empty", description = "spells"},
        boolSetting{key = "creature.spell.randomize", name = "randomizeSpells", default = config.default.creature.spell.randomize},
        boolSetting{key = "creature.spell.bySchool", name = "spellsBySchool", default = config.default.creature.spell.bySchool},
        minmaxSetting{key = "creature.spell.rregion", name = "rregion", default = config.default.creature.spell.rregion, independent = true, min = -100, max = 100},
        boolSetting{key = "creature.spell.bySkill", name = "spellsBySkill", default = config.default.creature.spell.bySkill},
        numberSetting{key = "creature.spell.bySkillMax", name = "bySkillMax", default = config.default.creature.spell.levelReference, integer = true, min = 1, max = 5},
        numberSetting{key = "creature.spell.levelReference", name = "levelReferenceSpells", default = config.default.creature.spell.levelReference, integer = true, min = 1},
        textLabel{name = "empty", description = "removeSpell"},
        numberSetting{key = "creature.spell.remove.count", name = "count", default = config.default.creature.spell.remove.count, integer = true, min = 0},
        textLabel{name = "empty", description = "addSpell"},
        numberSetting{key = "creature.spell.add.count", name = "count", default = config.default.creature.spell.add.count, integer = true, min = 0},
        boolSetting{key = "creature.spell.add.bySkill", name = "spellsBySkill", default = config.default.creature.spell.add.bySkill},
        numberSetting{key = "creature.spell.add.bySkillMax", name = "bySkillMax", default = config.default.creature.spell.add.levelReference, integer = true, min = 1, max = 5},
        numberSetting{key = "creature.spell.add.levelReference", name = "levelReferenceSpells", default = config.default.creature.spell.add.levelReference, integer = true, min = 1},
        minmaxSetting{key = "creature.spell.add.rregion", name = "rregion", default = config.default.creature.spell.add.rregion, independent = true, min = -100, max = 100},
    },
})

storageName = config.storageName.."_2"
for _, arg in pairs(arguments) do
    I.Settings.updateRendererArgument(storageName, arg.key, arg)
end
lableId = 0
arguments = {}

I.Settings.registerGroup({
    key = config.storageName.."_3",
    page = "MorrowindWorldRandomizer",
    l10n = "morrowind_world_randomizer",
    name = "container",
    permanentStorage = false,
    order = 4,
    settings = {
        textLabel{name = "empty", description = "items"},
        boolSetting({key = "container.item.randomize", name = "randomizeItemsInContainer", default = config.default.container.item.randomize}),
        minmaxSetting{key = "container.item.rregion", name = "rregion", default = config.default.container.item.rregion, independent = true, min = -100, max = 100},
        textLabel{name = "empty", description = "lock"},
        numberSetting({key = "container.lock.maxValue", name = "maxLock", default = config.default.container.lock.maxValue, min = 1, max = 10000}),
        textLabel{name = "empty", description = "existing"},
        numberSetting({key = "container.lock.chance", name = "chanceToChange", default = config.default.container.lock.chance, min = 0, max = 100}),
        minmaxSetting{key = "container.lock.rregion", name = "rregion", default = config.default.container.lock.rregion, independent = true, min = -100, max = 100},
        textLabel{name = "empty", description = "addNew"},
        numberSetting({key = "container.lock.add.chance", name = "chanceToAdd", default = config.default.container.lock.add.chance, min = 0, max = 100}),
        numberSetting{key = "container.lock.add.levelReference", name = "levelReferenceLock", default = config.default.container.lock.add.levelReference, integer = true, min = 1},
        textLabel{name = "empty", description = "removeLock"},
        numberSetting({key = "container.lock.remove.chance", name = "chanceToUnlock", default = config.default.container.lock.remove.chance, min = 0, max = 100}),
        textLabel{name = "empty", description = "trap"},
        textLabel{name = "empty", description = "existing"},
        numberSetting({key = "container.trap.chance", name = "chanceToChange", default = config.default.container.trap.chance, min = 0, max = 100}),
        numberSetting{key = "container.trap.levelReference", name = "levelReferenceTrap", default = config.default.container.trap.levelReference, integer = true, min = 1},
        textLabel{name = "empty", description = "addNew"},
        numberSetting({key = "container.trap.add.chance", name = "chanceToAdd", default = config.default.container.trap.add.chance, min = 0, max = 100}),
        numberSetting{key = "container.trap.add.levelReference", name = "levelReferenceTrap", default = config.default.container.trap.add.levelReference, integer = true, min = 1},
        textLabel{name = "empty", description = "untrapping"},
        numberSetting({key = "container.trap.remove.chance", name = "chanceToRemoveTrap", default = config.default.container.trap.remove.chance, min = 0, max = 100}),
    },
})

storageName = config.storageName.."_3"
for _, arg in pairs(arguments) do
    I.Settings.updateRendererArgument(storageName, arg.key, arg)
end
lableId = 0
arguments = {}

I.Settings.registerGroup({
    key = config.storageName.."_4",
    page = "MorrowindWorldRandomizer",
    l10n = "morrowind_world_randomizer",
    name = "door",
    permanentStorage = false,
    order = 5,
    settings = {
        textLabel{name = "empty", description = "lock"},
        numberSetting({key = "door.lock.maxValue", name = "maxLock", default = config.default.door.lock.maxValue, min = 1, max = 10000}),
        textLabel{name = "empty", description = "existing"},
        numberSetting({key = "door.lock.chance", name = "chanceToChange", default = config.default.door.lock.chance, min = 0, max = 100}),
        minmaxSetting{key = "door.lock.rregion", name = "rregion", default = config.default.door.lock.rregion, independent = true, min = -100, max = 100},
        textLabel{name = "empty", description = "addNew"},
        numberSetting({key = "door.lock.add.chance", name = "chanceToAdd", default = config.default.door.lock.add.chance, min = 0, max = 100}),
        numberSetting{key = "door.lock.add.levelReference", name = "levelReferenceLock", default = config.default.door.lock.add.levelReference, integer = true, min = 1},
        textLabel{name = "empty", description = "removeLock"},
        numberSetting({key = "door.lock.remove.chance", name = "chanceToUnlock", default = config.default.door.lock.remove.chance, min = 0, max = 100}),
        textLabel{name = "empty", description = "trap"},
        textLabel{name = "empty", description = "existing"},
        numberSetting({key = "door.trap.chance", name = "chanceToChange", default = config.default.door.trap.chance, min = 0, max = 100}),
        numberSetting{key = "door.trap.levelReference", name = "levelReferenceTrap", default = config.default.door.trap.levelReference, integer = true, min = 1},
        textLabel{name = "empty", description = "addNew"},
        numberSetting({key = "door.trap.add.chance", name = "chanceToAdd", default = config.default.door.trap.add.chance, min = 0, max = 100}),
        numberSetting{key = "door.trap.add.levelReference", name = "levelReferenceTrap", default = config.default.door.trap.add.levelReference, integer = true, min = 1},
        textLabel{name = "empty", description = "untrapping"},
        numberSetting({key = "door.trap.remove.chance", name = "chanceToRemoveTrap", default = config.default.door.trap.remove.chance, min = 0, max = 100}),
    },
})

storageName = config.storageName.."_4"
for _, arg in pairs(arguments) do
    I.Settings.updateRendererArgument(storageName, arg.key, arg)
end
lableId = 0
arguments = {}

I.Settings.registerGroup({
    key = config.storageName.."_5",
    page = "MorrowindWorldRandomizer",
    l10n = "morrowind_world_randomizer",
    name = "world",
    permanentStorage = false,
    order = 6,
    settings = {
        boolSetting({key = "world.item.randomize", name = "randomizeItemsWithoutContainer", default = config.default.world.item.randomize}),
        minmaxSetting{key = "world.item.rregion", name = "rregion", default = config.default.world.item.rregion, independent = true, min = -100, max = 100},
        textLabel{name = "empty", description = "light"},
        boolSetting({key = "world.light.randomize", name = "randomizeLight", default = config.default.world.light.randomize}),
        textLabel{name = "empty", description = "trees"},
        boolSetting({key = "world.static.tree.randomize", name = "randomizeTrees", default = config.default.world.static.tree.randomize}),
        numberSetting({key = "world.static.tree.typesPerCell", name = "typesPerCell", default = config.default.world.static.tree.typesPerCell,
            integer = true, min = 1, max = 10}),
        textLabel{name = "empty", description = "rocks"},
        boolSetting({key = "world.static.rock.randomize", name = "randomizeRocks", default = config.default.world.static.rock.randomize}),
        numberSetting({key = "world.static.rock.typesPerCell", name = "typesPerCell", default = config.default.world.static.rock.typesPerCell,
            integer = true, min = 1, max = 10}),
        textLabel{name = "empty", description = "flora"},
        boolSetting({key = "world.static.flora.randomize", name = "randomizeFlora", default = config.default.world.static.flora.randomize}),
        numberSetting({key = "world.static.flora.typesPerCell", name = "typesPerCell", default = config.default.world.static.flora.typesPerCell,
            integer = true, min = 1, max = 10}),
        textLabel{name = "empty", description = "herbs"},
        boolSetting({key = "world.herb.randomize", name = "randomizeHerbs", default = config.default.world.herb.randomize}),
        numberSetting({key = "world.herb.typesPerCell", name = "typesPerCell", default = config.default.world.herb.typesPerCell,
            integer = true, min = 1, max = 10}),
        boolSetting({key = "world.herb.item.randomize", name = "randomizeItemsInHerb", default = config.default.world.herb.item.randomize}),
        minmaxSetting{key = "world.herb.item.rregion", name = "rregion", default = config.default.world.herb.item.rregion, independent = true, min = -100, max = 100},
    },
})

storageName = config.storageName.."_5"
for _, arg in pairs(arguments) do
    I.Settings.updateRendererArgument(storageName, arg.key, arg)
end
lableId = 0
arguments = {}

for i = 0, 5 do
    local sotrageName = config.storageName.."_"..tostring(i)
    storage.playerSection(sotrageName):subscribe(async:callback(function()
        core.sendGlobalEvent("mwr_loadLocalConfigData", storage.playerSection(sotrageName):asTable())
    end))
end

storage.playerSection(config.storageName.."_generator"):subscribe(async:callback(function()
    core.sendGlobalEvent("mwr_updateGeneratorSettings", storage.playerSection(config.storageName.."_generator"):asTable())
end))