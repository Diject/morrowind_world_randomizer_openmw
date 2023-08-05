local storage = require("openmw.storage")
local async = require("openmw.async")
local I = require("openmw.interfaces")
local core = require('openmw.core')

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

---@class mwr.settings.textSetting
---@field name string l10n
---@field description string|nil l10n
---@field disabled boolean|nil

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
    return {
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
end

---@param args mwr.settings.textSetting
local function textSetting(args)
    return {
        renderer = "textLine",
        name = args.name,
        description = args.description,
        disabled = args.disabled,
    }
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

I.Settings.registerGroup({
    key = config.storageName.."_1",
    page = "MorrowindWorldRandomizer",
    l10n = "morrowind_world_randomizer",
    name = "items",
    permanentStorage = false,
    order = 1,
    settings = {
        boolSetting({key = "npc.item.randomize", name = "randomizeItemsInNPC", default = config.default.npc.item.randomize}),
        numberSetting({key = "npc.item.rregion.min", name = "leftShift", default = config.default.npc.item.rregion.min,
            min = -1, max = 1}),
        numberSetting({key = "npc.item.rregion.max", name = "rightShift", default = config.default.npc.item.rregion.max,
            min = -1, max = 1}),
        boolSetting({key = "creature.item.randomize", name = "randomizeItemsInNPC", default = config.default.creature.item.randomize}),
        numberSetting({key = "creature.item.rregion.min", name = "leftShift", default = config.default.creature.item.rregion.min,
            min = -1, max = 1}),
        numberSetting({key = "creature.item.rregion.max", name = "rightShift", default = config.default.creature.item.rregion.max,
            min = -1, max = 1}),
        boolSetting({key = "container.item.randomize", name = "randomizeItemsInContainer", default = config.default.container.item.randomize}),
        numberSetting({key = "container.item.rregion.min", name = "leftShift", default = config.default.container.item.rregion.min,
            min = -1, max = 1}),
        numberSetting({key = "container.item.rregion.max", name = "rightShift", default = config.default.container.item.rregion.max,
            min = -1, max = 1}),
        boolSetting({key = "world.item.randomize", name = "randomizeItemsWithoutContainer", default = config.default.world.item.randomize}),
        numberSetting({key = "world.item.rregion.min", name = "leftShift", default = config.default.world.item.rregion.min,
            min = -1, max = 1}),
        numberSetting({key = "world.item.rregion.max", name = "rightShift", default = config.default.world.item.rregion.max,
            min = -1, max = 1}),
    },
})

I.Settings.registerGroup({
    key = config.storageName.."_2",
    page = "MorrowindWorldRandomizer",
    l10n = "morrowind_world_randomizer",
    name = "world",
    permanentStorage = false,
    order = 2,
    settings = {
        boolSetting({key = "world.static.tree.randomize", name = "randomizeTrees", default = config.default.world.static.tree.randomize}),
        numberSetting({key = "world.static.tree.typesPerCell", name = "typesPerCell", default = config.default.world.static.tree.typesPerCell,
            integer = true, min = 1, max = 10}),
        boolSetting({key = "world.static.rock.randomize", name = "randomizeRocks", default = config.default.world.static.rock.randomize}),
        numberSetting({key = "world.static.rock.typesPerCell", name = "typesPerCell", default = config.default.world.static.rock.typesPerCell,
            integer = true, min = 1, max = 10}),
        boolSetting({key = "world.static.flora.randomize", name = "randomizeFlora", default = config.default.world.static.flora.randomize}),
        numberSetting({key = "world.static.flora.typesPerCell", name = "typesPerCell", default = config.default.world.static.flora.typesPerCell,
            integer = true, min = 1, max = 10}),
        boolSetting({key = "world.herb.randomize", name = "randomizeHerbs", default = config.default.world.herb.randomize}),
        numberSetting({key = "world.herb.typesPerCell", name = "typesPerCell", default = config.default.world.herb.typesPerCell,
            integer = true, min = 1, max = 10}),
    },
})

for i = 0, 2 do
    storage.playerSection(config.storageName.."_"..tostring(i)):subscribe(async:callback(function()
        -- local cfg = require("scripts.morrowind_world_randomizer.config.local")
        -- cfg.loadPlayerSettings(storage.playerSection(config.storageName.."_"..tostring(i)))
        core.sendGlobalEvent("mwr_loadLocalConfigData", storage.playerSection(config.storageName.."_"..tostring(i)):asTable())
    end))
end