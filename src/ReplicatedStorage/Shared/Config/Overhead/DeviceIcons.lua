--!nonstrict
local OverheadDeviceIcons = {}

OverheadDeviceIcons.Images = {
	Desktop = "rbxassetid://132881150121152",
	Mobile = "rbxassetid://13021320268",
}

function OverheadDeviceIcons.getImage(device)
	return OverheadDeviceIcons.Images[device] or OverheadDeviceIcons.Images.Mobile or ""
end

function OverheadDeviceIcons.apply(deviceLabel, device)
	if not deviceLabel or not deviceLabel:IsA("ImageLabel") then
		return
	end
	if not device then
		deviceLabel.Visible = false
		return
	end
	deviceLabel.Visible = true
	local image = OverheadDeviceIcons.getImage(device)
	if image and image ~= "" then
		deviceLabel.Image = image
	end
end

return OverheadDeviceIcons
