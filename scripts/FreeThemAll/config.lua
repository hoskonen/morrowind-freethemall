local interfaces = require('openmw.interfaces')
local storage = require('openmw.storage')

local GROUP_KEY = 'SettingsGlobalFreeThemAll'

interfaces.Settings.registerGroup {
    key = GROUP_KEY,
    page = 'FreeThemAll',
    l10n = 'FreeThemAll',
    name = 'group_name',
    description = 'group_description',
    permanentStorage = true,
    settings = {
        {
            key = 'enabled',
            renderer = 'checkbox',
            name = 'enabled_name',
            description = 'enabled_description',
            default = true,
        },
    },
}

local settings = storage.globalSection(GROUP_KEY)

local excludedTargets = {
    ['eleedal_lei'] = true,
    ['dahleena'] = true,
}

local excludedTriggers = {
    ['eleedal_lei'] = true,
}

return {
    maxAdditionalSlaves = 1,

    excludedTargets = excludedTargets,
    excludedTriggers = excludedTriggers,

    isEnabled = function()
        return settings:get('enabled') ~= false
    end,
}