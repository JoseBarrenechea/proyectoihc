local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Structures = ReplicatedStorage:WaitForChild("Structures")
local queue = require(Structures:WaitForChild("Queue"))
local Client = require(Structures:WaitForChild("Client"))
local RandomSet = require(Structures:WaitForChild("RandomSet"))
local PathfindingModule = require(script.Parent.PathfindingModule)
local tw = game:GetService("TweenService")
local y_botones_ini,y_botones_fi = -2,5.5
	

local Game = {}
Game.__index = Game

function Game.new(workers)
	local self = setmetatable({}, Game)

	-- Array de workers (players)
	self.workers = workers or {}
	self.currentDay = 1
	self.clientQueue = queue.new({ mode = "max" })
	self.clientCounter = 0
	self.set = RandomSet.new()
	
	for i = 1, 6 do
		self.set:insert(i)
	end
	
	self.Modulos = {
		{}
	}
	


	-- Control del juego
	self.isRunning = false
	self.clientSpawnInterval = 15
	self.dayDuration = 60 
	self.Intermission = true

	return self
end


function Game:Takeseat(char,num)
	
	PathfindingModule.MoveTo(char, workspace.Plats:FindFirstChild("Seat"..num))

	
end

function Game:spawnClients()
	self.spawnClientsActive = true
	while self.isRunning and (not self.Intermission) do
		local spawnInterval = self:getClientSpawnInterval()

		-- Crear y añadir cliente a la cola
		self.clientCounter = self.clientCounter + 1
		
		local char = game.ReplicatedStorage.Rig:Clone()
		char.Parent = workspace
		char.PrimaryPart.CFrame = workspace.npcspawn.CFrame

		local nose = Instance.new("BoolValue")
		nose.Name = "C-" .. self.clientCounter
		nose.Parent = game.ReplicatedStorage.Fila
		
		local newClient = Client.new("C-" .. self.clientCounter)
		newClient.char = char
		newClient.tag = nose
		self.clientQueue:push(newClient)

		print("🧑 Cliente #" .. self.clientCounter .. " añadido a la cola")
		print("📊 Clientes en cola: " .. self.clientQueue:size())
		
		
		
		
		if not self.set:isEmpty() then
			
			local random = self.set:popRandom()
			self:Takeseat(char,random)
			
		end
		
		-- Esperar el intervalo antes del siguiente spawn
		task.wait(spawnInterval)
	end
	
end

function Game:StartSpawnClients()
	if self.spawnClientsActive then
		warn("Ya hay un sistema de spawn activo")
		return
	end

	print("▶️ Iniciando sistema de spawn de clientes...")
	self.clientSpawnThread = task.spawn(function()
		self:spawnClients()
	end)
end

function Game:StopSpawningClients()
	self.spawnClientsActive = false
	if self.clientSpawnThread then
		task.cancel(self.clientSpawnThread)
	end
end


local function tipoTexto(label,textoCompleto)
	for i = 1, #textoCompleto do
		label.Text = textoCompleto:sub(1, i)

		wait(.1)
	end
end

function Game:AtenderCliente(player,num)
	
	local cli = self.clientQueue:pop()
	
	
	local resultado,mensaje = PathfindingModule.MoveTo(cli.char, workspace.Plats:FindFirstChild(num),1)
	
	
	if resultado then
		
		
		local clonchat = ReplicatedStorage.Chat:Clone()
		clonchat.text.GA.Text.Text = " "
		clonchat.CFrame = cli.char.Head.CFrame * CFrame.new(-.85,1.5,0)
		clonchat.Transparency = 1
		clonchat.Parent = workspace
		
		tw:Create(clonchat,TweenInfo.new(.2
			,Enum.EasingStyle.Linear),{Transparency = 0.6 }):Play()
		
		task.wait(.2)

        local opcioones =  {"Quiero un chip", "Quiero hacer un reporte"}
        tipoTexto(clonchat.text.GA.Text,opcioones[math.random(1,2)])


	
		local errorb = workspace.Modulos["Modulo"..num].Error
		local activarb = workspace.Modulos["Modulo"..num].Activar

		local t_ = tw:Create(errorb,TweenInfo.new(.6
			,Enum.EasingStyle.Linear),{Position = Vector3.new(errorb.Position.X,y_botones_fi,errorb.Position.Z) })
		local t_2 = tw:Create(activarb,TweenInfo.new(.6
			,Enum.EasingStyle.Linear),{Position = Vector3.new(activarb.Position.X,y_botones_fi,activarb.Position.Z) })
		t_:Play()
		t_2:Play()
		
		
		local cdError = Instance.new("ClickDetector")
		cdError.Parent = errorb

		local cdActivar = Instance.new("ClickDetector")
		cdActivar.Parent = activarb
		
		local conexionError
		local conexionActivar

		self.Modulos[tonumber(num)] = {player,cli}


		local function limpiarClicks(bot)
			
			clonchat:Destroy()

			
			tw:Create(bot.SurfaceGui.Frame,TweenInfo.new(.2
				,Enum.EasingStyle.Linear),{Transparency = 1 }):Play()

			tw:Create(bot,TweenInfo.new(.2
				,Enum.EasingStyle.Linear),{Transparency = 0 }):Play()

			---------------------------------
			task.wait(.3)
			
			tw:Create(errorb,TweenInfo.new(.5
				,Enum.EasingStyle.Linear),{Position = Vector3.new(errorb.Position.X,
					y_botones_ini,errorb.Position.Z) }):Play()
			
			tw:Create(activarb,TweenInfo.new(.5
				,Enum.EasingStyle.Linear),{Position = Vector3.new(activarb.Position.X,
					y_botones_ini,activarb.Position.Z) }):Play()
			
			
			
			-----------------------------
			
			task.wait(.49)
			bot.SurfaceGui.Frame.Transparency = 0.3
			bot.Transparency = 1
			cli.tag:Destroy()
			
			self.Modulos[tonumber(num)] = {}
			cli.char:Destroy()
			
			if conexionError then
				conexionError:Disconnect()
			end
			if conexionActivar then
				conexionActivar:Disconnect()
			end
			if cdError then
				cdError:Destroy()
			end
			if cdActivar then
				cdActivar:Destroy()
			end
		end
		
		conexionError = cdError.MouseClick:Connect(function(player)
  
			limpiarClicks(errorb)  
		end)

 		conexionActivar = cdActivar.MouseClick:Connect(function(player)
  
			limpiarClicks(activarb)  
		end)
		
		
		
		
	end
	


	
	return cli
	
end

function Game:DayStart()
	print("Iniciando dia ",self.currentDay)
	
	while self.isRunning do
		self.Intermission = false
		
		local dayDuration = self:getDayDuration()
		local spawnInterval = self:getClientSpawnInterval()
		
		print("\n╔═══════════════════════════════════════╗")
		print("║         DÍA " .. self.currentDay .. " INICIADO           ║")
		print("╚═══════════════════════════════════════╝")
		print("⏱️  Duración: " .. dayDuration .. " segundos")
		print("🔄 Spawn cada: " .. string.format("%.1f", spawnInterval) .. " segundos")
		print("👷 Trabajadores: " .. #self.workers)
		
		
		local dayStartTime = tick()
		
		-- habria una funcion tipo task.spawn que genera clientes en un while 
		
		self:StartSpawnClients()
		
		while tick() - dayStartTime < dayDuration and self.isRunning do
			task.wait(1)
		end
		
		self:StopSpawningClients()
		
		print("Dia termiando !!!")
		self.currentDay = self.currentDay + 1
		self.Intermission = true 
		if self.Intermission then
			print("\n⏸️ Intermisión de 10 segundos...")
			task.wait(10)
		end
		
		-- detendria esa funcion task.spawn
		
	end
end

function Game:start()
	if self.isRunning then
		warn("El juego ya está corriendo")
		return
	end

	if #self.workers == 0 then
		warn("No hay trabajadores disponibles")
		return
	end

	self.isRunning = true
	self.Intermission = false
	print("=== JUEGO INICIADO ===")
	
	local db = true
	
	for _,v in pairs(workspace.Modulos:GetChildren()) do
		if v:IsA("Folder") then
			local numero = string.match(v.Name, "%d+$")
			local mb = v:FindFirstChild("MB")
			if not mb then continue end
			local click : ClickDetector = mb:FindFirstChild("ClickDetector")
			click.MouseClick:Connect(function(player)
 				if not db then return end 
				db = false 
				if self.Modulos[tonumber(numero)][1] == nil and (not self.clientQueue:isEmpty()) then

					local cliente = self:AtenderCliente(player,numero)


				end

				db = true
			end)
			
			
 			
			
		end
	end

	self:DayStart()
	
	

	
	
end

function Game:getDayDuration()
	return self.dayDuration
end

function Game:getClientSpawnInterval()
	return self.clientSpawnInterval
end


return Game
