local addonName, XarUI = ...

XarUI.modules = {}

local eventHandler = CreateFrame("Frame", nil, UIParent)
eventHandler:SetScript("OnEvent", function(self, event, ...) return self[event](self, ...) end)
eventHandler:RegisterEvent("ADDON_LOADED")

XarUI.defaultSettings = {
	profile = {
	},
}

XarUI.optionsTable = {
	name = "|cff00c0ffXarUI|r",
	type = "group",
	childGroups = "tab",
	validate = function()
		if InCombatLockdown() then
			return "Must leave combat first."
		else
			return true
		end
	end,
	args = {
	},
}

function XarUI:CreateModule(m)
	self.modules[m] = {}
	return self.modules[m]
end

function XarUI:OnProfileChange()
	for m, _ in pairs(self.modules) do
		self.modules[m].db = self.db.profile[m]
		if self.modules[m].OnProfileChange then
			self.modules[m]:OnProfileChange()
		end
	end
end

function eventHandler:ADDON_LOADED(addon)
	if addon ~= addonName then return end

	local i = 0
	for m, _ in pairs(XarUI.modules) do
		XarUI.optionsTable.args[m] = {
			name = m,
			type = "group",
			order = i,
			get = function(info) return XarUI.modules[m].db[info[#info]] end,
			args = XarUI.modules[m].optionsTable,
		}

		XarUI.defaultSettings.profile[m] = XarUI.modules[m].defaultSettings

		i = i + 1
	end

	XarUI.db = LibStub("AceDB-3.0"):New("XarUIDB", XarUI.defaultSettings, true)
	XarUI.optionsTable.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(XarUI.db)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("XarUI", XarUI.optionsTable)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("XarUI", "|cff00c0ffXarUI|r")
	LibStub("AceConfigDialog-3.0"):SetDefaultSize("XarUI", 420, 400)
	XarUI.db.RegisterCallback(self, 'OnProfileChanged', XarUI.OnProfileChange)
	XarUI.db.RegisterCallback(self, 'OnProfileCopied', XarUI.OnProfileChange)
	XarUI.db.RegisterCallback(self, 'OnProfileReset', XarUI.OnProfileChange)

	SLASH_XARUI1 = "/xarui"
	SLASH_XARUI2 = "/xar"
	SlashCmdList["XARUI"] = function() LibStub("AceConfigDialog-3.0"):Open("XarUI") end

	for m, _ in pairs(XarUI.modules) do
		XarUI.modules[m].db = XarUI.db.profile[m]
		if XarUI.modules[m].OnLoad then
			XarUI.modules[m]:OnLoad()
		end
	end
end
