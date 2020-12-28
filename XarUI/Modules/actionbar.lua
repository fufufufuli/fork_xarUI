local _, XarUI = ...
local m = XarUI:CreateModule("Actionbar")

local eventHandler = CreateFrame("Frame", nil, UIParent)
eventHandler:SetScript("OnEvent", function(self, event, ...) return self[event](self, ...) end)

function m:OnLoad()
	eventHandler:RegisterEvent("PLAYER_LOGIN")

	-- Hide artwork
	MainMenuBarArtFrameBackground.BackgroundSmall:SetAlpha(0)
	MainMenuBarArtFrameBackground.BackgroundLarge:SetAlpha(0)
	MainMenuBarArtFrameBackground.QuickKeybindGlowLarge:SetAlpha(0)
	MainMenuBarArtFrameBackground.QuickKeybindGlowSmall:SetAlpha(0)
	MultiBarBottomLeft.QuickKeybindGlow:SetAlpha(0)
	MultiBarBottomRight.QuickKeybindGlow:SetAlpha(0)
	MainMenuBarArtFrame.RightEndCap:Hide()
	MainMenuBarArtFrame.LeftEndCap:Hide()
	MainMenuBarArtFrame.PageNumber:Hide()
	StanceBarLeft:SetAlpha(0)
	StanceBarRight:SetAlpha(0)
	StanceBarMiddle:SetAlpha(0)
	SlidingActionBarTexture0:SetAlpha(0)
	SlidingActionBarTexture1:SetAlpha(0)

	-- Adjust gap between main & bottom right bars to accomodate extra buttons
	MultiBarBottomRightButton1:ClearAllPoints()
	MultiBarBottomRightButton1:SetPoint("LEFT", ActionButton12, "CENTER", 89, 0)
	MultiBarBottomRightButton7:ClearAllPoints()
	MultiBarBottomRightButton7:SetPoint("LEFT", MultiBarBottomLeftButton12, "CENTER", 89, 0)

	-- Hide XP Bar. Don't touch MainMenuBar it's evil
	MainMenuBarArtFrameBackground:ClearAllPoints()
	MainMenuBarArtFrameBackground:SetPoint("LEFT", MainMenuBar)

	hooksecurefunc(StatusTrackingBarManager, "LayoutBar", function(self, bar)
		bar:SetPoint("BOTTOM", MainMenuBarArtFrameBackground, 0, select(5, bar:GetPoint()));
	end)

	-- MainMenuBar blocks click action on some moved buttons
	MainMenuBar:EnableMouse(false)

	-- UIParent_ManageFramePosition will ignore a frame if it's user-placed
	MultiBarBottomLeft:SetMovable(true)
	MultiBarBottomLeft:SetUserPlaced(true)

	-- Fix position of pet bar
	local petAnchor = CreateFrame("Frame", nil, PetActionBarFrame)
	petAnchor:SetSize(509, 43)
	for i = 1, 10 do
		local button = _G["PetActionButton"..i]
		button:ClearAllPoints()
		if i == 1 then
			button:SetPoint("BOTTOMLEFT", petAnchor, "BOTTOMLEFT", 36, 2)
		else
			button:SetPoint("LEFT", "PetActionButton"..i-1, "RIGHT", 8, 0)
		end
	end

	-- Fix position of stance bar
	StanceBarFrame.ignoreFramePositionManager = true

	hooksecurefunc("UIParent_ManageFramePosition", function(index)
		if InCombatLockdown() then return end

		if index == "PETACTIONBAR_YPOS" then
			petAnchor:SetPoint("BOTTOMLEFT", MainMenuBarArtFrameBackground, "TOPLEFT", 30, SHOW_MULTI_ACTIONBAR_1 and 40 or -2)
		elseif index == "StanceBarFrame" then
			StanceBarFrame:SetPoint("BOTTOMLEFT", MainMenuBarArtFrameBackground, "TOPLEFT", 30, SHOW_MULTI_ACTIONBAR_1 and 40 or -2)
		end
	end)

	-- Fix texture size on stance bar when bottom left bar is disabled
	local sizeHook = false

	local function widthFunc(self)
		if sizeHook then return end
		sizeHook = true
		self:SetWidth(52)
		sizeHook = false
	end

	local function heightFunc(self)
		if sizeHook then return end
		sizeHook = true
		self:SetHeight(52)
		sizeHook = false
	end

	for i=1, NUM_STANCE_SLOTS do
		hooksecurefunc(_G["StanceButton"..i]:GetNormalTexture(), "SetWidth", widthFunc)
		hooksecurefunc(_G["StanceButton"..i]:GetNormalTexture(), "SetHeight", heightFunc)
	end

	self.buttons = {}
	for i = 1, 12 do
		tinsert(self.buttons, _G["ActionButton"..i])
		tinsert(self.buttons, _G["MultiBarBottomLeftButton"..i])
		tinsert(self.buttons, _G["MultiBarBottomRightButton"..i])
		tinsert(self.buttons, _G["MultiBarLeftButton"..i])
		tinsert(self.buttons, _G["MultiBarRightButton"..i])
	end

	local function updateHotkeys(self)
		if m.db.hideHotkeys then
			self.HotKey:Hide()
		end
	end

	for _,button in pairs(self.buttons) do
		hooksecurefunc(button, "UpdateHotkeys", updateHotkeys)
	end

	hooksecurefunc("ActionButton_UpdateRangeIndicator", updateHotkeys)
	hooksecurefunc("PetActionButton_SetHotkeys", updateHotkeys)

	self:HideXPBar(self.db.hideXPBar)
	self:HideArrows(self.db.hideArrows)
	self:HideHotkeys(self.db.hideHotkeys)
	self:HideMacroNames(self.db.hideMacroNames)
	self:EnableExtraButtons(self.db.extraButtons)
	self:FuliButtons(self.db.fuliButtons)
end

function eventHandler:PLAYER_LOGIN()
	if InCombatLockdown() then return end

	-- moving the bar here because PLAYER_LOGIN is called after layout-local.txt settings
	MultiBarBottomLeft:ClearAllPoints()
	MultiBarBottomLeft:SetPoint("BOTTOMLEFT", ActionButton1, "TOPLEFT", 0, 6)
end

function m:HideXPBar(hide)
	self.db.hideXPBar = hide
	StatusTrackingBarManager:SetAlpha(hide and 0 or 1)
	MainMenuBarArtFrameBackground:SetPoint("BOTTOM", hide and UIParent or MainMenuBar, 0, hide and 3 or 0)
end

function m:HideArrows(hide)
	self.db.hideArrows = hide
	ActionBarDownButton:SetAlpha(hide and 0 or 1)
	ActionBarUpButton:SetAlpha(hide and 0 or 1)
end

function m:HideHotkeys(hide)
	self.db.hideHotkeys = hide
	for _, button in ipairs(self.buttons) do
		button:UpdateHotkeys(button.buttonType)
	end
	for i = 1, 10 do
		PetActionButton_SetHotkeys(_G["PetActionButton"..i])
	end
end

function m:HideMacroNames(hide)
	self.db.hideMacroNames = hide
	for _, button in ipairs(self.buttons) do
		button.Name:SetShown(not hide)
	end
end

function m:EnableExtraButtons(enable)
	self.db.extraButtons = enable

	if enable then
		MultiBarLeftButton12:ClearAllPoints()
		MultiBarLeftButton12:SetPoint("LEFT", MultiBarBottomLeftButton12, "RIGHT", 6, 0)
		MultiBarRightButton12:ClearAllPoints()
		MultiBarRightButton12:SetPoint("LEFT", ActionButton12, "RIGHT", 6, 0)
		ActionBarDownButton:ClearAllPoints()
		ActionBarUpButton:ClearAllPoints()
		ActionBarUpButton:SetPoint("BOTTOM", MultiBarRightButton12, "RIGHT", 14,-1)
		ActionBarDownButton:SetPoint("TOP", MultiBarRightButton12, "RIGHT", 14,-1)
	else
		MultiBarLeftButton12:ClearAllPoints()
		MultiBarLeftButton12:SetPoint("TOP", MultiBarLeftButton11, "BOTTOM", 0, -6)
		MultiBarRightButton12:ClearAllPoints()
		MultiBarRightButton12:SetPoint("TOP", MultiBarRightButton11, "BOTTOM", 0, -6)
		ActionBarDownButton:ClearAllPoints()
		ActionBarUpButton:ClearAllPoints()
		ActionBarUpButton:SetPoint("BOTTOM", ActionButton12, "RIGHT", 14,-1)
		ActionBarDownButton:SetPoint("TOP", ActionButton12, "RIGHT", 14,-1)
	end
end

function m:FuliButtons(enable)
	self.db.fuliButtons = enable

	if enable then
		MultiBarLeftButton12:ClearAllPoints()
		MultiBarLeftButton12:SetPoint("TOP", ActionButton12, "TOP", 0, 90)
		MultiBarLeftButton11:ClearAllPoints()
		MultiBarLeftButton11:SetPoint("TOP", ActionButton11, "TOP", 0, 90)
		MultiBarLeftButton10:ClearAllPoints()
		MultiBarLeftButton10:SetPoint("TOP", ActionButton10, "TOP", 0, 90)
		MultiBarLeftButton9:ClearAllPoints()
		MultiBarLeftButton9:SetPoint("TOP", ActionButton9, "TOP", 0, 90)
		MultiBarLeftButton8:ClearAllPoints()
		MultiBarLeftButton8:SetPoint("TOP", ActionButton8, "TOP", 0, 90)
		MultiBarLeftButton7:ClearAllPoints()
		MultiBarLeftButton7:SetPoint("TOP", ActionButton7, "TOP", 0, 90)
		MultiBarLeftButton6:ClearAllPoints()
		MultiBarLeftButton6:SetPoint("TOP", ActionButton6, "TOP", 0, 90)
		MultiBarLeftButton5:ClearAllPoints()
		MultiBarLeftButton5:SetPoint("TOP", ActionButton5, "TOP", 0, 90)
		MultiBarLeftButton4:ClearAllPoints()
		MultiBarLeftButton4:SetPoint("TOP", ActionButton4, "TOP", 0, 90)
		MultiBarLeftButton3:ClearAllPoints()
		MultiBarLeftButton3:SetPoint("TOP", ActionButton3, "TOP", 0, 90)
		MultiBarLeftButton2:ClearAllPoints()
		MultiBarLeftButton2:SetPoint("TOP", ActionButton2, "TOP", 0, 90)
		MultiBarLeftButton1:ClearAllPoints()
		MultiBarLeftButton1:SetPoint("TOP", ActionButton1, "TOP", 0, 90)
	else
		MultiBarLeftButton12:ClearAllPoints()
		MultiBarLeftButton12:SetPoint("TOP", MultiBarRightButton12, "TOP", -42, 0)
		MultiBarLeftButton11:ClearAllPoints()
		MultiBarLeftButton11:SetPoint("TOP", MultiBarRightButton11, "TOP", -42, 0)
		MultiBarLeftButton10:ClearAllPoints()
		MultiBarLeftButton10:SetPoint("TOP", MultiBarRightButton10, "TOP", -42, 0)
		MultiBarLeftButton9:ClearAllPoints()
		MultiBarLeftButton9:SetPoint("TOP", MultiBarRightButton9, "TOP", -42, 0)
		MultiBarLeftButton8:ClearAllPoints()
		MultiBarLeftButton8:SetPoint("TOP", MultiBarRightButton8, "TOP", -42, 0)
		MultiBarLeftButton7:ClearAllPoints()
		MultiBarLeftButton7:SetPoint("TOP", MultiBarRightButton7, "TOP", -42, 0)
		MultiBarLeftButton6:ClearAllPoints()
		MultiBarLeftButton6:SetPoint("TOP", MultiBarRightButton6, "TOP", -42, 0)
		MultiBarLeftButton5:ClearAllPoints()
		MultiBarLeftButton5:SetPoint("TOP", MultiBarRightButton5, "TOP", -42, 0)
		MultiBarLeftButton4:ClearAllPoints()
		MultiBarLeftButton4:SetPoint("TOP", MultiBarRightButton4, "TOP", -42, 0)
		MultiBarLeftButton3:ClearAllPoints()
		MultiBarLeftButton3:SetPoint("TOP", MultiBarRightButton3, "TOP", -42, 0)
		MultiBarLeftButton2:ClearAllPoints()
		MultiBarLeftButton2:SetPoint("TOP", MultiBarRightButton2, "TOP", -42, 0)
		MultiBarLeftButton1:ClearAllPoints()
		MultiBarLeftButton1:SetPoint("TOP", MultiBarRightButton1, "TOP", -42, 0)
	end
end

function m:OnProfileChange()
	self:HideXPBar(self.db.hideXPBar)
	self:HideArrows(self.db.hideArrows)
	self:HideHotkeys(self.db.hideHotkeys)
	self:HideMacroNames(self.db.hideMacroNames)
	self:EnableExtraButtons(self.db.extraButtons)
	self:FuliButtons(self.db.fuliButtons)
end

m.defaultSettings = {
	hideXPBar = true,
	hideArrows = false,
	hideHotkeys = false,
	hideMacroNames = false,
	extraButtons = false,
	fuliButtons = true,
}

m.optionsTable = {
	hideXPBar = {
		name = "Hide Experience Bar",
		type = "toggle",
		width = "full",
		order = 1,
		set = function(info, val) m.db.hideXPBar = val m:HideXPBar(val) end,
	},
	hideArrows = {
		name = "Hide Up / Down Buttons",
		type = "toggle",
		width = "full",
		order = 2,
		set = function(info, val) m.db.hideArrows = val m:HideArrows(val) end,
	},
	hideHotkeys = {
		name = "Hide Hot Keys",
		type = "toggle",
		width = "full",
		order = 3,
		set = function(info, val) m.db.hideHotkeys = val m:HideHotkeys(val) end,
	},
	hideMacroNames = {
		name = "Hide Macro Names",
		type = "toggle",
		width = "full",
		order = 4,
		set = function(info, val) m.db.hideMacroNames = val m:HideMacroNames(val) end,
	},
	extraButtons = {
		name = "Extra Buttons",
		desc = "Moves the 12th button on each of the right side actionbars down to the bottom bars",
		type = "toggle",
		width = "full",
		order = 5,
		set = function(info, val) m:EnableExtraButtons(val) end,
	},
	fuliButtons = {
		name = "fuli的动作条",
		desc = "将右边左侧动作条移动到中间位置",
		type = "toggle",
		width = "full",
		order = 6,
		set = function(info, val) m:FuliButtons(val) end,
	},
}