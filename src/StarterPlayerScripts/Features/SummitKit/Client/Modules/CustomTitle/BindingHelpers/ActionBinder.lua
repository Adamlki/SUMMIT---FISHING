--!nonstrict
local ColorParser = require(script.Parent.Parent.ColorParser)
local PlayersList = require(script.Parent.Parent.PlayersList)
local Preview = require(script.Parent.Parent.Preview)

local ActionBinder = {}

function ActionBinder.bindButtons(ctx, refs, overheadService, actions)
	if refs.Toggle then
		refs.Toggle.MouseButton1Click:Connect(function()
			ctx.Open = not ctx.Open
			if ctx.Animator then
				if ctx.Open then
					ctx.Animator:Open()
				else
					ctx.Animator:Close()
				end
			elseif refs.Menu then
				refs.Menu.Visible = ctx.Open
			end
		end)
	end
	if refs.Close then
		refs.Close.MouseButton1Click:Connect(function()
			ctx.Open = false
			if ctx.Animator then
				ctx.Animator:Close()
			elseif refs.Menu then
				refs.Menu.Visible = false
			end
		end)
	end
	if refs.Give then
		refs.Give.MouseButton1Click:Connect(function()
			actions.apply(ctx, overheadService)
		end)
	end
	if refs.Remove then
		refs.Remove.MouseButton1Click:Connect(function()
			actions.remove(ctx, overheadService)
		end)
	end
	if refs.Clear then
		refs.Clear.MouseButton1Click:Connect(function()
			actions.clearInputs(ctx, refs)
			Preview.Refresh(refs, ctx)
		end)
	end
	if refs.ColorButton then
		refs.ColorButton.MouseButton1Click:Connect(function()
			ctx:cycleColorMode()
			refs.ColorButton.Text = ctx.ColorMode
			Preview.Refresh(refs, ctx)
		end)
	end
	if refs.ModeButton then
		refs.ModeButton.MouseButton1Click:Connect(function()
			ctx:cycleMode()
			refs.ModeButton.Text = ctx.Mode
			Preview.Refresh(refs, ctx)
		end)
	end
	if refs.SlotButton then
		refs.SlotButton.MouseButton1Click:Connect(function()
			ctx:cycleSlot()
			refs.SlotButton.Text = ("Slot %d"):format(ctx.Slot)
		end)
	end
	if refs.Search then
		refs.Search:GetPropertyChangedSignal("Text"):Connect(function()
			local query = refs.Search.Text or ""
			if refs.PlayersPanel then
				refs.PlayersPanel.Visible = query ~= ""
			end
			PlayersList.Rebuild(refs, function(player, btn)
				ctx:setSelectedPlayer(player, btn)
			end, query)
		end)
	end
end

function ActionBinder.bindTextBoxes(ctx, refs)
	local binder = require(script.Parent.TextBoxBinder)
	local function refresh()
		Preview.Refresh(refs, ctx)
	end
	binder.bind(refs.InputText, function(text)
		ctx:setText(text)
		refresh()
	end)
	binder.bind(refs.Color1Text, function(text)
		ctx:setColor(1, ColorParser.parse(text))
		refresh()
	end)
	binder.bind(refs.Color2Text, function(text)
		ctx:setColor(2, ColorParser.parse(text))
		refresh()
	end)
	binder.bind(refs.Color3Text, function(text)
		ctx:setColor(3, ColorParser.parse(text))
		refresh()
	end)
	binder.bind(refs.Color4Text, function(text)
		ctx:setColor(4, ColorParser.parse(text))
		refresh()
	end)
end

return ActionBinder
