setclipboard(getgenv().antifling = true/false)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

getgenv().antifling = true

local connections = {}
local processedPlayers = {}

local function processCharacterParts(character)
    if not character or not getgenv().antifling then return end
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
    local descendantConnection = character.DescendantAdded:Connect(function(descendant)
        if getgenv().antifling and descendant:IsA("BasePart") then
            descendant.CanCollide = false
        end
    end)
    return descendantConnection
end

local function setupPlayer(targetPlayer)
    if targetPlayer == player or processedPlayers[targetPlayer] then return end
    processedPlayers[targetPlayer] = true
    if targetPlayer.Character then
        local conn = processCharacterParts(targetPlayer.Character)
        if conn then
            connections[targetPlayer] = connections[targetPlayer] or {}
            connections[targetPlayer].descendant = conn
        end
    end
    local charConnection = targetPlayer.CharacterAdded:Connect(function(character)
        if not getgenv().antifling then return end
        if connections[targetPlayer] and connections[targetPlayer].descendant then
            connections[targetPlayer].descendant:Disconnect()
        end
        local conn = processCharacterParts(character)
        if conn then
            connections[targetPlayer] = connections[targetPlayer] or {}
            connections[targetPlayer].descendant = conn
        end
    end)
    connections[targetPlayer] = connections[targetPlayer] or {}
    connections[targetPlayer].character = charConnection
end

local function cleanupPlayer(targetPlayer)
    if connections[targetPlayer] then
        for _, conn in pairs(connections[targetPlayer]) do
            if conn then conn:Disconnect() end
        end
        connections[targetPlayer] = nil
    end
    processedPlayers[targetPlayer] = nil
end

for _, targetPlayer in pairs(Players:GetPlayers()) do
    if targetPlayer ~= player then
        setupPlayer(targetPlayer)
    end
end

local playerAddedConnection = Players.PlayerAdded:Connect(function(targetPlayer)
    if targetPlayer ~= player then
        setupPlayer(targetPlayer)
    end
end)

local playerRemovingConnection = Players.PlayerRemoving:Connect(function(targetPlayer)
    cleanupPlayer(targetPlayer)
end)

local reactivateConnection = RunService.Heartbeat:Connect(function()
    if getgenv().antifling then
        for _, targetPlayer in pairs(Players:GetPlayers()) do
            if targetPlayer ~= player and targetPlayer.Character then
                for _, part in pairs(targetPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end
    end
end)
