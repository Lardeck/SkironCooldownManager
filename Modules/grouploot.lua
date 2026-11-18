local SCM = select(2, ...)
local LibWindow = LibStub("LibWindow-1.1")

local lootAnchor
local groupLootContainerAnchored

function SCM.CanPositionGroupLoot()
	return not C_AddOns.IsAddOnLoaded("ElvUI")
end

local function UpdateGroupLootContainer(container)
	if groupLootContainerAnchored then
		if not container:IsVisible() then
			return
		end
	elseif container:IsShown() then
		return
	end

	if not groupLootContainerAnchored then
		if not container.ignoreFramePositionManager then
			container.ignoreFramePositionManager = true
		end
		container:SetParent(UIParent)
	end

	container:ClearAllPoints()
	container:SetPoint("BOTTOM", lootAnchor, "TOP")
	groupLootContainerAnchored = true
end

local function CreateGroupLootAnchor(container)
	lootAnchor = CreateFrame("Frame", nil, UIParent)
	lootAnchor:SetSize(container:GetWidth(), 24)
	lootAnchor:SetFrameStrata("FULLSCREEN_DIALOG")
	lootAnchor:SetClampedToScreen(true)
	lootAnchor:SetMovable(true)
	lootAnchor:EnableMouse(true)
	lootAnchor:RegisterForDrag("LeftButton")
	lootAnchor:SetScript("OnDragStart", function(self)
		if not InCombatLockdown() then
			self.isMoving = true
			self:StartMoving()
		end
	end)
	lootAnchor:SetScript("OnDragStop", function(self)
		if self.isMoving then
			self.isMoving = nil
			LibWindow.OnDragStop(self)
		end
	end)
	local onDragStop = lootAnchor:GetScript("OnDragStop")
	lootAnchor:SetScript("OnHide", onDragStop)
	lootAnchor:SetScript("OnEvent", onDragStop)
	lootAnchor:RegisterEvent("PLAYER_REGEN_DISABLED")

	SCM.CreateAnchorHighlight(lootAnchor, "Group Loot", 20, false)

	container:HookScript("OnHide", UpdateGroupLootContainer)
	hooksecurefunc("GroupLootContainer_Update", UpdateGroupLootContainer)
end

function SCM.SetGroupLootAnchorShown(shown)
	if not lootAnchor then
		return
	end

	lootAnchor:SetShown(shown)
	lootAnchor.debugText:SetShown(shown)
	lootAnchor.debugTexture:SetShown(shown)
end

function SCM:ApplyGroupLootAnchor()
	local settings = self.db.profile.options.groupLootAnchor
	if lootAnchor or not settings.enabled or not self.CanPositionGroupLoot() then
		return
	end

	local container = GroupLootContainer
	CreateGroupLootAnchor(container)
	LibWindow.RegisterConfig(lootAnchor, settings.position)
	LibWindow.RestorePosition(lootAnchor)
	self.SetGroupLootAnchorShown(self.isOptionsOpen or false)
	UpdateGroupLootContainer(container)
end
