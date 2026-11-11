--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Packages = Shared.Packages
local Promise = require(Packages.Promise)

local Payload = require(script.Parent.Payload)
local CustomTitleNotification = require(script.Parent.Parent.Notifications.CustomTitleNotification)

local Actions = {}

function Actions.apply(ctx, overheadService)
    if not ctx.SelectedPlayer then
        return
    end
    local payload = Payload.Build(ctx)
    Promise.try(function()
        return overheadService:SetCustomTitle(ctx.SelectedPlayer.UserId, payload)
    end):andThen(function(ok, reason)
        if ok == false then
            local msg = "Failed to apply custom title"
            if reason == "NotPrivileged" then
                msg = "You don't have permission to give titles"
            elseif reason == "TargetOffline" then
                msg = "Target player is offline"
            elseif reason == "EmptyText" then
                msg = "Title text is empty"
            end
            CustomTitleNotification.error(msg)
        else
            CustomTitleNotification.success("Custom title applied")
        end
    end):catch(function(err)
        warn("[TitleMenu] apply failed: " .. tostring(err))
        CustomTitleNotification.error("Failed to apply custom title")
    end)
end

function Actions.remove(ctx, overheadService)
    if not ctx.SelectedPlayer then
        return
    end
    Promise.try(function()
        return overheadService:ClearCustomTitle(ctx.SelectedPlayer.UserId, ctx.Slot)
    end):andThen(function(ok, reason)
        if ok == false then
            local msg = "Failed to remove custom title"
            if reason == "NotPrivileged" then
                msg = "You don't have permission to remove titles"
            elseif reason == "TargetOffline" then
                msg = "Target player is offline"
            end
            CustomTitleNotification.error(msg)
        else
            CustomTitleNotification.success("Custom title removed")
        end
    end):catch(function(err)
        warn("[TitleMenu] remove failed: " .. tostring(err))
        CustomTitleNotification.error("Failed to remove custom title")
    end)
end

function Actions.clearInputs(ctx, refs)
    ctx:setText("")
    ctx.Colors = {nil, nil, nil, nil}
    if refs.InputText then
        refs.InputText.Text = ""
    end
    if refs.Color1Text then
        refs.Color1Text.Text = ""
    end
    if refs.Color2Text then
        refs.Color2Text.Text = ""
    end
    if refs.Color3Text then
        refs.Color3Text.Text = ""
    end
    if refs.Color4Text then
        refs.Color4Text.Text = ""
    end
end

return Actions
