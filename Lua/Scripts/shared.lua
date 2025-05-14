local damageTable = {
    antidama1 = {
        Damage = 30,
    },
    antidama2 = {
        Damage = 20,
    },
    antibleeding1 = {
        Damage = 1.5,
    },
    antibleeding2 = {
        Damage = 5,
    },
    antibleeding3 = {
        Damage = 40,
    },
    pomegrenadeextract = {
        Damage = 0.32,
    },
    antibloodloss1 = {
        Damage = 2.5,
    },
    antibloodloss2 = {
        Damage = 8,
    },
    deusizine = {
        Damage = 3,
    },
    liquidoxygenite = {
        Damage = 2.5,
    },
    calyxanide = {
        Damage = 180,
    },
    antipsychosis = {
        Damage = 100,
    },
    antinarc = {
        Damage = 2,
    },
    morbusineantidote = {
        Damage = 10,
    },
    cyanideantidote = {
        Damage = 10,
    },
    sufforinantidote = {
        Damage = 20,
    },
    deliriumineantidote = {
        Damage = 20,
    },
    antirad = {
        Damage = 100,
    },
    antiparalysis = {
        Damage = 150,
    },
    elastin = {
        Damage = 0,
    },
    opium = {
        Damage = 0.8,
    },
    antibiotics = {
        Damage = 60,
    },
    stabilozine = {
        Damage = 0,
    },
    adrenaline = {
        Damage = 8,
    },
    tonicliquid = {
        Damage = 0.1,
    }
}

HH.HusksAreMute = true
HH.Species = {
    Husk_player = {
        ApplyTreatmentModifier = damageTable,
        CharacterInfoValues = {
            AllowFace = true,
        }
    },
    Husk_player_chimera = {
        ApplyTreatmentModifier = damageTable,
        CanJump = true,
        JumpForce = 800,
        CharacterInfoValues = {
            AllowFace = true,
        }
    },
    Husk_player_prowler = {
        ApplyTreatmentModifier = damageTable,
        CanJump = true,
        JumpForce = 450,
        CharacterInfoValues = {
            AllowFace = true,
        }
    },
    Husk_player_exosuit = {
        ApplyTreatmentModifier = damageTable,
        CharacterInfoValues = {}
    },
}
HH.Jobs = {
    PlayerHuskJob = {
        SpeciesName = "Husk_player",
    }
}

function HH:IsServer()
    return SERVER or not Game.IsMultiplayer
end

function HH:Ping(client)

    -- Don't need to check if client has clientside lua on clients.
    if CLIENT and not Game.IsMultiplayer then
        print("Send pong to server")
        local netMsg = Networking.Start("husk_pong")
        Networking.Send(netMsg, nil, DeliveryMethod.Reliable)
    else
        print("Send ping to client")
        local netMsg = Networking.Start("husk_ping")
        Networking.Send(netMsg, client.Connection, DeliveryMethod.Reliable)

        Timer.Wait(function()
            print(HH.HasClientsideLua)
            if not HH.HasClientsideLua or not HH.HasClientsideLua[client] then
                HH:Message(client, "Conciousness", "No client-side Lua detected, don't submit a bug report, install client-side Lua.", ChatMessageType.Private)
            end
        end, 1000)
    end

end

function HH:Pong(client)

    -- We can't receive pongs in singleplayer.
    if CLIENT and not Game.IsMultiplayer then
        return
    end

    if CLIENT then
        return
    end
    
    HH.HasClientsideLua = HH.HasClientsideLua or {}
    HH.HasClientsideLua[client] = true

end

function HH:GetCharacterClient(character)

    for _, client in pairs(Client.ClientList) do
        if client.Character == character then
            return client
        end
    end

end

function HH:GetLocalClient()

    for _, c in pairs(Client.ClientList) do
        if c.IsOwner then
            return c
        end
    end

end

function HH:AddToCrew(character)

    if not character or character.IsDead then
        return
    end

    if CLIENT then
        if Game.IsMultiplayer then
            local client = HH:GetLocalClient()

            if client and character.TeamID ~= client.TeamID then
                return
            end
        end

        Game.GameSession.CrewManager.AddCharacter(character)
    else
        local netMsg = Networking.Start("husk_addToCrew")
        netMsg.WriteUInt16(character.ID)
        Networking.Send(netMsg, nil, DeliveryMethod.Reliable)

        Game.GameSession.CrewManager.AddCharacter(character)
    end

end

function HH:RemoveFromCrew(character)

    if not HH:IsServer() then
        Game.GameSession.CrewManager.RemoveCharacterInfo(character.Info, true, true)
    elseif CLIENT then
        Game.GameSession.CrewManager.RemoveCharacter(character, true, true)
    else
        local netMsg = Networking.Start("husk_removeFromCrew")

        netMsg.WriteUInt16(character.Info.ID)
        Networking.Send(netMsg, nil, DeliveryMethod.Reliable)

        Game.GameSession.CrewManager.RemoveCharacter(character, true, true)
    end

end

function HH:Message(client, sender, message, type)

    if type == nil then
        type = ChatMessageType.Private
    end

    local message = ChatMessage.Create(sender, message, type, nil, client, nil, nil)

    if SERVER then
        Game.SendDirectChatMessage(message, client)
    else
        Game.ChatBox.AddMessage(message)
    end

end

local function TransformToFromProwler(character)

    if not character.HasTalent("prowler_transform") then
        return false
    end

    local speciesName = "Husk_player_prowler"
    if character.SpeciesName == speciesName then
        speciesName = "Husk_player"
    end

    HH:RespawnCharacter(character, speciesName)

    return true

end

function HH:HuskTransform(client)

    if HH:IsServer() then

        local character = client and client.Character or Character.Controlled

        if character == nil then
            return
        end

        if not character.IsRagdolled then
            return -- Someone is probably cheating?
        end

        if not HH:CanTransform(character) then
            HH:Message(client, "Conciousness", "I must rest before I can transform again.", ChatMessageType.Private)

            return
        end

        if not TransformToFromProwler(character) then
            return
        end

        HH:SetNextTransformAt(character, 60)

    elseif CLIENT then

        local msgWriter = Networking.Start("husk_transform")
        Networking.Send(msgWriter)

    end

end

function HH:HuskJump(character)

    if HH:IsServer() then
        if
            character == nil or
            character.IsRagdolled or
            character.IsForceRagdolled or
            character.InWater or
            not character.CanInteract
        then
            return
        end
    
        local species = HH.Species[character.SpeciesName.Value]
    
        if
            character == nil or
            not species.CanJump
        then
            return
        end
    
        character.IsForceRagdolled = true
    
        Timer.Wait(function()
            if character == nil then
                return
            end

            for _, limb in pairs(character.AnimController.Limbs) do
                limb.body.ApplyForce(Vector2(0, species.JumpForce))
            end
        end, 100)
    
        Timer.Wait(function()
            if character == nil then
                return
            end

            character.IsForceRagdolled = false
        end, 400)
    else
        local msgWriter = Networking.Start("husk_jump")
        Networking.Send(msgWriter)
    
        character.IsForceRagdolled = true
    
        Timer.Wait(function() 
            if character == nil then
                return
            end
    
            character.IsForceRagdolled = false
    
        end, 500)
    end

end

function HH:HasValue(table, str)

    for _, v in pairs(table) do
        if v == str then
            return true
        end
    end

    return false

end

function HH:IsHusk(character)
    return HH.Species[character.SpeciesName.Value] ~= nil
end

function HH:StringSplit(s, sep)
    local fields = {}
    
    local sep = sep or " "
    local pattern = string.format("([^%s]+)", sep)
    string.gsub(s, pattern, function(c) fields[#fields + 1] = c end)
    
    return fields
end

local exosuit = ItemPrefab.Find(nil, "exosuit")
local clownExosuit = ItemPrefab.Find(nil, "clownexosuit")
local hhExosuitBackpack = ItemPrefab.Find(nil, "hh_exosuit_backpack")

local itemHooks = {}
itemHooks[hhExosuitBackpack.Identifier] = {
    drop = function(item, character)
        return character ~= nil -- Never allow dropping
    end,
    inventoryPutItem = function(inventory, item, character, index, removeItemBool)
        return character ~= nil and character.SpeciesName == "Husk_player_exosuit" -- Allow picking up only for exosuit
    end,
    inventoryItemSwap = function(inventory, item, character, index, swapWholeStack)
        return character ~= nil -- Never allow swapping
    end,
}
itemHooks[clownExosuit.Identifier] = {
    inventoryPutItem = function(inventory, item, character, index, swapWholeStack)
        if CLIENT and Game.IsMultiplayer then
            return false
        end

        if
            not character or
            not character.HasTalent("exosuit_transform") or
            not character.SpeciesName == "Husk_player"
        then
            return
        end

        HH:RespawnCharacter(character, "Husk_player_exosuit", function(newCharacter)
            Entity.Spawner.AddItemToSpawnQueue(hhExosuitBackpack, newCharacter.Inventory, nil, nil, function() print(":D") end, true, false, InvSlotType.Bag)
        end)

        Entity.Spawner.AddEntityToRemoveQueue(item)

    end
}
itemHooks[exosuit.Identifier] = itemHooks[clownExosuit.Identifier]

Hook.Add("item.drop", "husk_itemUnequip", function(item, character)

    local hook = itemHooks[item.Prefab.Identifier]
    if hook and hook.drop then
        return hook.drop(item, character)
    end

end)

Hook.Add("item.equip", "husk_itemEquip", function(item, character)

    local hook = itemHooks[item.Prefab.Identifier]
    if hook and hook.equip then
        return hook.equip(item, character)
    end

end)

Hook.Add("inventoryItemSwap", "husk_inventoryItemSwap", function(inventory, item, characterUser, index, swapWholeStackBool)

    local hook = itemHooks[item.Prefab.Identifier]
    if hook and hook.inventoryItemSwap then
        return hook.inventoryItemSwap(inventory, item, characterUser, index, swapWholeStackBool)
    end

end)

Hook.Add("inventoryPutItem", "husk_inventoryPutItem", function(inventory, item, characterUser, index, removeItemBool)

    local hook = itemHooks[item.Prefab.Identifier]
    if hook and hook.inventoryPutItem then
        return hook.inventoryPutItem(inventory, item, characterUser, index, removeItemBool)
    end

end)

Hook.Patch(
"Barotrauma.Character",
"get_IsHuman",
{ },
function(instance, ptable)

    return ptable.OriginalReturnValue or instance.Params.UseHumanAI

end,
Hook.HookMethodType.After)
