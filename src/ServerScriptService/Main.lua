local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Structures = ReplicatedStorage:WaitForChild("Structures")
local StartEvent = ReplicatedStorage:WaitForChild("START")
local GameModule = require(script.Parent.Game)

local empezo = false 

StartEvent.OnServerEvent:Connect(function()
	
	local workers = game.Players:GetPlayers()
	
	local gameInstance = GameModule.new(workers)

	gameInstance:start()

	
end)

 
-- Agregar/remover workers dinámicamente
game.Players.PlayerAdded:Connect(function(player)
	--gameInstance:addWorker(player)
end)

game.Players.PlayerRemoving:Connect(function(player)
	--gameInstance:removeWorker(player)
end)

 
