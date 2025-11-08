export type Mode = "max" | "min"
export type Entry<T> = {
	priority: number,
	value: T,
	order: number, -- tie-breaker: smaller means older
}

export type PriorityQueue<T> = {
	-- Core API
	push: (self: PriorityQueue<T>, value: T, priority: number) -> (),
	pop: (self: PriorityQueue<T>) -> T?,
	peek: (self: PriorityQueue<T>) -> T?,
	size: (self: PriorityQueue<T>) -> number,
	isEmpty: (self: PriorityQueue<T>) -> boolean,
	clear: (self: PriorityQueue<T>) -> (),
	-- Debug helpers
	toArray: (self: PriorityQueue<T>) -> {Entry<T>},

	-- internal fields (opaque to users)
	_mode: Mode,
	_heap: {Entry<T>},
	_counter: number,
}

local PriorityQueue = {}
PriorityQueue.__index = PriorityQueue

local function defaultMode(mode: Mode?): Mode
	if mode == "min" then
		return "min"
	end
	return "max"
end

local function compare<T>(mode: Mode, a: Entry<T>, b: Entry<T>): boolean
	if a.priority == b.priority then
		return a.order < b.order
	end
	if mode == "max" then
		return a.priority > b.priority
	else
		return a.priority < b.priority
	end
end

local function swap<T>(heap: {Entry<T>}, i: number, j: number)
	heap[i], heap[j] = heap[j], heap[i]
end

local function siftUp<T>(self: PriorityQueue<T>, idx: number)
	local heap = self._heap
	while idx > 1 do
		local parent = idx // 2
		if compare(self._mode, heap[parent], heap[idx]) then
			break
		end
		swap(heap, parent, idx)
		idx = parent
	end
end

local function siftDown<T>(self: PriorityQueue<T>, idx: number)
	local heap = self._heap
	local n = #heap
	while true do
		local left = idx * 2
		local right = left + 1
		local best = idx

		if left <= n and not compare(self._mode, heap[best], heap[left]) then
			best = left
		end
		if right <= n and not compare(self._mode, heap[best], heap[right]) then
			best = right
		end
		if best == idx then
			break
		end
		swap(heap, idx, best)
		idx = best
	end
end

function PriorityQueue.new<T>(config: { mode: Mode }?): PriorityQueue<T>
	local mode = defaultMode(config and config.mode)
	local self: PriorityQueue<T> = setmetatable({
		_mode = mode,
		_heap = {},
		_counter = 0,
	}, PriorityQueue)
	return self
end

function PriorityQueue:push<T>(value: T, priority: number)
	--assert(typeof(priority) == "number", "priority must be a number")
	self._counter += 1
	local entry: Entry<T> = { value = value, priority = priority, order = self._counter }
	table.insert(self._heap, entry)
	siftUp(self, #self._heap)
end

function PriorityQueue:pop<T>(): T?
	local heap = self._heap
	local n = #heap
	if n == 0 then return nil end
	local top = heap[1]
	heap[1] = heap[n]
	heap[n] = nil :: any
	if n > 1 then
		siftDown(self, 1)
	end
	return top.value
end

function PriorityQueue:peek<T>(): T?
	local heap = self._heap
	if #heap == 0 then return nil end
	return heap[1].value
end

function PriorityQueue:size(): number
	return #self._heap
end

function PriorityQueue:isEmpty(): boolean
	return #self._heap == 0
end

function PriorityQueue:clear()
	table.clear(self._heap)
end

function PriorityQueue:toArray<T>(): {Entry<T>}
	local out: {Entry<T>} = {}
	for i = 1, #self._heap do
		out[i] = self._heap[i]
	end
	return out
end

return PriorityQueue
 
