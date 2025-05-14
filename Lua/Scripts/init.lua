dofile(HH.HuntersHusks.Path .. "/Lua/Scripts/utility.lua")
dofile(HH.HuntersHusks.Path .. "/Lua/Scripts/chat.lua")

Networking.Receive("husk_transform", function(_, client) HH:HuskTransform(client) end)
Networking.Receive("husk_jump", function(_, client) HH:HuskJump(client.Character) end)
Networking.Receive("husk_pong", function(_, client) HH:Pong(client) end)

Hook.Add("character.created", "husk_convertJobs", function(character)

    Timer.Wait(function()

        if
            character == nil or
            character.Info == nil or
            character.Info.Job == nil or
            character.isDead
        then
            return
        end

        local job = HH.Jobs[character.Info.Job.Prefab.Identifier.Value]

        if job == nil then
            return
        end

        if character.SpeciesName == "Human" then
            print("Respawning " .. character.Name .. " as " .. job.SpeciesName)

            HH:RespawnCharacter(character, job.SpeciesName)

            return
        elseif
            (
                character.SpeciesName == "Husk_player_chimera" or
                character.SpeciesName == "Husk_player_prowler"
            ) and character.TeamID == 3
        then
            character.TeamID = 1
        end

        HH:AddToCrew(character)
        HH:SetCanSpeek(character, not HH.HusksAreMute)

        HH:Ping(HH:GetCharacterClient(character))

    end, 1000)

end)

local healBuffPrefab = AfflictionPrefab.Prefabs["HHHealBuff"]
local medicineDebuffPrefab = AfflictionPrefab.Prefabs["HHMedicineDebuff"]

local function OnApplyMedicationToHusk(item, usingCharacter, targetCharacter, limb)

    local species = HH.Species[targetCharacter.SpeciesName.Value]

    if species == nil then
        return false
    end

    local identifier = item.Prefab.Identifier.Value
    local affliction = species.ApplyTreatmentModifier[identifier]

    if affliction == nil then
        return false
    end

    local toLimb = targetCharacter.AnimController.GetLimb(LimbType.Torso)

    targetCharacter.CharacterHealth.ApplyAffliction(toLimb, medicineDebuffPrefab.Instantiate(affliction.Damage))

    Entity.Spawner.AddItemToRemoveQueue(item)

    return true

end

local function OnApplyMedicationFromHusk(item, usingCharacter, targetCharacter, limb)

    local species = HH.Species[usingCharacter.SpeciesName.Value]

    if species == nil then
        return false
    end

    if not usingCharacter.HasTalent("symbiosis") then
        return false
    end

    local identifier = item.Prefab.Identifier.Value
    local affliction = species.ApplyTreatmentModifier[identifier]

    if affliction == nil then
        return false
    end

    local toLimb = targetCharacter.AnimController.GetLimb(LimbType.Torso)

    targetCharacter.CharacterHealth.ApplyAffliction(toLimb, healBuffPrefab.Instantiate(affliction.Damage / 2))

end

local function TryTransformToChimera(item, usingCharacter, targetCharacter, limb)

    if not usingCharacter.HasTalent("chimera_transform") then
        return false
    end

    if item.Prefab.Identifier ~= "hh_brainslug" then
        return false
    end

    if usingCharacter.SpeciesName ~= "Husk_player" then
        return false
    end

    if targetCharacter.Vitality <= 90 then
        return false
    end

    usingCharacter.IsForceRagdolled = true
    targetCharacter.IsForceRagdolled = true

    targetCharacter.CharacterHealth.ApplyAffliction(limb, medicineDebuffPrefab.Instantiate(100))

    local shouldSpasm = true
    local direction = true

    local function Spasm()
        if not shouldSpasm then
            return
        end

        if usingCharacter ~= nil or targetCharacter == nil then
            local torso1 = usingCharacter.AnimController.GetLimb(LimbType.Torso)

            torso1.body.ApplyTorque(direction and 100 or -100)
        end

        if targetCharacter ~= nil then
            local torso2 = targetCharacter.AnimController.GetLimb(LimbType.Torso)

            torso2.body.ApplyTorque(direction and 100 or -100)
        end

        direction = not direction

        Timer.Wait(Spasm, 100)
    end

    Timer.Wait(Spasm, 100)

    Timer.Wait(function()
        if usingCharacter ~= nil then
            usingCharacter.IsForceRagdolled = false

            HH:RespawnCharacter(usingCharacter, "Husk_player_chimera")
        end

        if targetCharacter ~= nil then
            targetCharacter.CharacterHealth.ReduceAllAfflictionsOnAllLimbs(-100) -- Make the player explode
            targetCharacter.IsForceRagdolled = false
        end

        shouldSpasm = false

        if item ~= nil then
            Entity.Spawner.AddItemToRemoveQueue(item)
        end
    end, 15000)

    return true

end

Hook.Add("item.applyTreatment", "husk_applyMedication", function(item, usingCharacter, targetCharacter, limb)

    if -- invalid use, dont do anything
        item == nil or
        usingCharacter == nil or
        targetCharacter == nil or
        targetCharacter.SpeciesName == nil or
        targetCharacter.SpeciesName.Value == nil or
        limb == nil
    then return end

    return
        OnApplyMedicationToHusk(item, usingCharacter, targetCharacter, limb) or
        OnApplyMedicationFromHusk(item, usingCharacter, targetCharacter, limb) or
        TryTransformToChimera(item, usingCharacter, targetCharacter, limb)

end)

Hook.Add("chatMessage", "husk_commands", function(message, client)

    local msgParts = HH:StringSplit(message:lower(), " ")
    local command = msgParts[1]

    if HH.ChatCommands[command] ~= nil then
        return HH.ChatCommands[msgParts[1]](msgParts, client)
    end

end)

Hook.Patch(
    "Barotrauma.AIObjectiveRescueAll",
    "IsValidTarget",
    {
        "Barotrauma.Character",
        "Barotrauma.Character",
        "out System.Boolean"
    },
    function (_, ptable)
        if HH:IsHusk(ptable["target"]) then
            return false
        end

        return ptable.OriginalReturnValue
    end,
    Hook.HookMethodType.After
)
