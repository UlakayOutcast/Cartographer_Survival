local bs = AceLibrary("Babble-Spell-2.2")
local AceAddon = AceLibrary("AceAddon-2.0")
local Tablet = AceLibrary("Tablet-2.0")
local Deformat = AceLibrary("Deformat-2.0")
local L = {}

local L = AceLibrary("AceLocale-2.2"):new("Cartographer_Survival")
L:RegisterTranslations("enUS", function() return {
    ["Requires Survival"] = true,
    
    ["Filter"] = true,
    ["Filter out trees"] = true,
    
    ["Select all"] = true,
    ["Select none"] = true,

	["Survival"] = true,
		
    -- Woods,
    -- ["Simple Wood Tree (Teldrassil)"] = true,
    ["Simple Wood Tree"] = true,
    ["Bright Wood Tree"] = true,
} end)

L:RegisterTranslations("ruRU", function() return {
    ["Requires Survival"] = "Ben\195\182tigt Kr\195\164uterkunde",
    
    ["Filter"] = "Фильтр",
    ["Filter out trees"] = "Отфильтровать деревья",
    
    ["Select all"] = "Выбрать все",
    ["Select none"] = "Выбрать нет",

	["Survival"] = true,
	["Cut Wood"] = true,
	
    -- Woods
    -- ["Simple Wood Tree (Teldrassil)"] = "Простое дерево",
    ["Simple Wood Tree"] = "Простое дерево",
    ["Bright Wood Tree"] = "Светлое дерево",
} end)

local mod = Cartographer:NewModule("Survival", "AceConsole-2.0", "AceEvent-2.0")

mod.icon = {
    -- ["Simple Wood Tree (Teldrassil)"] = {
        -- text = L["Simple Wood Tree (Teldrassil)"],
        -- path = "Interface\\Icons\\simple_wood_1",
        -- width = 12,
        -- height = 12
    -- },
    ["Simple Wood Tree"] = {
        text = L["Simple Wood Tree"],
        path = "Interface\\Icons\\simple_wood_1",
        width = 12,
        height = 12
    },
    ["Bright Wood Tree"] = {
        text = L["Bright Wood Tree"],
        path = "Interface\\Icons\\simple_wood_1",
        width = 12,
        height = 12
    },
}

local lua51 = loadstring("return function(...) return ... end") and true or false
function mod:OnInitialize()
	self.db = Cartographer:AcquireDBNamespace("Survival")
    Cartographer:RegisterDefaults("Survival", "profile", {
		filter = {
			['*'] = true,
		}
    })
	
    local aceopts = {}
    aceopts.toggle = {
		name = AceLibrary("AceLocale-2.2"):new("Cartographer")["Active"],
		desc = AceLibrary("AceLocale-2.2"):new("Cartographer")["Suspend/resume this module."],
        type  = 'toggle',
        order = -1,
        get   = function() return Cartographer:IsModuleActive(self) end,
        set   = function() Cartographer:ToggleModuleActive(self) end,
    }
    aceopts.filter = {
		name = L["Filter"],
		desc = L["Filter out trees"],
		type = 'group',
		args = {
			all = {
				name = L["Select all"],
				desc = L["Select all"],
				type = 'execute',
				func = function()
					for k in pairs(self.icon) do
						self:ToggleShowingTree(k, true)
					end
				end,
				order = 1,
			},
			none = {
				name = L["Select none"],
				desc = L["Select none"],
				type = 'execute',
				func = function()
					for k in pairs(self.icon) do
						self:ToggleShowingTree(k, false)
					end
				end,
				order = 2,
			},
			blank = {
				type = 'header',
				order = 3,
			}
		}
    }
    for k,v in pairs(self.icon) do
		local k = k
		aceopts.filter.args[string.gsub(k, "%s", "-")] = {
			name = v.text,
			desc = v.text,
			type = 'toggle',
			get = function()
				return self:IsShowingTree(k)
			end,
			set = function(value)
				return self:ToggleShowingTree(k, value)
			end,
		}
    end

    Cartographer.options.args[gsub(bs["Survival"], " ", "")] = {
        name = bs["Survival"],
        desc = self.notes,
        type = 'group',
        args = aceopts,
        handler = self,
    }
    AceLibrary("AceConsole-2.0"):InjectAceOptionsTable(self, Cartographer.options.args[gsub(bs["Survival"], " ", "")])
    Cartographer:GetModule('Professions').addons[bs["Survival"]] = self

    if not Cartographer_SurvivalDB then
        Cartographer_SurvivalDB = {}
    else
		for _, zone in pairs(Cartographer_SurvivalDB) do
			for id, data in pairs(zone) do
				if type(data) == "table" then
					zone[id] = data.icon
				end
			end
		end
    end
end

function mod:OnEnable()
    if Cartographer_Notes then
        if not self.iconsregistered then
            for k,v in pairs(self.icon) do
                Cartographer_Notes:RegisterIcon(k, v)
            end
            self.iconsregistered = true
        end

        Cartographer_Notes:RegisterNotesDatabase('Survival', Cartographer_SurvivalDB, self)
    else
        Cartographer:ToggleModuleActive(self, false)
    end

    self:RegisterEvent("UI_ERROR_MESSAGE")

    if lua51 then
        self:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF")
    else
        self:RegisterEvent("SPELLCAST_START")
    end
end

function mod:OnDisable()
    self:UnregisterAllEvents()

    if Cartographer_Notes then
        Cartographer_Notes:UnregisterNotesDatabase('Survival')
    end
end

-- function mod:SetNote(what)
    -- local x, y = GetPlayerMapPosition("player")
    -- if x == 0 and y == 0 then return end
    -- local zone = GetRealZoneText()
    -- local _,_,w = string.find(what, "^(.-) %(%d+%)$")
    -- if w then
		-- what = w
	-- end
    -- Cartographer_Notes:SetNote(zone, x, y, L:GetReverseTranslation(what), "Survival")
-- end
function mod:SetNote(what)
    local x, y = GetPlayerMapPosition("player")
    if x == 0 and y == 0 then return end
    local zone = GetRealZoneText()

    -- Извлекаем название дерева без зоны
    local startPos, endPos = string.find(what, "%(")
    local treeName = what
    if startPos then
        treeName = string.sub(what, 1, startPos - 2)
    end

    Cartographer_Notes:SetNote(zone, x, y, treeName, "Survival")
end


function mod:OnNoteTooltipRequest(zone, id)
	local icon = Cartographer_SurvivalDB[zone][id]
	
	Tablet:SetTitle(L[icon])
	Tablet:SetTitleColor(0, 0.8, 0)
	
	Tablet:AddCategory(
		'columns', 2,
		'hideBlankLine', true
	):AddLine(
		'text', AceLibrary("AceLocale-2.2"):new("Cartographer-Notes")["Created by"],
		'text2', bs["Survival"]
	)
end

local perform_string = '^' .. string.gsub(string.gsub(string.format(SIMPLEPERFORMSELFOTHER, bs["Cut Wood"], "%s"), "([%(%)%.%*%+%-%[%]%?%^%$%%])", "%%%1"), "%%%%s", "(.+)") .. '$'
function mod:CHAT_MSG_SPELL_SELF_BUFF(msg)
    local _,_,what = string.find(msg, perform_string)
    if what then
        self:SetNote(what)
    end
end

function mod:UI_ERROR_MESSAGE(msg)
    -- if string.find(msg, UNIT_SKINNABLE_HERB) then -- TBC only
    if string.find(msg, L["Requires Survival"]) then
        local what = GameTooltipTextLeft1:GetText()
        if what and strlen(what) > 0 then
            self:SetNote(what)
        end
    end
end

function mod:SPELLCAST_START(msg)
    if msg == bs["Cut Wood"] then
        local what = GameTooltipTextLeft1:GetText()
        if what and strlen(what) > 0 then
            self:SetNote(what)
        end
    end
end

function mod:IsNoteHidden(zone, id)
	return not self.db.profile.filter[Cartographer_SurvivalDB[zone][id]]
end

function mod:IsShowingTree(herb)
	return self.db.profile.filter[herb]
end

function mod:ToggleShowingTree(herb, value)
	if value == nil then
		value = not self.db.profile.filter[herb]
	end
	self.db.profile.filter[herb] = value
	
	self:ScheduleEvent("CartographerSurvival_RefreshMap", Cartographer_Notes.RefreshMap, 0, Cartographer_Notes)
end
