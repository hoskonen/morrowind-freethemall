local world = require('openmw.world')

local CHECK_INTERVAL = 0.25

-- Controlled test: free only one additional slave.
local MAX_ADDITIONAL_SLAVES = 1

-- These actors have unique quest-related "go free" dialogue.
local excludedTargets = {
    ['eleedal_lei'] = true,
    ['dahleena'] = true,
}

-- Eleedal-Lei's dialogue already credits the entire rebellion group.
local excludedTriggers = {
    ['eleedal_lei'] = true,
}

local elapsed = 0
local player = nil
local previousStatuses = {}
local loggedSlaves = {}

local function showMessage(message)
    if player then
        player:sendEvent('ShowMessage', {
            message = message,
        })
    end
end

local function getFreedSlavesCounter()
    local globals = world.mwscript.getGlobalVariables(player)

    return globals.freedslavescounter
end

local function getSlaveScript(actor)
    local script = world.mwscript.getLocalScript(actor)

    if not script or not script.recordId then
        return nil
    end

    if script.recordId:lower() ~= 'slavescript' then
        return nil
    end

    return script
end

local function isSameCell(firstActor, secondActor)
    local firstCell = firstActor.cell
    local secondCell = secondActor.cell

    if not firstCell or not secondCell then
        return false
    end

    if firstCell.isExterior ~= secondCell.isExterior then
        return false
    end

    if firstCell.isExterior then
        return firstCell.gridX == secondCell.gridX
            and firstCell.gridY == secondCell.gridY
            and firstCell.worldSpaceId == secondCell.worldSpaceId
    end

    return firstCell.id == secondCell.id
end

local function getEligibleAdditionalSlaves(freedSlave)
    local candidates = {}

    for _, actor in ipairs(world.activeActors) do
        if actor.id ~= freedSlave.id
            and isSameCell(actor, freedSlave)
            and not excludedTargets[actor.recordId]
        then
            local script = getSlaveScript(actor)

            if script and script.variables.slavestatus == 0 then
                table.insert(candidates, actor)
            end
        end
    end

    return candidates
end

local function freeAdditionalSlaves(freedSlave)
    local candidates = getEligibleAdditionalSlaves(freedSlave)
    local globals = world.mwscript.getGlobalVariables(player)

    local numberToFree = math.min(
        MAX_ADDITIONAL_SLAVES,
        #candidates
    )

    local freedCount = 0

    for index = 1, numberToFree do
        local target = candidates[index]
        local script = getSlaveScript(target)

        if script and script.variables.slavestatus == 0 then
            script.variables.slavestatus = 3

            -- Mark it immediately so our detector does not treat this
            -- automatically freed slave as a new manual trigger.
            previousStatuses[target.id] = 3

            globals.freedslavescounter =
                globals.freedslavescounter + 1

            freedCount = freedCount + 1

            print(
                '[FreeThemAll] Automatically freed slave: '
                .. target.recordId
            )
        end
    end

    return freedCount, #candidates
end

local function checkSlaves()
    for _, actor in ipairs(world.activeActors) do
        local script = getSlaveScript(actor)

        if script then
            local currentStatus = script.variables.slavestatus

            if not loggedSlaves[actor.id] then
                loggedSlaves[actor.id] = true

                print(
                    '[FreeThemAll] Found slave: actor='
                    .. actor.recordId
                    .. ', script='
                    .. script.recordId
                    .. ', status='
                    .. tostring(currentStatus)
                )
            end

            local previousStatus = previousStatuses[actor.id]

            -- Record the current status immediately.
            -- This must happen before any return statement.
            previousStatuses[actor.id] = currentStatus

            if previousStatus ~= nil
                and previousStatus ~= 3
                and currentStatus == 3
            then
                if excludedTriggers[actor.recordId] then
                    print(
                        '[FreeThemAll] Special trigger skipped: '
                        .. actor.recordId
                    )

                    return
                end

                local counterBefore = getFreedSlavesCounter()

                local freedCount, eligibleCount =
                    freeAdditionalSlaves(actor)

                local counterAfter = getFreedSlavesCounter()

                print(
                    '[FreeThemAll] Manual slave detected: '
                    .. actor.recordId
                    .. ', eligible additional slaves='
                    .. tostring(eligibleCount)
                    .. ', automatically freed='
                    .. tostring(freedCount)
                    .. ', counter before auto-free='
                    .. tostring(counterBefore)
                    .. ', counter after auto-free='
                    .. tostring(counterAfter)
                )

                if freedCount == 1 then
                    showMessage(
                        'Free Them All: freed 1 additional slave.'
                    )
                else
                    showMessage(
                        'Free Them All: no additional slaves freed.'
                    )
                end

                return
            end
        end
    end
end

local function onPlayerAdded(addedPlayer)
    player = addedPlayer

    previousStatuses = {}
    loggedSlaves = {}

    print('[FreeThemAll] Global script is running')

    print(
        '[FreeThemAll] FreedSlavesCounter at load='
        .. tostring(getFreedSlavesCounter())
    )

    showMessage('Free Them All: script loaded successfully')
end

local function onUpdate(dt)
    elapsed = elapsed + dt

    if elapsed < CHECK_INTERVAL then
        return
    end

    elapsed = elapsed - CHECK_INTERVAL

    checkSlaves()
end

return {
    engineHandlers = {
        onPlayerAdded = onPlayerAdded,
        onUpdate = onUpdate,
    },
}