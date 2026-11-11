game.Players.PlayerAdded:Connect(function(player: Player) 
	player.CharacterAdded:Connect(function()
		local gui = script:WaitForChild('GUI'):Clone()
		gui.Parent = player.Character
		gui.Adornee = player.Character:WaitForChild('Head')
		gui.NAME.Text = `{player.DisplayName} | @{player.Name}`
	end)
end)