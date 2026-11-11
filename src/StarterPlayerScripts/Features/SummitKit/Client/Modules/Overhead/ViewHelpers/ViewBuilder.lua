--!nonstrict
local ViewBuilder = {}

function ViewBuilder.build(template, character)
	local head = character:FindFirstChild("Head") or character:WaitForChild("Head", 60)
	if not head then
		return nil
	end

	local gui = template:Clone()
	gui.Name = "Overhead"
	gui.Adornee = head
	gui.ResetOnSpawn = false
	gui.Parent = character

	local canvas = gui:FindFirstChild("Canvas")
	local titleTextFrame = gui:FindFirstChild("TitleText")
	local titleImageFrame = gui:FindFirstChild("TitleImage")

	local textTemplate = titleTextFrame and titleTextFrame:FindFirstChild("TitleTextTemplate")
	local imageTemplate = titleImageFrame and (titleImageFrame:FindFirstChild("TitleImageTamplate") or titleImageFrame:FindFirstChild("TitleImageTemplate"))

	local refs = {
		Root = gui,
		Canvas = canvas,
		Name = (canvas and canvas:FindFirstChild("Name")) or gui:FindFirstChild("Name"),
		Total = gui:FindFirstChild("Total"),
		Title = gui:FindFirstChild("Title"),
		Flag = canvas and canvas:FindFirstChild("Flag"),
		Device = canvas and canvas:FindFirstChild("Device"),
		VipLabel = nil,
		VipEffect = nil,
		LevelGradient = nil,
		DefaultGradient = nil,

		TitleText = titleTextFrame,
		TitleTextTemplate = textTemplate,
		TextItems = {},

		TitleImage = titleImageFrame,
		TitleImageTemplate = imageTemplate,
		ImageItems = {},
	}

	if refs.Canvas then
		local vipLabel = refs.Canvas:FindFirstChild("VIP")
		if vipLabel and vipLabel:IsA("TextLabel") then
			refs.VipLabel = vipLabel
		end
	end

	if refs.Title then
		refs.LevelGradient = refs.Title:FindFirstChildWhichIsA("UIGradient")
		if refs.LevelGradient then
			refs.DefaultGradient = refs.LevelGradient.Color
		end
	end

	-- Sembunyikan template master agar tidak ikut terlihat
	if textTemplate then
		textTemplate.Visible = false
	end
	if imageTemplate then
		imageTemplate.Visible = false
	end

	-- 1. Duplikasi Template Title Teks (Maksimal 3 item)
	if titleTextFrame and textTemplate then
		titleTextFrame.Visible = false
		for i = 1, 3 do
			local textClone = textTemplate:Clone()
			textClone.Name = "TextItem" .. tostring(i)
			textClone.LayoutOrder = i
			textClone.Visible = false
			textClone.Parent = titleTextFrame

			local grad = textClone:FindFirstChildWhichIsA("UIGradient")
			if not grad then
				grad = Instance.new("UIGradient")
				grad.Parent = textClone
			end

			table.insert(refs.TextItems, {
				Label = textClone,
				Gradient = grad,
			})
		end
	end

	-- 2. Duplikasi Template Image Title (Maksimal 3 item)
	if titleImageFrame and imageTemplate then
		titleImageFrame.Visible = false
		for i = 1, 3 do
			local imageClone = imageTemplate:Clone()
			imageClone.Name = "ImageItem" .. tostring(i)
			imageClone.LayoutOrder = i
			imageClone.Visible = false
			imageClone.Parent = titleImageFrame

			table.insert(refs.ImageItems, {
				Image = imageClone,
			})
		end
	end

	return refs
end

return ViewBuilder
