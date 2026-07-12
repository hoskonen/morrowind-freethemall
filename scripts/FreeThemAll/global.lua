local world = require('openmw.world')

local config = require('scripts/FreeThemAll/config')
local slaves = require('scripts/FreeThemAll/slaves')

local player = nil
local processedActors = {}

local function debugLog(message)
    if config.isDebugEnabled() then
        print('[FreeThemAll] ' .. message)
    end
end

local function getFreedSlavesCounter()
    local globals = world.mwscript.getGlobalVariables(player)
    return globals.freedslavescounter
end

local function onTryBatchRelease(data)
    local actor = data.actor

    if not actor then
        debugLog('Dialogue event did not contain an actor.')
        return
    end

    -- Prevent duplicate processing if the same dialogue response is
    -- emitted more than once.
    if processedActors[actor.id] then
        debugLog(
            'Ignoring duplicate release event for '
            .. actor.recordId
        )
        return
    end

    local script = slaves.getSlaveScript(actor)

    if not script then
        debugLog(
            'Go free response came from non-standard slave: '
            .. actor.recordId
        )
        return
    end

    local currentStatus = script.variables.slavestatus

    -- This also verifies that the player chose the actual unlock response,
    -- rather than merely opening the "go free" topic.
    if currentStatus ~= 3 then
        debugLog(
            'Go free response observed before release for '
            .. actor.recordId
            .. ', slaveStatus='
            .. tostring(currentStatus)
        )
        return
    end

    processedActors[actor.id] = true

    if not config.isEnabled() then
        debugLog(
            'Manual release detected while disabled: '
            .. actor.recordId
        )
        return
    end

    if config.excludedTriggers[actor.recordId] then
        debugLog(
            'Special trigger skipped: '
            .. actor.recordId
        )
        return
    end

    local counterBefore = getFreedSlavesCounter()

    local freedCount, eligibleCount =
        slaves.freeAdditionalSlaves {
            freedSlave = actor,
            player = player,
            excludedTargets = config.excludedTargets,
        }

    local counterAfter = getFreedSlavesCounter()

    debugLog(
        'Manual slave detected: '
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

    if freedCount > 0 then
        player:sendEvent(
            'FreeThemAll_QueueNotification',
            {
                count = freedCount + 1,
            }
        )
    end
end

local function onPlayerAdded(addedPlayer)
    player = addedPlayer
    processedActors = {}

    debugLog(
        'Global script loaded. FreedSlavesCounter='
        .. tostring(getFreedSlavesCounter())
    )
end

return {
    engineHandlers = {
        onPlayerAdded = onPlayerAdded,
    },

    eventHandlers = {
        FreeThemAll_TryBatchRelease = onTryBatchRelease,
    },
}