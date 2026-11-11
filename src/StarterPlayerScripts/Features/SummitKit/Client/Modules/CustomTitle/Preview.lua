--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Janitor = require(Packages.Janitor)

local Effects = require(script.Parent.Effects)

local Preview = {}

local previewJanitor = Janitor.new()

function Preview.Refresh(refs, state)
    if not refs or not refs.PreviewText then
        return
    end
    previewJanitor:Cleanup()
    local view = state:buildView()
    local text = view.Text ~= "" and view.Text or "Custom Title"
    refs.PreviewText.Text = text

	local colors = view.Colors
	refs.PreviewText.TextColor3 = Color3.fromRGB(255, 255, 255)
	if #colors == 1 then
		refs.PreviewText.TextColor3 = colors[1]
	end

    Effects.apply(refs.PreviewText, colors, view.Mode, previewJanitor)
end

function Preview.Cleanup()
    previewJanitor:Destroy()
    previewJanitor = Janitor.new()
end

return Preview
