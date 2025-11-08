 
export type Client = {
	priority: number,
	name: string,
	char: any?, -- Character/modelo del jugador 
	tag: any?,

	-- Métodos
	getPriority: (self: Client) -> number,
	getName: (self: Client) -> string,
	toString: (self: Client) -> string,

	-- Metamétodos internos
	__lt: (self: Client, other: Client) -> boolean,
	__le: (self: Client, other: Client) -> boolean,
}

local Client = {}
Client.__index = Client

 function Client:__lt(other: Client): boolean
	return self.priority < other.priority
end

 function Client:__le(other: Client): boolean
	return self.priority <= other.priority
end

 function Client.new(name: string, priority: number?): Client
	local self = setmetatable({
		priority = priority or 1,  
		name = name,
		char = nil,  
		tag = nil,
	}, Client)

	return self :: any
end

-- Obtener prioridad
function Client:getPriority(): number
	return self.priority
end

-- Obtener nombre
function Client:getName(): string
	return self.name
end

-- Representación en texto
function Client:toString(): string
	return string.format("Client(%s, priority=%d)", self.name, self.priority)
end

return Client
 
