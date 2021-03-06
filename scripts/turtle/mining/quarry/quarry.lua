local stringDigWidth = arg[1]
local stringStartY = arg[2]
local noDeposit = arg[3]
local DIG_WIDTH
if (stringDigWidth == nil) then
    DIG_WIDTH = 15
else
    DIG_WIDTH = tonumber(stringDigWidth) - 1
end

local START_Y
if (stringStartY == nil) then
    START_Y = 0
else
    START_Y = tonumber(stringStartY)
end

if (noDeposit ~= nil) then
    noDeposit = string.lower(noDeposit)
end
local needToDeposit = noDeposit ~= "nodeposit"

local POSITIVE_X = "positive_x"
local NEGATIVE_X = "negative_x"
local POSITIVE_Z = "positive_z"
local NEGATIVE_Z = "negative_z"

local relativeX = 0
local relativeY = 0
local relativeZ = 0

local START_ORIENTATION = POSITIVE_X
local relativeOrientation = START_ORIENTATION

local nextTurnIsRight = true

local movedX = 0
local movedZ = 0
local canMove = true

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
    if needToDeposit then
        for i = 1, 16 do
            if turtle.getItemCount(i) == 0 then
                return false
            end
        end
    
        return true
    else
        return false
    end
end

function travelTo(x, y, z)
    if x ~= relativeX or y ~= relativeY or z ~= relativeZ then
        local toTravelY = y - relativeY
        local goUp = toTravelY > 0
        for _ = 1, math.abs(toTravelY) do
            if (goUp) then
                digAndMoveUp()
            else
                digAndMoveDown()
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
    if (needToDeposit) then
        turnLeft()
        turnLeft()
        for i = 1, 16 do
            turtle.select(i)
            turtle.drop()
        end
        turnRight()
        turnRight()
    end
end

function resupply()
    refuel()
    travelTo(0, 0, 0)
    orientate(START_ORIENTATION)
    deposit()
    refuelFromStation()
end

function execute()
    resupply()

    for _ = 1, math.abs(START_Y) do
        if START_Y > 0 then
            digAndMoveUp()
        else
            digAndMoveDown()
        end
    end

    while canMove do
        turtle.select(1)
        if needToRefuel() then
            refuel()
        end
        
        if needToRefuel() or isInventoryFull() then
            local currentX = relativeX
            local currentY = relativeY
            local currentZ = relativeZ
            local currentOrientation = relativeOrientation
            resupply()
            travelTo(currentX, currentY, currentZ)
            orientate(currentOrientation)
        end

        canMove = forward()
        if canMove then
            movedX = movedX + 1

            if movedX == DIG_WIDTH then
                movedX = 0
                if movedZ == DIG_WIDTH then
                    movedZ = 0
                    nextTurnIsRight = not nextTurnIsRight
                    turn(nextTurnIsRight)
                    canMove = digAndMoveDown()
                else
                    turn(nextTurnIsRight)
                    canMove = forward()
                    if canMove then
                        turn(nextTurnIsRight)
                        movedZ = movedZ + 1
                        nextTurnIsRight = not nextTurnIsRight
                    end
                end
            end
        end
    end

    travelTo(0, 0, 0)
    orientate(START_ORIENTATION)
    deposit()
end

execute()
