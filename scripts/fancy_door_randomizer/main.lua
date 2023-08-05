local doorLib = require("scripts.fancy_door_randomizer.door")
local storage = require("scripts.fancy_door_randomizer.storage")

local Door = require('openmw.types').Door
local Activation = require('openmw.interfaces').Activation
local async = require('openmw.async')
local core = require('openmw.core')
local world = require('openmw.world')

local doorsData = nil

local function onInit()
    doorLib.init(storage)

    doorsData = doorLib.fingDoors()

    Activation.addHandlerForType(Door,
        async:callback(function(door, actor)
            if Door.objectIsInstance(door) and Door.isTeleport(door) and not doorLib.forbiddenDoorIds[door.recordId] then
                local cell, pos, rot = storage.getData(door.id)
                if cell then
                    actor:teleport(cell, pos, {onGround = true, rotation = rot})
                else
                    local list = doorLib.getDoorList(door, doorsData)
                    local newDestinationDoor = list[math.random(1, #list)]
                    local pos = Door.destPosition(newDestinationDoor)
                    local rot = Door.destRotation(newDestinationDoor)
                    local cell = Door.destCell(newDestinationDoor)
                    local toMainDoor = doorLib.getBackDoor(door)
                    local targetDoor = doorLib.getBackDoor(newDestinationDoor)
                    print(door.id, toMainDoor.id, doorLib.getBackDoor(door).id, doorLib.getBackDoor(toMainDoor).id)
                    storage.setData(door.id, pos, rot, cell)
                    storage.setData(targetDoor.id, Door.destPosition(toMainDoor), Door.destRotation(toMainDoor), Door.destCell(toMainDoor))
                    actor:teleport(cell, pos, {onGround = true, rotation = rot})
                end
                return false
            end
        end)
    )
end

local function onSave()
    return {storage = storage.data}
end

local function onLoad(data)
    storage.data = data.storage or {}
    doorLib.init(storage)
    doorsData = doorLib.fingDoors()
end

return {
    engineHandlers = {
        onInit = onInit,
        onSave = onSave,
        onLoad = onLoad,
    },

}