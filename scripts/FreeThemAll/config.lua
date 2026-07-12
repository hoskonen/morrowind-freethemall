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
        {
            key = 'debug',
            renderer = 'checkbox',
            name = 'debug_name',
            description = 'debug_description',
            default = false,
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
    excludedTargets = excludedTargets,
    excludedTriggers = excludedTriggers,

    isEnabled = function()
        return settings:get('enabled') ~= false
    end,

    isDebugEnabled = function()
        return settings:get('debug') == true
    end,
}