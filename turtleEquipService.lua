--@requires log
--@requires turtleController
--@requires settingsManager
--@requires turtleResourceManager

---@class Log
local log = require("./libs/log")
---@class turtleController
local t = require("./libs/turtleController")
---@class SettingManager
local settingsManager = require("./libs/settingsManager")

---@class TurtleEquipService
--- ### settings used:
--- - turtleEquipServicePrefix
--- - equipableSlots
local turtleEquipService = {}

---@alias equipPosition
--- | "left"
--- | "right"
--- | nil

---@class EquipableSlot
---@field position equipPosition
---@field slotNo number

---@class EquipableSlots
---@field item EquipableSlot

---@type EquipableSlots
local defaultEquipableSlots = {
    ["advancedperipherals:chunk_controller"] = {
        position = "left",
        slotNo = 3
    },
    ["minecraft:diamond_pickaxe"] = {
        position = "right",
        slotNo = 4
    },
    ["minecraft:diamond_hoe"] = {
        position = "right",
        slotNo = 4
    },
    ["minecraft:diamond_axe"] = {
        position = "right",
        slotNo = 4
    },
    ["computercraft:wireless_modem"] = {
        position = "right",
        slotNo = 5
    },
    ["computercraft:wireless_modem_advanced"] = {
        position = "right",
        slotNo = 5
    },
    ["advancedperipherals:geo_scanner"] = {
        position = "left",
        slotNo = 6
    }
}

local function errorHandler(content, oldSlot)
    local prefix = settingsManager.setget('turtleEquipServicePrefix', nil, '[turtleEquipService] :')
    if type(content) == "table" then
        content = textutils.serialise(content)
    end
    if type(content) == "string" or type(content) == "number" then
        content = prefix .. content .. '\n'
    end
    log.ErrorHandler(content, nil, false)
    if oldSlot then
        turtle.select(oldSlot)
    end
end

local function fixNoSlotToDumpCurrent()
end

local function manageFreeSlotAvailable()

    ---comment
    ---@return boolean successfull
    ---@return any result error | table {number, string}
    local function makeSlotFree()
        ---adds the required items to the "itemsToCeep"
        local function modifySettings()
            local putIntoSlot = settingsManager.setget('equipableSlots', nil, defaultEquipableSlots)
            local sett = settingsManager.setget("ItemsToCeep", nil, putIntoSlot)
            for key, _ in ipairs(putIntoSlot) do
                sett[key] = true
            end
            settingsManager.setget("ItemsToCeep", sett, sett)
        end

        local function tryRequire()
            ---@class TurtleResourceManager
            local tRM = require("./libs/turtleResourceManager")
            modifySettings()
            local result = { pcall(tRM.manageSpace, 1, nil) }
            if not result[1] then
                errorHandler(result[2], nil)
                error(result[2])
            end
            print(textutils.serialise(result[2]))
            if type(result[2]) == "table" then
                return table.unpack(result[2])
            else
                return result[2]
            end
        end

        return pcall(tryRequire)

    end

    local slot = t:findEmptySlot()
    if not slot then
        local madeslotFree = { makeSlotFree() }
        if not madeslotFree[1] or madeslotFree[2] ~= 1 then
            local err = 'Could not switch equiped Item' .. madeslotFree[2]
            errorHandler(err, nil)
            return 3, err
        end
        slot = t:findEmptySlot()
    end
    return 1, slot
end

---equips the specified item in the inventory
---@param item function | string | number | nil : comparefunction | itemDetail.name | slotnumber | just unequip
---@param position equipPosition nil = default behaviour
---@param ... any function parameters
---@return integer status : 1 = succ | 2 = err
---@return string? errorReason
function turtleEquipService.equip(item, position, ...)
    local err
    local currentslot = turtle.getSelectedSlot()
    local status, freeSlot
    if type(item) ~= "string" and type(item) ~= "function" and type(item) ~= "number" and type(item) ~= "nil" then
        err = 'Wrong parameter, got ' .. type(item)
        errorHandler(err, currentslot)
        return 2, err
    end
    local slotNo
    if type(item) == "string" then
        slotNo = t:findItemInInventory(item);
        if not slotNo then
            err = 'Could not find Item: ' .. item
            errorHandler(err, currentslot)
            return 2, err
        end
    elseif type(item) == "function" then
        slotNo = t.findItem(item, table.unpack(arg))
        if not slotNo then
            err = 'Could not find equipable item in inventory'
            errorHandler(err, currentslot)
            return 2, err
        end
    elseif type(item) == "number" and item > 0 and item < 17 then
        slotNo = item
    elseif type(item) == "nil" then
        status, slotNo = manageFreeSlotAvailable()
        if status ~= 1 then
            err = 'No free slot available to get equiped item'
            errorHandler(err, currentslot)
            return 2, err
        end
    else
        err = 'Could not use item Parameter'
        errorHandler(err, currentslot)
        return 2, err
    end
    -- here needs to be a check if no item selected
    turtle.select(slotNo)
    local doEquip = position
    local putIntoSide = settingsManager.setget('equipableSlots', nil, defaultEquipableSlots)
    if not doEquip and turtle.getItemDetail(slotNo) then
        if putIntoSide[turtle.getItemDetail(slotNo).name] then
            doEquip = putIntoSide[turtle.getItemDetail(slotNo).name]
        end
    end
    if doEquip ~= "right" then
        doEquip = turtle.equipLeft
    else
        doEquip = turtle.equipRight
    end
    if not doEquip() then
        err = 'Could not equip Item'
        errorHandler(err, currentslot)
        return 2, err
    end
    local selectedItem = turtle.getItemDetail(slotNo)
    -- if there is data on where to item should land, free the slot and move it there =>
    if selectedItem and selectedItem.name and putIntoSide[selectedItem.name] then
        local itemData = putIntoSide[selectedItem.name]
        if turtle.getItemDetail(itemData.slotNo) then -- is slot occupied
            status, freeSlot = manageFreeSlotAvailable()
            if status ~= 1 then
                err = 'No free slot available to switch equiped items ' .. status
                errorHandler(err, currentslot)
                return 2, err
            end
            turtle.select(itemData.slotNo)
            turtle.transferTo(freeSlot)
            turtle.select(slotNo)
        end
        turtle.transferTo(itemData.slotNo)
    end

    return 1
end

return turtleEquipService
