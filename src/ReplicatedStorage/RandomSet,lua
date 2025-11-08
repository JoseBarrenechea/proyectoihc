-- Estructura de datos tipo Set con extracción aleatoria
local RandomSet = {}
RandomSet.__index = RandomSet

-- Constructor
function RandomSet.new()
	local self = setmetatable({}, RandomSet)
	self.values = {}       -- lista de valores
	self.indices = {}      -- mapa: valor -> índice en la lista
	return self
end

-- Inserta un número (solo si no existe)
function RandomSet:insert(value)
	if not self.indices[value] then
		table.insert(self.values, value)
		self.indices[value] = #self.values
	end
end

-- Elimina un número específico (si existe)
function RandomSet:remove(value)
	local index = self.indices[value]
	if not index then return end

	local lastValue = self.values[#self.values]
	self.values[index] = lastValue
	self.indices[lastValue] = index

	table.remove(self.values)
	self.indices[value] = nil
end

-- Devuelve y elimina un número aleatorio
function RandomSet:popRandom()
	if #self.values == 0 then return nil end

	local randomIndex = math.random(1, #self.values)
	local value = self.values[randomIndex]

	self:remove(value)
	return value
end

-- Devuelve los valores actuales
function RandomSet:getAll()
	return self.values
end

function RandomSet:isEmpty()
	return #self.values == 0
end

-- Ejemplo de uso:

return RandomSet

