local stringDigWidth = arg[1]
local DIG_WIDTH
if (stringDigWidth == nil) then
    DIG_WIDTH = 16
else
    DIG_WIDTH = math.max(tonumber(stringDigWidth), 6)
end

local POSITIVE_X = "positive_x"
local NEGATIVE_X = "negative_x"
local POSITIVE_Z = "positive_z"
local NEGATIVE_Z = "negative_z"

local relativeX = 0
local relativeY = 0
local relativeZ = 0

local START_ORIENTATION = POSITIVE_X
local relativeOrientation = START_ORIENTATION

function forward()
    local moved = turtle.forward()
    if not moved then
        turtle.dig()
        moved = turtle.forward()
    end

    if (moved) then
        if relativeOrientation == POSITIVE_X then
            relativeX = relativeX + 1
        elseif relativeOrientation == NEGATIVE_X then
            relativeX = relativeX - 1
        elseif relativeOrientation == POSITIVE_Z then
            relativeZ = relativeZ + 1
        elseif relativeOrientation == NEGATIVE_Z then
            relativeZ = relativeZ - 1
        end
    end

    return moved
end

function digAndMoveDown()
    local moved = turtle.down()
    if not moved then
        turtle.digDown()
        moved = turtle.down()
    end

    if (moved) then
        relativeY = relativeY - 1
    end

    return moved
end

function digAndMoveUp()
    local moved = turtle.up()
    if not moved then
        turtle.digUp()
        moved = turtle.up()
    end

    if (moved) then
        relativeY = relativeY + 1
    end

    return moved
end

function turnRight()
    turtle.turnRight()

    if relativeOrientation == POSITIVE_X then
        relativeOrientation = POSITIVE_Z
    elseif relativeOrientation == POSITIVE_Z then
        relativeOrientation = NEGATIVE_X
    elseif relativeOrientation == NEGATIVE_X then
        relativeOrientation = NEGATIVE_Z
    elseif relativeOrientation == NEGATIVE_Z then
        relativeOrientation = POSITIVE_X
    end
end

function turnLeft()
    turtle.turnLeft()

    if relativeOrientation == POSITIVE_X then
        relativeOrientation = NEGATIVE_Z
    elseif relativeOrientation == NEGATIVE_Z then
        relativeOrientation = NEGATIVE_X
    elseif relativeOrientation == NEGATIVE_X then
        relativeOrientation = POSITIVE_Z
    elseif relativeOrientation == POSITIVE_Z then
        relativeOrientation = POSITIVE_X
    end
end

function turn(right)
    if right then
        turnRight()
    else
        turnLeft()
    end
end

function orientate(direction)
    while relativeOrientation ~= direction do
        turnRight()
    end
end

function faceTowardsX(x)
    local direction
    if x - relativeX > 0 then
        direction = POSITIVE_X
    else
        direction = NEGATIVE_X
    end

    orientate(direction)
end

function faceTowardsZ(z)
    local direction
    if z - relativeZ > 0 then
        direction = POSITIVE_Z
    else
        direction = NEGATIVE_Z
    end

    orientate(direction)
end

function needToRefuel()
    local distanceBack = relativeX + relativeY + relativeZ
    return distanceBack * 2 >= turtle.getFuelLevel()
end

function isInventoryFull()
    for i = 1, 16 do
        if turtle.getItemCount(i) == 0 then
            return false
        end
    end

    return true
end

function travelTo(x, y, z)
    if x ~= relativeX or y ~= relativeY or z ~= relativeZ then
        local toTravelY = math.abs(y - relativeY)
        if (y > relativeY) then
            for _ = 1, toTravelY do
                digAndMoveUp()
            end
        end

        faceTowardsX(x)
        local toTravelX = x - relativeX
        for _ = 1, math.abs(toTravelX) do
            forward()
        end

        faceTowardsZ(z)
        local toTravelZ = z - relativeZ
        for _ = 1, math.abs(toTravelZ) do
            forward()
        end

        if (y < relativeY) then
            for _ = 1, toTravelY do
                digAndMoveDown()
            end
        end
    end
end

function refuel()
    for i = 1, 16 do
        if turtle.getFuelLevel() < turtle.getFuelLimit() then
            turtle.select(i)
            for _ = 1, turtle.getItemCount() do
                if turtle.getFuelLevel() < turtle.getFuelLimit() then
                    turtle.refuel(1)
                else
                    break
                end
            end
        else
            break
        end
    end
end

function refuelFromStation()
    turtle.select(1)
    local hasMoreItems = true
    while turtle.getFuelLevel() < turtle.getFuelLimit() and hasMoreItems do
        hasMoreItems = turtle.suckUp(1)
        refuel()
    end
end

function deposit()
    turnLeft()
    turnLeft()
        for i = 1, 16 do
            turtle.select(i)
            turtle.drop()
        end
    turnRight()
    turnRight()
end

function resupply()
    refuel()
    travelTo(0, 0, 0)
    orientate(START_ORIENTATION)
    deposit()
    refuelFromStation()
end

function resupplyAndReturn()
    local currentX = relativeX
    local currentY = relativeY
    local currentZ = relativeZ
    local currentOrientation = relativeOrientation
    resupply()
    travelTo(currentX, currentY, currentZ)
    orientate(currentOrientation)
end

function digOres()
    local movedDown = 0
    local wentDown = true
    while wentDown do
        if needToRefuel() or isInventoryFull() then
            resupplyAndReturn()
        end

        wentDown = digAndMoveDown()

        if wentDown then
            for _ = 1, 4 do
                local success, data = turtle.inspect()
                if success then
                    if string.find(data.name, "ore") then
                        turtle.dig()
                    end
                end
                turnRight()
            end

            movedDown = movedDown + 1
        end
    end

    for _ = 1, movedDown do
        digAndMoveUp()
    end
end

function digLane()
    for i = 1, DIG_WIDTH - 1 do
        if needToRefuel() then
            refuel()
        end

        if i == digIndex then
            digOres()
            digIndex = digIndex + 5
        end

        forward()
    end
end

function execute()
    resupply()

    local turnBack = true
    local digIndex = 1
    for i = 1, DIG_WIDTH do
        for j = 1, DIG_WIDTH - 1 do
            if needToRefuel() then
                refuel()
            end

            if j == digIndex then
                digOres()
                digIndex = digIndex + 5
            end

            forward()
        end

        if digIndex == DIG_WIDTH then
            digOres()
        end

        if (i ~= DIG_WIDTH) then
            local newDigIndex
            if (turnBack) then
                turnRight()
                forward()
                turnRight()

                newDigIndex = digIndex + 3
                if newDigIndex > DIG_WIDTH then
                    newDigIndex = digIndex - 2
                end
            else
                turnLeft()
                forward()
                turnLeft()

                newDigIndex = digIndex + 2
                if (newDigIndex > DIG_WIDTH) then
                    newDigIndex = digIndex - 3
                end
            end

            digIndex = DIG_WIDTH - newDigIndex + 1
            turnBack = not turnBack

            while digIndex <= 0 do
                digIndex = digIndex + 5
            end
        end
    end

    travelTo(0, 0, 0)
    orientate(START_ORIENTATION)
    deposit()
end

execute()
