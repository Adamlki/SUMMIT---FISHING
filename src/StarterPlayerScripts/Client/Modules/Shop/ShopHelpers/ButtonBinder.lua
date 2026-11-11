--!nonstrict
local ButtonBinder = {}

function ButtonBinder.connect(btn, cb, janitor)
	if not btn then
		return
	end

	local conn
	if btn:IsA("TextButton") or btn:IsA("ImageButton") then
		conn = btn.MouseButton1Click:Connect(cb)
	else
		conn = btn.InputBegan:Connect(function(input)
			if input.UserInputType.Name:match("MouseButton") or input.UserInputType == Enum.UserInputType.Touch then
				cb()
			end
		end)
	end

	if janitor and conn then
		janitor:Add(conn, "Disconnect")
	end
end

return ButtonBinder
