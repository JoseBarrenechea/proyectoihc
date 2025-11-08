-- MÓDULO: PathfindingModule
-- Coloca este script como ModuleScript en ReplicatedStorage o ServerScriptService

local PathfindingService = game:GetService("PathfindingService")

local PathfindingModule = {}

-- Configuración del pathfinding
local PATH_CONFIG = {
	AgentRadius = 2,
	AgentHeight = 5,
	AgentCanJump = true,
	WaypointSpacing = 4
}

-- Configuración de visualización
local VISUAL_CONFIG = {
	ShowWaypoints = true, -- Cambiar a false para desactivar visualización
	WaypointSize = Vector3.new(1, 1, 1),
	WaypointColor = Color3.fromRGB(0, 255, 0), -- Verde
	JumpWaypointColor = Color3.fromRGB(255, 255, 0), -- Amarillo para saltos
	LineThickness = 0.2,
	LineColor = Color3.fromRGB(255, 0, 0), -- Rojo para líneas
	Duration = 3, -- Segundos que permanecen visibles
	Transparency = 0.5
}

-- Función para calcular la distancia total del camino
local function calculatePathDistance(waypoints)
	local totalDistance = 0
	for i = 1, #waypoints - 1 do
		local distance = (waypoints[i + 1].Position - waypoints[i].Position).Magnitude
		totalDistance = totalDistance + distance
	end
	return totalDistance
end

-- Función para visualizar los waypoints
local function visualizeWaypoints(waypoints)
	if not VISUAL_CONFIG.ShowWaypoints then return end

	local visualFolder = Instance.new("Folder")
	visualFolder.Name = "PathVisualization"
	visualFolder.Parent = workspace

	-- Dibujar cada waypoint
	for i, waypoint in ipairs(waypoints) do
		-- Crear esfera para el waypoint
		local sphere = Instance.new("Part")
		sphere.Name = "Waypoint_" .. i
		sphere.Shape = Enum.PartType.Ball
		sphere.Size = VISUAL_CONFIG.WaypointSize
		sphere.Position = waypoint.Position
		sphere.Anchored = true
		sphere.CanCollide = false
		sphere.Transparency = VISUAL_CONFIG.Transparency
		sphere.Material = Enum.Material.Neon

		-- Color diferente para waypoints de salto
		if waypoint.Action == Enum.PathWaypointAction.Jump then
			sphere.Color = VISUAL_CONFIG.JumpWaypointColor
		else
			sphere.Color = VISUAL_CONFIG.WaypointColor
		end

		sphere.Parent = visualFolder

		-- Dibujar línea al siguiente waypoint
		if i < #waypoints then
			local nextWaypoint = waypoints[i + 1]
			local distance = (nextWaypoint.Position - waypoint.Position).Magnitude

			local line = Instance.new("Part")
			line.Name = "Line_" .. i
			line.Size = Vector3.new(VISUAL_CONFIG.LineThickness, VISUAL_CONFIG.LineThickness, distance)
			line.Anchored = true
			line.CanCollide = false
			line.Transparency = VISUAL_CONFIG.Transparency
			line.Material = Enum.Material.Neon
			line.Color = VISUAL_CONFIG.LineColor

			-- Posicionar línea entre dos waypoints
			local midPoint = (waypoint.Position + nextWaypoint.Position) / 2
			line.CFrame = CFrame.lookAt(midPoint, nextWaypoint.Position)

			line.Parent = visualFolder
		end
	end

	-- Eliminar visualización después del tiempo especificado
	game:GetService("Debris"):AddItem(visualFolder, VISUAL_CONFIG.Duration)
end

--[[
    Mueve un personaje a una posición usando pathfinding
    
    Parámetros:
    - character: El modelo del personaje (debe tener Humanoid y HumanoidRootPart)
    - destination: Vector3 de la posición destino O un objeto (Part, Model) con CFrame
    - timeToReach: (Opcional) Tiempo en segundos para llegar. Si no se especifica, usa velocidad normal del humanoid
    
    Retorna:
    - success: true si llegó exitosamente, false si falló
    - message: Mensaje de éxito o error
]]
function PathfindingModule.MoveTo(character, destination, timeToReach)
	-- Validar que el personaje existe
	local bloque_nombre = destination.Name
	destination = destination.Position
	if not character or not character:FindFirstChild("Humanoid") or not character:FindFirstChild("HumanoidRootPart") then
		warn("El personaje no tiene Humanoid o HumanoidRootPart")
		return false, "Personaje inválido"
	end

	local humanoid = character.Humanoid
	local rootPart = character.HumanoidRootPart
	local originalSpeed = humanoid.WalkSpeed

	if humanoid.Sit then
		humanoid.Sit = false
		task.wait(0.3)
		print("Personaje levantado de asiento")
	end

	-- Determinar posición destino y CFrame final (si existe)
	local destinationPos
	local finalCFrame = nil

	if typeof(destination) == "Vector3" then
		destinationPos = destination
	elseif typeof(destination) == "Instance" then
		if destination:IsA("BasePart") then
			-- Ajustar destino al nivel del piso (parte inferior del objeto)
			local objectBottom = destination.Position.Y - (destination.Size.Y / 2)
			destinationPos = Vector3.new(destination.Position.X, objectBottom, destination.Position.Z)
			finalCFrame = destination.CFrame
		elseif destination:IsA("Model") and destination.PrimaryPart then
			local objectBottom = destination.PrimaryPart.Position.Y - (destination.PrimaryPart.Size.Y / 2)
			destinationPos = Vector3.new(destination.PrimaryPart.Position.X, objectBottom, destination.PrimaryPart.Position.Z)
			finalCFrame = destination.PrimaryPart.CFrame
		else
			warn("El destino debe ser un Part, Model con PrimaryPart, o Vector3")
			return false, "Destino inválido"
		end
	else
		warn("El destino debe ser un Vector3 o Instance")
		return false, "Tipo de destino inválido"
	end

	-- Crear el path
	local path = PathfindingService:CreatePath(PATH_CONFIG)

	-- Calcular el camino
	local success, errorMessage = pcall(function()
		path:ComputeAsync(rootPart.Position, destinationPos)
	end)

	if not success or path.Status ~= Enum.PathStatus.Success then
		warn("No se pudo calcular el camino: " .. tostring(errorMessage))
		return false, "Error al calcular camino"
	end

	local waypoints = path:GetWaypoints()

	-- SOLUCIÓN: Hacer que el personaje mire hacia el destino ANTES de filtrar waypoints
	local directionToDestination = (destinationPos - rootPart.Position).Unit
	local lookAtDestination = Vector3.new(destinationPos.X, rootPart.Position.Y, destinationPos.Z)

	if (lookAtDestination - rootPart.Position).Magnitude > 0.5 then
		rootPart.CFrame = CFrame.lookAt(rootPart.Position, lookAtDestination)
		task.wait(0.1) -- Pequeña pausa para que se oriente
		print("Personaje orientado hacia el destino")
	end

	-- Ahora filtrar waypoints basándose en la NUEVA orientación
	local filteredWaypoints = {}
	local lookDirection = rootPart.CFrame.LookVector

	for i, waypoint in ipairs(waypoints) do
		local directionToWaypoint = (waypoint.Position - rootPart.Position).Unit
		local dotProduct = directionToWaypoint:Dot(lookDirection)

		-- Solo incluir waypoints que estén adelante (hacia donde mira ahora)
		if dotProduct > -0.5 or i == #waypoints then
			table.insert(filteredWaypoints, waypoint)
		end
	end

	-- Si eliminamos todo, usar los waypoints originales
	if #filteredWaypoints == 0 then
		filteredWaypoints = waypoints
	end

	waypoints = filteredWaypoints

	-- ¡VISUALIZAR LOS WAYPOINTS!
	visualizeWaypoints(waypoints)

	-- Si se especificó un tiempo, calcular velocidad necesaria
	if timeToReach and timeToReach > 0 then
		local totalDistance = calculatePathDistance(waypoints)
		local requiredSpeed = totalDistance / timeToReach

		requiredSpeed = math.clamp(requiredSpeed, 1, 100)
		humanoid.WalkSpeed = requiredSpeed

		print(string.format("Distancia: %.2f studs | Tiempo: %.2fs | Velocidad: %.2f", 
			totalDistance, timeToReach, requiredSpeed))
	end

	-- Variable para detectar si el camino fue bloqueado
	local pathBlocked = false

	-- Detectar bloqueos del camino
	local blockedConnection
	blockedConnection = path.Blocked:Connect(function(blockedWaypointIndex)
		pathBlocked = true
		print("Camino bloqueado en waypoint " .. blockedWaypointIndex)
	end)

	-- Recorrer cada waypoint
	for i, waypoint in ipairs(waypoints) do
		if pathBlocked then
			blockedConnection:Disconnect()
			humanoid.WalkSpeed = originalSpeed
			return PathfindingModule.MoveTo(character, destination, timeToReach)
		end

		if waypoint.Action == Enum.PathWaypointAction.Jump then
			humanoid.Jump = true
		end

		local currentPos = rootPart.Position
		local targetPos = waypoint.Position
		local lookAtPos = Vector3.new(targetPos.X, currentPos.Y, targetPos.Z)

		if (lookAtPos - currentPos).Magnitude > 0.1 then
			rootPart.CFrame = CFrame.lookAt(currentPos, lookAtPos)
		end

		humanoid:MoveTo(waypoint.Position)

		local timeout = 8
		local moveFinished = false

		local finishedConnection
		finishedConnection = humanoid.MoveToFinished:Connect(function(reached)
			moveFinished = true
			finishedConnection:Disconnect()
		end)

		local startTime = tick()
		while not moveFinished and (tick() - startTime) < timeout do
			task.wait(0.1)
		end

		if not moveFinished then
			finishedConnection:Disconnect()
			warn("Timeout en waypoint " .. i)
		end
	end

	humanoid.WalkSpeed = originalSpeed
	blockedConnection:Disconnect()

	if finalCFrame then
		local currentPosition = rootPart.Position
		local targetPosition = finalCFrame.Position
		local lookAtPos = Vector3.new(targetPosition.X, currentPosition.Y, targetPosition.Z)

		if (lookAtPos - currentPosition).Magnitude > 0.1 then
			rootPart.CFrame = CFrame.lookAt(currentPosition, lookAtPos)
			print("Orientación final aplicada - mirando hacia el bloque")
		end
	end

	print("¡Llegó al destino!")
	return true, "Éxito"
end

-- Función para cambiar configuración de visualización
function PathfindingModule.SetVisualization(enabled, config)
	VISUAL_CONFIG.ShowWaypoints = enabled

	if config then
		for key, value in pairs(config) do
			if VISUAL_CONFIG[key] ~= nil then
				VISUAL_CONFIG[key] = value
			end
		end
	end
end

return PathfindingModule
 
