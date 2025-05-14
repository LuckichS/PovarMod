local function handleNetOperation(messageName, findByIdFunc, callback)
    Networking.Receive(messageName, function (msgReader)

        local id = msgReader.ReadUInt16()
        local attempts = 0
        local maxAttempts = 5
        local initialDelay = 1000 -- in milliseconds

        local function attemptFunc()

            local character = findByIdFunc(id)

            if character ~= nil then
                callback(HH, character)
            else
                if attempts >= maxAttempts then
                    print(string.format("Failed to process %s for ID %d after %d attempts.", messageName, id, attempts))
                    return
                end

                attempts = attempts + 1

                Timer.Wait(attemptFunc, initialDelay * attempts)
            end
        end

        attemptFunc()
    end)
end

local function findCharacterInfoByID(id)
    for _, c in pairs(Game.GameSession.CrewManager.GetCharacterInfos()) do
        if c.ID == id then
            return { Info = c }
        end
    end

    return nil
end

Networking.Receive("husk_ping", HH.Ping)

handleNetOperation("husk_addToCrew", Entity.FindEntityByID, HH.AddToCrew)
handleNetOperation("husk_removeFromCrew", findCharacterInfoByID, HH.RemoveFromCrew)

local transformCounter = 0
local transformCooldown = 60
local nextTransformAt = 0

local function CheckTransformToProwler(character, deltaTime)

    if
        not character.IsRagdolled or
        not character.HasTalent("prowler_transform")
    then
        return
    end

    if not PlayerInput.KeyDown(InputType.Ragdoll) then
        transformCounter = 0
        return
    end

    transformCounter = transformCounter + deltaTime

    if transformCounter < 10 then
        return
    end

    if nextTransformAt > Timer.GetTime() then
        HH:Message(nil, "Conciousness", "I must rest before I can transform again.", ChatMessageType.Private)
        transformCounter = 0

        return
    end

    nextTransformAt = Timer.GetTime() + transformCooldown

    HH:HuskTransform()

end

local jumpCounter = 0
local jumpCooldown = 1
local nextJumpAt = 0

function CheckHuskJump(character, deltaTime)

    if character == nil then
        return
    end

    local species = HH.Species[character.SpeciesName.Value]

    if
        character.IsRagdolled or
        character.InWater or
        character.IsClimbing or
        not character.CanInteract or
        species == nil or
        not species.CanJump
    then
        return
    end

    if not PlayerInput.KeyDown(InputType.Up) then
        jumpCounter = 0
        return
    end

    jumpCounter = jumpCounter + deltaTime

    if jumpCounter < 1 then
        return
    end

    if nextJumpAt > Timer.GetTime() then
        jumpCounter = 0

        return
    end

    nextJumpAt = Timer.GetTime() + jumpCooldown

    HH:HuskJump(character)

end

Hook.Add("keyUpdate", "husk_keyUpdate", function(deltaTime)

    if Character.Controlled == nil then return end

    local character = Character.Controlled

    CheckTransformToProwler(character, deltaTime)
    CheckHuskJump(character, deltaTime)

end)