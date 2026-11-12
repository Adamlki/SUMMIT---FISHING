local Module = {}

function Module.Install(Controller)
function Controller:LoadCaughtData()
	task.spawn(function()
		for _ = 1, 5 do
			local callOk, awaitedOk, response = pcall(function()
				return self.NetworkGateway:Request("GET", "/fishing/index"):await()
			end)
			if callOk and awaitedOk and type(response) == "table" and response.Success and type(response.Data) == "table" then
				self.caughtData = response.Data
				if self.refreshGrid then self.refreshGrid() end
				return
			end
			task.wait(1)
		end
	end)
end

function Controller:SetupCatchListener()
	self.NetworkGateway:On("Fishing/CatchSuccess", function(event)
		if type(event) ~= "table" then return end
		local fishName = event.FishName
		if type(fishName) ~= "string" or fishName == "" then return end
		self.caughtData[fishName] = event.SpeciesCount or ((self.caughtData[fishName] or 0) + 1)
		if self.refreshGrid then self.refreshGrid() end
	end)
end

function Controller:StartSync()
	self:LoadCaughtData()
	self:SetupCatchListener()
	task.spawn(function()
		task.wait(1)
		if self.refreshGrid then self.refreshGrid() end
	end)
end

end

return Module
