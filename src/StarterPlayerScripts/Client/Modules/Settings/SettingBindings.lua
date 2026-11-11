--!nonstrict
local SettingBindings = {}

local function bindButton(janitor, btn, fn)
    if not btn then return end
    if btn:IsA("GuiButton") then
        janitor:Add(btn.Activated:Connect(fn), "Disconnect")
    else
        btn.Active = true
        btn.Selectable = false
        janitor:Add(btn.InputBegan:Connect(function(input)
            if input.UserInputType.Name:find("MouseButton") or input.UserInputType == Enum.UserInputType.Touch then
                fn()
            end
        end), "Disconnect")
    end
end

function SettingBindings.BindMenu(janitor, refs, onToggle, onClose)
    bindButton(janitor, refs.ToggleBtn, onToggle)
    bindButton(janitor, refs.Close, onClose)
end

function SettingBindings.BindAdjusters(janitor, adjusters, onChange, onReset)
    if not adjusters then return end
    for name, adj in pairs(adjusters) do
        if name ~= "Reset" and adj then
            bindButton(janitor, adj.Min, function()
                onChange(name, -1)
            end)
            bindButton(janitor, adj.Plus, function()
                onChange(name, 1)
            end)
        end
    end
    if adjusters.Reset then
        bindButton(janitor, adjusters.Reset, onReset)
    end
end

function SettingBindings.BindToggles(janitor, toggles, onChange)
    for name, t in pairs(toggles or {}) do
        bindButton(janitor, t.Sliding, function()
            onChange(name)
        end)
    end
end

return SettingBindings
