HH.ChatCommands = {}

HH.ChatCommands["!togglemutehusks"] = function (msgParts, client)
    if not CLIENT then -- Ignore permission in singleplayer
        if not client.CheckPermission(ClientPermissions.ConsoleCommands) then
            return
        end
    end

    HH.HusksAreMute = not HH.HusksAreMute

    for _, c in pairs(Client.ClientList) do
        HH:Message(c, "Server", "Husks are mute: " .. (HH.HusksAreMute and "on." or "off."), ChatMessageType.Private)
    end

    for _, c in pairs(Character.CharacterList) do
        if HH:IsHusk(c) then
            HH:SetCanSpeek(c, not HH.HusksAreMute)
        end
    end

    return true
end
--[[
We can't override CanClimb in any way, shape or form so ignore for now.

HH.ChatCommands["!toggleladdershusk"] = function (msgParts, client)
    if not client.CheckPermission(ClientPermissions.ConsoleCommands) then
        return
    end

    HH.husksClimbLadders = not HH.husksClimbLadders

    for _, c in pairs(Client.ClientList) do
        Game.SendDirectChatMessage(ChatMessage.Create("Server", "Husks can climb ladders: " .. (HH.husksClimbLadders and "on." or "off."), ChatMessageType.Private, nil, c, nil, nil), c)
    end

    for _, c in pairs(Character.CharacterList) do
        if HH:IsHusk(c) then
            c.Params.CanClimb = not HH.husksClimbLadders
        end
    end

    return true
end
]]