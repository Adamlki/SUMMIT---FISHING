local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")

TextChatService.OnIncomingMessage = function(textMessage)
	local properties = Instance.new("TextChatMessageProperties")

	if textMessage.TextSource then
		local player = Players:GetPlayerByUserId(textMessage.TextSource.UserId)
		if player then
			local role = player:GetAttribute("ChatRole")
			local roleColor = player:GetAttribute("ChatRoleColor")
			local roleDisplay = player:GetAttribute("ChatRoleDisplay")

			-- DEBUG: Cetak info chat client
			print(string.format("[Client Debug] Chat dari: %s | Role: %s | Display: %s", player.Name, tostring(role), tostring(roleDisplay)))

			if role and roleColor and roleDisplay then
				properties.PrefixText = string.format("<font color='%s'><b>[%s]</b></font> %s", roleColor, roleDisplay, textMessage.PrefixText)
			end
		end
	end

	return properties
end