local core = require('openmw.core')
local interfaces = require('openmw.interfaces')
local ui = require('openmw.ui')
local async = require('openmw.async')

local pendingFreedCount = nil

local function showFreedMessage(count)
    ui.showMessage(
        'You freed '
        .. tostring(count)
        .. ' slaves.'
    )
end

local function onDialogueResponse(data)
    if data.type ~= 'topic' then
        return
    end

    if data.recordId:lower() ~= 'go free' then
        return
    end

    core.sendGlobalEvent('FreeThemAll_TryBatchRelease', {
        actor = data.actor,
    })
end

local function onQueueNotification(data)
    local count = data.count

    if not count or count < 2 then
        return
    end

    -- Normally the result arrives while dialogue is still open.
    if interfaces.UI.getMode() == 'Dialogue' then
        pendingFreedCount = count
    else
        -- Fallback in case event ordering changes or another mod closes
        -- the dialogue immediately.
        showFreedMessage(count)
    end
end

local function onUiModeChanged(data)
    if not pendingFreedCount then
        return
    end

    if data.oldMode == 'Dialogue'
        and data.newMode ~= 'Dialogue'
    then
        local count = pendingFreedCount
        pendingFreedCount = nil

        async:newUnsavableSimulationTimer(1.0, function()
            showFreedMessage(count)
        end)
    end
end

return {
    eventHandlers = {
        DialogueResponse = onDialogueResponse,
        FreeThemAll_QueueNotification = onQueueNotification,
        UiModeChanged = onUiModeChanged,
    },
}