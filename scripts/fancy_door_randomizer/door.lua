local world = require('openmw.world')
local Door = require('openmw.types').Door

local this = {}

this.forbiddenDoorIds = {
    ["chargen customs door"] = true,
    ["chargen door captain"] = true,
    ["chargen door exit"] = true,
    ["chargen door hall"] = true,
    ["chargen exit door"] = true,
    ["chargen_cabindoor"] = true,
    ["chargen_ship_trapdoor"] = true,
    ["chargen_shipdoor"] = true,
    ["chargendoorjournal"] = true,
}

this.storage = nil

function this.init(storage)
    this.storage = storage
end

function this.isExterior(cell)
    if cell.isExterior or cell:hasTag("QuasiExterior") then
        return true
    end
    return false
end

function this.fingDoors()
    local out = {InToIn = {}, InToEx = {}, ExToIn = {}, ExToEx = {}}
    for _, cell in pairs(world.cells) do
        for _, door in pairs(cell:getAll(Door)) do
            if Door.isTeleport(door) and not this.forbiddenDoorIds[door.recordId] then
                local posExterior = this.isExterior(door.cell)
                local destExterior = this.isExterior(Door.destCell(door))
                if posExterior and destExterior then
                    table.insert(out.ExToEx, door)
                elseif posExterior and not destExterior then
                    table.insert(out.ExToIn, door)
                elseif not posExterior and destExterior then
                    table.insert(out.InToEx, door)
                elseif not posExterior and not destExterior then
                    table.insert(out.InToIn, door)
                end
            end
        end
    end
    return out
end

function this.getDoorList(door, array)
    local posExterior = this.isExterior(door.cell)
    local destExterior = this.isExterior(Door.destCell(door))
    if posExterior and destExterior then
        return array.ExToEx
    elseif posExterior and not destExterior then
        return array.ExToIn
    elseif not posExterior and destExterior then
        return array.InToEx
    elseif not posExterior and not destExterior then
        return array.InToIn
    end
end

function this.getDistance(vec1, vec2)
    return math.sqrt((vec1.x - vec2.x) ^ 2 + (vec1.y - vec2.y) ^ 2 + (vec1.z - vec2.z) ^ 2)
end

function this.getBackDoor(door)
    if Door.objectIsInstance(door) and Door.isTeleport(door) and not this.forbiddenDoorIds[door.recordId] then
        local cell = Door.destCell(door)
        if not cell then return end
        local nearestDoor = nil
        local distance = math.huge
        local doorDestPos = Door.destPosition(door)
        for _, cdoor in pairs(cell:getAll(Door)) do
            if Door.isTeleport(cdoor) then
                local distBetween = this.getDistance(doorDestPos, cdoor.position)
                if Door.isTeleport(cdoor) and not this.forbiddenDoorIds[cdoor.recordId] and distBetween < distance then
                    distance = distBetween
                    nearestDoor = cdoor
                end
            end
        end
        return nearestDoor
    end
end

return this