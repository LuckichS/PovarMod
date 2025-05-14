function HH:CanTransform(character)
    if
        HH.Players == nil or
        HH.Players[character.ID] == nil or
        HH.Players[character.ID].NextTransformAt == nil
    then
        return true
    end

    return HH.Players[character.ID].NextTransformAt < Timer.GetTime()
end

function HH:SetNextTransformAt(character, delay)

    HH.Players = HH.Players or {}

    local player = HH.Players[character.ID] or {}

    player.NextTransformAt = Timer.GetTime() + delay

    HH.Players[character.ID] = player

end

local function CopyCharacterInfoValues(speciesName, source, atable)

    local target = CharacterInfo(speciesName, source.Name, source.OriginalName, source.Job)

    -- Copy simple value properties directly
    target.Salary = source.Salary
    target.SetExperience(source.ExperiencePoints)
    target.AdditionalTalentPoints = source.AdditionalTalentPoints
    target.PermanentlyDead = source.PermanentlyDead
    target.RenamingEnabled = source.RenamingEnabled

    -- Copy structs like colors if exposed and modifiable
    target.Head = source.Head
    target.Head.SkinColor = atable.AllowSkinColor and source.Head.SkinColor or Color(255, 255, 255, 255)
    target.Head.HairColor = atable.AllowHair and source.Head.HairColor or Color(255, 255, 255, 255)
    target.Head.FacialHairColor = atable.AllowBeard and source.Head.FacialHairColor or Color(255, 255, 255, 255)

    -- Copy indices for hair/beard etc.
    target.Head.HairIndex = atable.AllowHair and source.Head.HairIndex or 0
    target.Head.BeardIndex = atable.AllowBeard and source.Head.BeardIndex or 0
    target.Head.MoustacheIndex = atable.AllowBeard and source.Head.MoustacheIndex or 0
    target.Head.FaceAttachmentIndex = atable.AllowFace and source.Head.FaceAttachmentIndex or 0

    return target

end

local function TransferInventory(oldCharacter, newCharacter)

    local slots = { InvSlotType.Card, InvSlotType.Headset, InvSlotType.Head,  InvSlotType.LeftHand, InvSlotType.RightHand, InvSlotType.OuterClothes, InvSlotType.InnerClothes, InvSlotType.Bag }

    if oldCharacter.Inventory then
        for _, slot in pairs(slots) do
            local item = oldCharacter.Inventory.GetItemInLimbSlot(slot)

            if item ~= nil then
                item.Drop()

                local index = newCharacter.Inventory.FindLimbSlot(slot)
                newCharacter.Inventory.TryPutItem(item, index, true, false)
            end
        end

        for _, items in pairs(oldCharacter.Inventory.FindAllItems()) do
            items.Drop()

            newCharacter.TryPutItemInAnySlot(items)
        end
    end

end

local function TransferTalents(oldCharacter, newCharacter)

    for _, talent in pairs(oldCharacter.CharacterTalents) do
        newCharacter.GiveTalent(talent.Prefab, true)
    end

end

local function TransferSkills(oldCharacter, newCharacter)

    for skillIdentity, _ in pairs(StatTypes) do
        local skill = oldCharacter.GetSkillLevel(skillIdentity)

        if skill > 0 then
            newCharacter.Info.SetSkillLevel(skillIdentity, skill, false)
        end
    end

end

local function TransferAfflictionsToLimbs(oldCharacter, newCharacter)

    local node = XElement("root")

    oldCharacter.CharacterHealth.Save(node)

    newCharacter.CharacterHealth.Load(node)

end

function HH:RespawnCharacter(oldCharacter, speciesName, characterSpawnedCallback)

    Entity.Spawner.AddCharacterToSpawnQueue(speciesName, oldCharacter.WorldPosition, function(newCharacter)
        local client = HH:GetCharacterClient(oldCharacter)

        local oldInfo = oldCharacter.Info
        local atable = (HH.Species[speciesName] and HH.Species[speciesName].CharacterInfoValues) or {}

        newCharacter.TeamID = oldCharacter.TeamID
        newCharacter.Info = CopyCharacterInfoValues(speciesName, oldInfo, atable)

        TransferInventory(oldCharacter, newCharacter)
        TransferTalents(oldCharacter, newCharacter)
        TransferSkills(oldCharacter, newCharacter)
        TransferAfflictionsToLimbs(oldCharacter, newCharacter)

        if client then
            client.SetClientCharacter(newCharacter)
        end

        HH:AddToCrew(newCharacter)
        HH:RemoveFromCrew(oldCharacter)

        print("Respawned " .. oldCharacter.Name .. " as " .. speciesName)

        if CLIENT then
            oldCharacter.Remove()
        else
            Entity.Spawner.AddEntityToRemoveQueue(oldCharacter)
        end

        newCharacter.CanSpeak = not HH.HusksAreMute

        if characterSpawnedCallback then
            characterSpawnedCallback(newCharacter)
        end
    end)

end

function HH:SetCanSpeek(character, canSpeak)

    if character == nil then
        return
    end

    character.CanSpeak = canSpeak

end