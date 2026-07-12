local world = require('openmw.world')

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

local function getEligibleAdditionalSlaves(freedSlave, excludedTargets)
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

local function freeAdditionalSlaves(options)
    local candidates = getEligibleAdditionalSlaves(
        options.freedSlave,
        options.excludedTargets
    )

    local globals = world.mwscript.getGlobalVariables(options.player)
    local freedCount = 0

    for index = 1, #candidates do
        local target = candidates[index]
        local script = getSlaveScript(target)

        if script and script.variables.slavestatus == 0 then
            script.variables.slavestatus = 3

            globals.freedslavescounter =
                globals.freedslavescounter + 1

            freedCount = freedCount + 1
        end
    end

    return freedCount, #candidates
end

return {
    getSlaveScript = getSlaveScript,
    freeAdditionalSlaves = freeAdditionalSlaves,
}
