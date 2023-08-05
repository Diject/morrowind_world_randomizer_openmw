local world = require('openmw.world')
local util = require('openmw.util')

local this = {}

---@class vector3
---@field x number
---@field y number
---@field z number

---@class cellData
---@field name string
---@field gridX integer
---@field gridY integer

---@class doorStorageObject
---@field pos vector3
---@field rot vector3
---@field cell cellData
---@field timestamp integer

---@type table<string, doorStorageObject>
this.data = {}

function this.getRawData(doorId)
    return this.data[doorId]
end

function this.getData(doorId)
    local data = this.data[doorId]
    if data then
        local cell = data.cell.name == "" and world.getExteriorCell(data.cell.gridX, data.cell.gridY) or world.getCellByName(data.cell.name)
        print(data.pos, data.rot)
        local pos = util.vector3(data.pos.x, data.pos.y, data.pos.z)
        local rot = util.transform.rotate(0, util.vector3(data.rot.x, data.rot.y, data.rot.z))
        return cell, pos, rot
    end
    return nil
end

---@param doorId string
---@param pos vector3
---@param rot vector3
---@param cell cellData
---@param timestamp integer
function this.setRawData(doorId, pos, rot, cell, timestamp)
    ---@type doorStorageObject
    local data = {cell = cell, pos = pos, rot = rot, timestamp = timestamp}
    this.data[doorId] = data
end

function this.setData(doorId, pos, rot, cell)
    ---@type doorStorageObject
    local rotX, rotY, rotZ = rot:getAnglesZYX()
    local data = {cell = {name = cell.name, gridX = cell.gridX, gridY = cell.gridY}, pos = {x = pos.x, y = pos.y, z = pos.z},
        rot = {x = rotX, y = rotY, z = rotZ}, timestamp = world.getSimulationTime()}
    this.data[doorId] = data
end

function this.clearData(doorId)
    this.data[doorId] = nil
end

return this