local world = require('openmw.world')

---@class mwr.localStorage
local this = {}

this.data = {lastRand = {}, cellLastRand = {}, creatureParent = {}, deletionList = {}}

function this.setRefRandomizationTimestamp(reference)
    this.data.lastRand[reference.id] = world.getSimulationTime()
end

---@return integer|nil
function this.getRefRandomizationTimestamp(reference)
    return this.data.lastRand[reference.id]
end

function this.clearRefRandomizationTimestamp(reference)
    this.data.lastRand[reference.id] = nil
end

function this.setCellRandomizationTimestamp(cellName)
    this.data.cellLastRand[cellName] = world.getSimulationTime()
end

---@return integer|nil
function this.getCellRandomizationTimestamp(cellName)
    return this.data.cellLastRand[cellName]
end

function this.removeObjectData(reference)
    this.data.lastRand[reference.id] = nil
end

function this.setCreatureParentIdData(crea, parent)
    this.data.creatureParent[crea.id] = parent.id
end

function this.getCreatureParentData(crea)
    return this.data.creatureParent[crea.id]
end

function this.addIdToDeletionList(id)
    this.data.deletionList[id] = true
end

---@return boolean
function this.isIdInDeletionList(id)
    return this.data.deletionList[id]
end

function this.removeIdFromDeletionList(id)
    this.data.deletionList[id] = nil
end

function this.loadData(data)
    this.data = data
end

function this.getData()
    return this.data
end

return this