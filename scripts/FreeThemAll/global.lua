local world = require('openmw.world')

local config = require('scripts/FreeThemAll/config')
local slaves = require('scripts/FreeThemAll/slaves')

local CHECK_INTERVAL = 0.25

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

local function checkSlaves()
    for _, actor in ipairs(world.activeActors) do
        local script = slaves.getSlaveScript(actor)

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

            -- Always track the transition, even while the mod is disabled.
            previousStatuses[actor.id] = currentStatus

            if previousStatus ~= nil
                and previousStatus ~= 3
                and currentStatus == 3
            then
                if not config.isEnabled() then
                    print(
                        '[FreeThemAll] Manual release detected while disabled: '
                        .. actor.recordId
                    )
                    return
                end

                if config.excludedTriggers[actor.recordId] then
                    print(
                        '[FreeThemAll] Special trigger skipped: '
                        .. actor.recordId
                    )
                    return
                end

                local counterBefore = getFreedSlavesCounter()

                local freedCount, eligibleCount = slaves.freeAdditionalSlaves {
                    freedSlave = actor,
                    player = player,
                    previousStatuses = previousStatuses,
                    excludedTargets = config.excludedTargets,
                    maxAdditionalSlaves = config.maxAdditionalSlaves,
                }

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
                    showMessage('Free Them All: freed 1 additional slave.')
                elseif freedCount > 1 then
                    showMessage(
                        'Free Them All: freed '
                        .. tostring(freedCount)
                        .. ' additional slaves.'
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
