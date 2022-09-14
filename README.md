# turtleEquipService-lua

Service that handles all equiped slots of a turtle

## function

```lua
function turtleEquipService.equip(item, position, ...)
```

- @param `item` function | string | number | nil
  - comparefunction | itemDetail.name | slotnumber | just unequip
- @param `position` equipPosition nil = default behaviour
- @param `...` any function parameters
- @return `integer` status : 1 = succ | 2 = err
- @return `string?` errorReason

## settings used:

- turtleEquipServicePrefix
- equipableSlots

### definitions for settings:

#### equipableSlots:

```lua
local equipableSlots = {
    ["advancedperipherals:chunk_controller"] = {
        position = "left",
        slotNo = 3
    },
    ["minecraft:diamond_pickaxe"] = {
        position = "right",
        slotNo = 4
    },...
```
