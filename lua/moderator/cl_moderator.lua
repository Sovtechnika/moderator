﻿--[[
    Copyright: Omar Saleh Assadi, Brian Hang 2014-2018; Licensed under the EUPL, with extension of article 5
    (compatibility clause) to any licence for distributing derivative works that have been
    produced by the normal use of the Work as a library
--]]
include("sh_util.lua")
include("sh_language.lua")
include("sh_moderator.lua")
CreateClientConVar("mod_clearoncommand", "1", true, true)

if (IsValid(moderator.menu)) then
    moderator.menu:Remove()
    moderator.menu = nil
    moderator.menu = vgui.Create("mod_Menu")
    MsgN("Reloaded moderator panel.")
end

net.Receive("mod_NotifyAction", function(length)
    local client = player.GetByID(net.ReadUInt(7))
    local target = net.ReadTable()
    local action = net.ReadString()
    local hasNoTarget = net.ReadBit() == 1
    local output

    if (IsValid(client)) then
        output = {client, color_white, " "}
    else
        output = {Color(180, 180, 180), "Console", color_white, " "}
    end

    if (action:find("*", nil, true)) then
        local exploded = string.Explode("*", action)
        output[#output + 1] = exploded[1]
        table.Add(output, moderator.TableToList(target))
        output[#output + 1] = exploded[2]
    else
        output[#output + 1] = action .. " "
        table.Add(output, moderator.TableToList(target, nil, hasNoTarget))
    end

    output[#output + 1] = "."
    chat.AddText(unpack(output))
end)

function moderator.Notify(message)
    chat.AddText(LocalPlayer(), color_white, ", " .. message)
end

net.Receive("mod_Notify", function(length)
    moderator.Notify(net.ReadString())
end)

do
    moderator.bans = moderator.bans or {}

    net.Receive("mod_BanList", function()
        moderator.bans = net.ReadTable()
    end)

    net.Receive("mod_BanAdd", function()
        local steamID = net.ReadString()
        local data = net.ReadString()
        moderator.bans[steamID] = von.deserialize(data)
        moderator.updateBans = true
    end)

    net.Receive("mod_BanRemove", function()
        local steamID = net.ReadString()
        moderator.bans[steamID] = nil
        moderator.updateBans = true
    end)

    net.Receive("mod_BanAdjust", function()
        local steamID = net.ReadString()
        local key = net.ReadString()
        local index = net.ReadUInt(8)
        local value = net.ReadType(index)

        if (moderator.bans[steamID]) then
            moderator.bans[steamID][key] = value
            moderator.updateBans = true
        end
    end)

    function moderator.AdjustBan(steamID, key, value)
        if (not LocalPlayer():CheckGroup("superadmin")) then return end
        net.Start("mod_BanAdjust")
        net.WriteString(steamID)
        net.WriteString(key)
        net.WriteType(value)
        net.SendToServer()
    end
end

do
    net.Receive("mod_AdminMessage", function(length)
        chat.AddText(Color(255, 50, 50), "[ADMIN] ", player.GetByID(net.ReadUInt(8)), color_white, ": " .. net.ReadString())
    end)

    net.Receive("mod_AllMessage", function(length)
        chat.AddText(Color(255, 50, 50), "[ALL] ", player.GetByID(net.ReadUInt(8)), color_white, ": " .. net.ReadString())
    end)
end