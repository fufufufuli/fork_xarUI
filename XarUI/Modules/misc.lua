local _, XarUI = ...
local m = XarUI:CreateModule("Misc")

local eventHandler = CreateFrame("Frame", nil , UIParent)
eventHandler:SetScript("OnEvent", function(self, event, ...) return self[event](self, ...) end)

function m:OnLoad()
	-- Short slash command to reload UI
	SLASH_XARUI_RELOAD1 = "/rl"
	SlashCmdList["XARUI_RELOAD"] = ReloadUI

	-- Hide minimap zoom icons
	MinimapZoomIn:Hide()
	MinimapZoomOut:Hide()

	-- Enable zooming on minimap with scrollwheel
	Minimap:EnableMouseWheel(true)
	Minimap:SetScript("OnMouseWheel", function(self, arg1)
		if arg1 > 0 then
			Minimap_ZoomIn()
		else
			Minimap_ZoomOut()
		end
	end)

	-- Alert system for posture checks
	self.alertSystem = AlertFrame:AddSimpleAlertFrameSubSystem("EntitlementDeliveredAlertFrameTemplate", self.AlertSystem_Setup)

	-- Dampening indicator for arena. using the eventHandler frame because why not
	local updateInterval = 5
	local dampeningText = GetSpellInfo(110310)
	eventHandler:SetSize(200, 12)
	eventHandler:SetPoint("TOP", UIWidgetTopCenterContainerFrame, "BOTTOM", 0, -2)
	eventHandler.text = eventHandler:CreateFontString(nil, "BACKGROUND")
	eventHandler.text:SetFontObject(GameFontNormalSmall)
	eventHandler.text:SetAllPoints()
	eventHandler.timeSinceLastUpdate = 0

	eventHandler:SetScript("OnUpdate", function(self, elapsed)
		self.timeSinceLastUpdate = self.timeSinceLastUpdate + elapsed
	
		if self.timeSinceLastUpdate > updateInterval then
			self.timeSinceLastUpdate = 0

			self.text:SetText(dampeningText..": "..C_Commentator.GetDampeningPercent().."%")
		end
	end)

	eventHandler:RegisterEvent("PLAYER_ENTERING_WORLD")
	eventHandler:RegisterEvent("MERCHANT_SHOW")

	self:OnProfileChange()
end

function m:OnProfileChange()
	self:HideLossOfControlBackground(self.db.hideLOCBackground)
	self:HideUIErrorsFrame(self.db.hideUIErrorsFrame)
	self:HideBags(self.db.hideBags)
	self:HideGlow(self.db.hideGlow)
	self:HideEffects(self.db.hideEffects)
	self:EnablePostureChecks(self.db.postureChecks)
end

-- Show dampening indicator in arenas only
function eventHandler:PLAYER_ENTERING_WORLD()
	self:SetShown(select(2, IsInInstance()) == "arena")
	if m.queuedPostureCheck then
		m.queuedPostureCheck = false
		C_Timer.After(5, m.PostureCheckCallback)
	end
end

-- Auto sell grey items
function eventHandler:MERCHANT_SHOW()
	for bag = 0, 4 do
		for slot = 0, GetContainerNumSlots(bag) do
			local link = GetContainerItemLink(bag, slot)
			if link and select(3, GetItemInfo(link)) == 0 then
				UseContainerItem(bag, slot)
			end
		end
	end
end

function m:HideBags(hide)
	self.db.hideBags = hide
	MicroButtonAndBagsBar:SetShown(not hide)
end

function m:HideGlow(hide)
	self.db.hideGlow = hide
	SetCVar("ffxGlow", hide and 0 or 1)
end

function m:HideEffects(hide)
	self.db.hideEffects = hide
	SetCVar("ffxDeath", hide and 0 or 1)
	SetCVar("ffxNether", hide and 0 or 1)
end

function m:HideLossOfControlBackground(hide)
	self.db.hideLOCBackground = hide
	LossOfControlFrame.blackBg:SetAlpha(hide and 0 or 1)
	LossOfControlFrame.RedLineTop:SetAlpha(hide and 0 or 1)
	LossOfControlFrame.RedLineBottom:SetAlpha(hide and 0 or 1)
end

function m:HideUIErrorsFrame(hide)
	self.db.hideUIErrorsFrame = hide
	UIErrorsFrame:SetShown(not hide)
end

function m.PostureCheckCallback()
	local _, instanceType = IsInInstance()
	if instanceType == "none" or instanceType == "scenario" or not m.db.hidePostureChecksInInstances then
		m.alertSystem:AddAlert(135898, "Posture Check", "No slouching!")
	else
		m.queuedPostureCheck = true
	end
end

function m:EnablePostureChecks(frequency)
	self.db.postureChecks = frequency

	if self.postureCheckTicker then
		self.postureCheckTicker:Cancel()
	end

	if frequency > 0 then
		self.postureCheckTicker = C_Timer.NewTicker(frequency * 60, m.PostureCheckCallback)
	end
end

function m.AlertSystem_Setup(frame, icon, text, desc)
	frame.Icon:SetTexture(icon)
	frame.Title:SetFontObject(GameFontNormalLarge)
	frame.Title:SetText(text)
	frame.Description:SetText(desc)

	if frame.Title:IsTruncated() then
		frame.Title:SetFontObject(GameFontNormal)
	end

	PlaySound(SOUNDKIT.UI_DIG_SITE_COMPLETION_TOAST)
end

m.defaultSettings = {
	hideLOCBackground = true,
	hideUIErrorsFrame = true,
	hideBags = true,
	hideGlow = true,
	hideEffects = true,
	postureChecks = 60,
	hidePostureChecksInInstances = true,
}

m.optionsTable = {
	hideLOCBackground = {
		name = "Hide Loss of Control Background",
		desc = "Black background on the \"Loss of Control\" frame",
		type = "toggle",
		width = "full",
		order = 1,
		set = function(info, val) m:HideLossOfControlBackground(val) end,
	},
	hideUIErrorsFrame = {
		name = "Hide UI Errors & Objective Updates",
		desc = "Text at center of screen that appears when errors occur or quest objectives are updated (Out of range spells, killing quest NPCs, etc)",
		type = "toggle",
		width = "full",
		order = 2,
		set = function(info, val) m:HideUIErrorsFrame(val) end,
	},
	hideBags = {
		name = "Hide Bags",
		type = "toggle",
		width = "full",
		order = 3,
		set = function(info, val) m:HideBags(val) end,
	},
	hideGlow = {
		name = "Disable Screen Glow",
		desc = "Bloom effects in the world",
		type = "toggle",
		width = "full",
		order = 4,
		set = function(info, val) m:HideGlow(val) end,
	},
	hideEffects = {
		name = "Disable Screen Effects",
		desc = "Effects such as \"blurry\" invisibility",
		type = "toggle",
		width = "full",
		order = 5,
		set = function(info, val) m:HideEffects(val) end,
	},
	postureChecksGroup = {
		name = "Posture Checks",
		type = "group",
		inline = true,
		order = 6,
		args = {
			postureChecks = {
				name = "Frequency",
				desc = "Notification every x minutes. 0 to disable",
				type = "range",
				width = 1,
				order = 1,
				min = 0,
				max = 60,
				step = 1,
				bigStep = 5,
				set = function(info, val) m:EnablePostureChecks(val) end,
			},
			hidePostureChecksInInstances = {
				name = "Disable In Instances",
				type = "toggle",
				width = "full",
				order = 2,
				set = function(info, val) m.db.hidePostureChecksInInstances = val end,
			}
		},
	},
}
