-- Custom Inventory Manager with 6-Slot Hotbar Architecture & Dynamic Fish Slot Visibility
-- Slot 1: RodSlot (1)
-- Slot 2: ToolSlot1 (2)
-- Slot 3: ToolSlot2 (3)
-- Slot 4: BagButton (4)
-- Slot 5: FishSlot1 (5) [Hidden when empty]
-- Slot 6: FishSlot2 (6) [Hidden when empty]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
task.spawn(function()
	local attempts = 0
	while attempts < 30 do
		local ok = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end)
		if ok then break end
		attempts = attempts + 1
		task.wait(0.1)
	end
end)

local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local StarterPack = game:GetService("StarterPack")

local NetworkGateway = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("NetworkGateway"))
local RoleConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("RoleConfig"))
local FishingConfig = require(ReplicatedStorage:WaitForChild("Configs"):WaitForChild("FishingConfig"))

local Core = require(script.Parent.Modules.Core)
local Viewport = require(script.Parent.Modules.Viewport)
local Hotbar = require(script.Parent.Modules.Hotbar)
local Grid = require(script.Parent.Modules.Grid)
local Interactions = require(script.Parent.Modules.Interactions)

local Controller = {}
Controller.__index = Controller

function Controller.new()
	local self = setmetatable({}, Controller)
	self.Players = Players
	self.ReplicatedStorage = ReplicatedStorage
	self.StarterGui = StarterGui
	self.CollectionService = CollectionService
	self.UserInputService = UserInputService
	self.SoundService = SoundService
	self.StarterPack = StarterPack
	self.NetworkGateway = NetworkGateway
	self.RoleConfig = RoleConfig
	self.FishingConfig = FishingConfig
	self.FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
	self.RarityColors = FishingConfig.RarityColors
	self.GlobalLuckVal = self.FishingSystem:WaitForChild("GlobalLuckMultiplier")
	self.fishAssetFolder = self.FishingSystem:WaitForChild("Assets"):WaitForChild("Fish")
	self.rodAssetFolder = self.FishingSystem:WaitForChild("Assets"):WaitForChild("Rod")

	self.player = Players.LocalPlayer
	self.playerGui = self.player:WaitForChild("PlayerGui")
	self.VIP_GAMEPASS_ID = 1590939529
	self.isVIP = false

	self.gui = nil
	self.Hotbar = {}
	self.Inventory = {}
	self.Templates = {}
	self.OriginalColors = {
		RodSlot = {},
		ToolSlot1 = {},
		ToolSlot2 = {},
		FishSlot1 = {},
		FishSlot2 = {}
	}

	self.isInventoryOpen = false
	self.currentTab = "Fish"
	self.lastOpenedTab = "Fish"
	self.allFishData = {}
	self.allRodData = {}
	self.rodToolStats = {}
	self.lastEquippedRodName = nil
	self.lastEquippedToolName1 = nil
	self.lastEquippedToolName2 = nil
	self.lastEquippedFishId1 = nil
	self.lastEquippedFishId2 = nil
	self.connections = {}
	self.buttonConnections = {}
	self.HotbarState = {
		rod = nil,
		tool1 = nil,
		tool2 = nil,
		fish1 = nil,
		fish2 = nil
	}
	self.isRefreshing = false
	return self
end

Core.Install(Controller)
Viewport.Install(Controller)
Hotbar.Install(Controller)
Grid.Install(Controller)
Interactions.Install(Controller)

function Controller:RefreshAllData()
	if self.isRefreshing then return end
	self.isRefreshing = true

	local ok, res = self.NetworkGateway:Request("GET", "/inventory/data"):await()
	if not ok or type(res) ~= "table" or not res.Success then
		self.isRefreshing = false
		return
	end
	local fullData = res.Data or { Fish = {}, Rods = {}, LastRod = nil }

	self.allFishData = fullData.Fish or {}
	self.allRodData = fullData.Rods or {}

	if next(self.rodToolStats) == nil then
		local rodShopEvents = self.FishingSystem:FindFirstChild("RodShopEvents")
		if rodShopEvents then
			local rfGetShopData = rodShopEvents:FindFirstChild("GetShopData")
			if rfGetShopData then
				local success2, shopData = pcall(function()
					return rfGetShopData:InvokeServer()
				end)

				if success2 and shopData and shopData.AllRodData then
					for rodName, data in pairs(shopData.AllRodData) do
						self.rodToolStats[rodName] = {
							Stats = data.Stats,
							TextureId = data.TextureId
						}
					end
				end
			end
		end
	end

	self:ValidateHotbarItems()

	if self.currentTab == "Fish" then
		self:PopulateFishGrid()
	elseif self.currentTab == "Rods" then
		self:PopulateRodGrid()
	elseif self.currentTab == "Tools" then
		self:PopulateToolGrid()
	elseif self.currentTab == "VIP" and self.isVIP then
		self:PopulateVIPToolGrid()
	end

	self:UpdateFishCount()
	self.isRefreshing = false
end

function Controller:SwitchTab(tabName)
	self.lastOpenedTab = tabName
	self.currentTab = tabName

	if self.Inventory.FishTabButton then self.Inventory.FishTabButton.BackgroundColor3 = Color3.fromRGB(49, 49, 49) end
	if self.Inventory.RodTabButton then self.Inventory.RodTabButton.BackgroundColor3 = Color3.fromRGB(49, 49, 49) end
	if self.Inventory.ToolTabButton then self.Inventory.ToolTabButton.BackgroundColor3 = Color3.fromRGB(49, 49, 49) end
	if self.Inventory.VIPTabButton then
		self.Inventory.VIPTabButton.BackgroundColor3 = Color3.fromRGB(49, 49, 49)
	end

	if self.Inventory.FishContent then self.Inventory.FishContent.Visible = false end
	if self.Inventory.RodContent then self.Inventory.RodContent.Visible = false end
	if self.Inventory.ToolContent then self.Inventory.ToolContent.Visible = false end
	if self.Inventory.VIPContent then
		self.Inventory.VIPContent.Visible = false
	end
	if self.Inventory.SellAllButton then self.Inventory.SellAllButton.Visible = false end

	if tabName == "Fish" and self.Inventory.FishTabButton and self.Inventory.FishContent then
		self.Inventory.FishTabButton.BackgroundColor3 = Color3.fromRGB(106, 106, 106)
		self.Inventory.FishContent.Visible = true
		if self.Inventory.SellAllButton then self.Inventory.SellAllButton.Visible = true end
		if self.Inventory.FishCountLabel then
			self.Inventory.FishCountLabel.Visible = true
		end
		self:PopulateFishGrid()
	elseif tabName == "Rods" and self.Inventory.RodTabButton and self.Inventory.RodContent then
		self.Inventory.RodTabButton.BackgroundColor3 = Color3.fromRGB(106, 106, 106)
		self.Inventory.RodContent.Visible = true
		if self.Inventory.FishCountLabel then
			self.Inventory.FishCountLabel.Visible = false
		end
		self:PopulateRodGrid()
	elseif tabName == "Tools" and self.Inventory.ToolTabButton and self.Inventory.ToolContent then
		self.Inventory.ToolTabButton.BackgroundColor3 = Color3.fromRGB(106, 106, 106)
		self.Inventory.ToolContent.Visible = true
		if self.Inventory.FishCountLabel then
			self.Inventory.FishCountLabel.Visible = false
		end
		self:PopulateToolGrid()
	elseif tabName == "VIP" and self.isVIP and self.Inventory.VIPTabButton and self.Inventory.VIPContent then
		self.Inventory.VIPTabButton.BackgroundColor3 = Color3.fromRGB(106, 106, 106)
		self.Inventory.VIPContent.Visible = true
		if self.Inventory.FishCountLabel then
			self.Inventory.FishCountLabel.Visible = false
		end
		self:PopulateVIPToolGrid()
	end
end

function Controller:ToggleInventory(visible)
	if visible == self.isInventoryOpen then return end

	self.isInventoryOpen = visible
	if self.Inventory.Frame then
		self.Inventory.Frame.Visible = visible
	end

	if visible then
		self:RefreshAllData()
		self:SwitchTab(self.lastOpenedTab)
	end
end

function Controller:SetupCharacter(character)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

	local guiSuccess = self:UpdateGUIReferences()
	if not guiSuccess then
		task.wait(1)
		guiSuccess = self:UpdateGUIReferences()
		if not guiSuccess then
			return
		end
	end

	self:CheckVIPStatus()
	self:SetupButtonEvents()

	for _, conn in ipairs(self.connections) do
		if conn.Connected then
			conn:Disconnect()
		end
	end
	table.clear(self.connections)

	if self.Hotbar.Frame then
		self.Hotbar.Frame.Visible = true
	end

	if self.Hotbar.BagButton then self.Hotbar.BagButton.Active = true end
	if self.Hotbar.RodSlot then self.Hotbar.RodSlot.Active = true end
	if self.Hotbar.ToolSlot1 then self.Hotbar.ToolSlot1.Active = true end
	if self.Hotbar.ToolSlot2 then self.Hotbar.ToolSlot2.Active = true end
	if self.Hotbar.FishSlot1 then self.Hotbar.FishSlot1.Active = true end
	if self.Hotbar.FishSlot2 then self.Hotbar.FishSlot2.Active = true end

	local backpack = self.player:WaitForChild("Backpack")

	task.wait(0.5)

	task.spawn(function()
		local ok, res = self.NetworkGateway:Request("GET", "/inventory/data"):await()
		if ok and type(res) == "table" and res.Success then
			local fullData = res.Data or { Fish = {}, Rods = {}, LastRod = nil }
			self.allFishData = fullData.Fish or {}
			self.allRodData = fullData.Rods or {}

			local isFirstLoad = not self.HotbarState.rod and not self.HotbarState.tool1 and not self.HotbarState.tool2 and not self.HotbarState.fish1 and not self.HotbarState.fish2

			if not isFirstLoad then
				self:RestoreHotbarState()
			else
				if fullData.LastRod then
					self.lastEquippedRodName = fullData.LastRod
					self.HotbarState.rod = fullData.LastRod
				elseif table.find(self.allRodData, "Basic Rod") or (backpack and backpack:FindFirstChild("Basic Rod")) then
					self.lastEquippedRodName = "Basic Rod"
					self.HotbarState.rod = "Basic Rod"
				elseif #self.allRodData > 0 then
					self.lastEquippedRodName = self.allRodData[1]
					self.HotbarState.rod = self.allRodData[1]
				end
			end

			self:AutoFillHotbarSlots()

			self:UpdateRodVisual(self.lastEquippedRodName)
			self:UpdateToolVisual1(self.lastEquippedToolName1)
			self:UpdateToolVisual2(self.lastEquippedToolName2)
			self:UpdateFishVisual1(self.lastEquippedFishId1)
			self:UpdateFishVisual2(self.lastEquippedFishId2)

			self:SaveHotbarState()
			self:UpdateFishCount()
		end
	end)

	table.insert(self.connections, backpack.ChildAdded:Connect(function(child)
		self:DisableTooltip(child)
		if child:IsA("Tool") and not self.CollectionService:HasTag(child, "Rod") and not child:FindFirstChild("FishId") then
			if not self.lastEquippedToolName1 or not self.lastEquippedToolName2 then
				self:AutoFillHotbarSlots()
			end
		end
	end))

	table.insert(self.connections, backpack.ChildRemoved:Connect(function(child)
		if not child:IsA("Tool") then return end

		task.wait(0.1)

		local isFish = child:FindFirstChild("FishId")
		local isRod = self.CollectionService:HasTag(child, "Rod")

		local stillExists = self.player.Backpack:FindFirstChild(child.Name) or
			(self.player.Character and self.player.Character:FindFirstChild(child.Name))

		if stillExists then
			return
		end

		if isRod and child.Name == self.lastEquippedRodName then
			local rodStillOwned = false
			for _, rodName in ipairs(self.allRodData) do
				if rodName == self.lastEquippedRodName then
					rodStillOwned = true
					break
				end
			end
			if not rodStillOwned then
				self.lastEquippedRodName = nil
				self:UpdateRodVisual(nil)
				self:SaveHotbarState()
			end
		elseif child.Name == self.lastEquippedToolName1 then
			self.lastEquippedToolName1 = nil
			self:UpdateToolVisual1(nil)
			self:SaveHotbarState()
		elseif child.Name == self.lastEquippedToolName2 then
			self.lastEquippedToolName2 = nil
			self:UpdateToolVisual2(nil)
			self:SaveHotbarState()
		elseif isFish and child:FindFirstChild("FishId") and child.FishId.Value == self.lastEquippedFishId1 then
			local fishStillExists = false
			for _, fish in ipairs(self.allFishData) do
				if fish.uniqueId == self.lastEquippedFishId1 then
					fishStillExists = true
					break
				end
			end
			if not fishStillExists then
				self.lastEquippedFishId1 = nil
				self:UpdateFishVisual1(nil)
				self:SaveHotbarState()
			end
		elseif isFish and child:FindFirstChild("FishId") and child.FishId.Value == self.lastEquippedFishId2 then
			local fishStillExists = false
			for _, fish in ipairs(self.allFishData) do
				if fish.uniqueId == self.lastEquippedFishId2 then
					fishStillExists = true
					break
				end
			end
			if not fishStillExists then
				self.lastEquippedFishId2 = nil
				self:UpdateFishVisual2(nil)
				self:SaveHotbarState()
			end
		end
	end))

	table.insert(self.connections, character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			self:DisableTooltip(child)
			self:OnToolChanged(child)
		end
	end))

	table.insert(self.connections, character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			self:OnToolChanged(nil)
		end
	end))
end

function Controller:ConnectReplicationEvents()
	local eventsFolder = self.ReplicatedStorage:WaitForChild("FishingEvents", 5)
	if eventsFolder then
		local onFishCaught = eventsFolder:FindFirstChild("FishCaught")
		if onFishCaught then
			onFishCaught.OnClientEvent:Connect(function(fishData)
				self:RefreshAllData()
			end)
		end
	end
end

local controller = Controller.new()
controller:UpdateGUIReferences()

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

task.spawn(function()
	while true do
		task.wait(1)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	controller:HandleKeyPress(input, gameProcessed)
end)

if controller.player.Character then
	controller:SetupCharacter(controller.player.Character)
end

controller.player.CharacterAdded:Connect(function(character)
	controller:SetupCharacter(character)
end)

if controller.GlobalLuckVal then
	controller.GlobalLuckVal.Changed:Connect(function()
		if controller.isInventoryOpen and controller.currentTab == "Rods" then
			controller:PopulateRodGrid()
		end
	end)
end

task.spawn(function()
	controller:ConnectReplicationEvents()
end)
