require "lib"

local metarecipe = copyPrototype("recipe", "inserter", "farl-meta")
metarecipe.ingredients = {}
metarecipe.enabled = false
metarecipe.hidden = true

--local metaitem = copyPrototype("deconstruction-item", "deconstruction-planner", "farl-meta")
--table.insert(metaitem.flags, "hidden")
--metarecipe.result = "farl-meta"
local vanilla = {["small-electric-pole"]=true, ["medium-electric-pole"]=true, ["big-electric-pole"]=true, ["substation"]=true}

for name, _ in pairs(vanilla) do
  table.insert(metarecipe.ingredients, {name, data.raw["electric-pole"][name].maximum_wire_distance*10})
end

for _, ent in pairs(data.raw["electric-pole"]) do
  if ent.minable and ent.maximum_wire_distance and ent.maximum_wire_distance > 0 and not vanilla[ent.name] then
    local item_name = false
    local item = data.raw["item"][ent.name]
    if item and item.place_result and item.place_result == ent.name then
      item_name = ent.name
    else
      -- item and entity name don't match
      --check if mining result matches an item that has entity as place result
      if ent.minable.result and type(ent.minable.result) == "string" then
        local result = data.raw["item"][ent.minable.result]
        if result and result.place_result and result.place_result == ent.name then
          item_name = result.place_result
        else
          --assume it's some proxy item, don't add it
          item_name = false
          log("FARL: No item found for pole: "..ent.name)
        end
      end
    end
    if item_name then
      table.insert(metarecipe.ingredients, {item_name, ent.maximum_wire_distance*10})
    end
  end
end

data:extend({metarecipe})

local updatedGrids = {}

local function addFarlCategory(equipmentGridName)
  local equipmentGrid = data.raw["equipment-grid"][equipmentGridName]
  if equipmentGrid and equipmentGrid.equipment_categories and not updatedGrids[equipmentGrid.name] then
    local found = false
    for _, category in pairs(equipmentGrid.equipment_categories) do
      if category == "farl-equipment" then
        found = true
        break
      end
    end
    if not found then
      table.insert(equipmentGrid.equipment_categories, "farl-equipment")
      updatedGrids[equipmentGrid.name] = true
    end
  end
end

--add grid to farl if one is present and FARL doesn't already have one
if data.raw["locomotive"]["locomotive"].equipment_grid and not data.raw["locomotive"]["farl"].equipment_grid then
  data.raw["locomotive"]["farl"].equipment_grid = data.raw["locomotive"]["locomotive"].equipment_grid
end

for locoName, loco in pairs(data.raw.locomotive) do
  if locoName ~= "farl" then
    if not loco.equipment_grid then
      loco.equipment_grid = "farl-equipment-grid"
    else
      addFarlCategory(loco.equipment_grid)
    end
  end
  --log("Loco: " .. locoName .. " " .. serpent.line(loco.equipment_grid, {comment=false}))
end
--[[
for wagonName, wagon in pairs(data.raw["cargo-wagon"]) do
  if not wagon.equipment_grid then
    wagon.equipment_grid = "farl-equipment-grid-wagon"
  else
    addFarlCategory(wagon.equipment_grid)
  end
end]]--
