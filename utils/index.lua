local threads = require('peak-tasks/threads')

function exports.eventEmitter(t, debug)
	local events = {}
	local queues = {}
	local lastEvent

	function t.emit(ev, ...)
		if exports.tableEqual(lastEvent, { ev, ... }) then return t end
		
		lastEvent = { ev, ... }

		if type(events[ev]) == 'function' then
			events[ev](...)
		elseif type(events[ev]) == 'table' then
			local handlers = events[ev]
			for i = 1, #handlers do
				handlers[i](...)
			end
		elseif debug then
			print('Unhandled event: ' .. ev)
		end

		for i = 1, #queues do
			queues[i](ev, ...)
		end

		return t
	end

	function t.on(ev, handler)
		if type(handler) ~= 'function' then error('Attempt to register non-function as interupt handler', 2) end

		local handlers = events[ev]
		if handlers == nil then
			events[ev] = {handler}
			return 1
		elseif type(handlers) == 'table' then
			handlers[#handlers + 1] = handler
			return #handlers
		elseif type(handlers) == 'function' then
			events[ev] = {handlers, handler}
			return 2
		else
			print('what is going on here? ', type(handlers))
			print('someone messed with the events table')
		end

		return t
	end

	function t.registerQueue(queue)
		if type(queue) ~= 'function' then error('Attempt to register non-function as queue', 2) end
		queues[#queues + 1] = queue
		return t
	end

	return t
end

function exports.cloneArr(arr)
	if type(arr) ~= 'table' then error('Attempt to cloneArr a non-table: ' .. type(dict), 2) end
	local new = {}

	for i = 1, #arr do
		new[i] = arr[i]
	end

	return new
end

function exports.cloneDict(dict)
	if type(dict) ~= 'table' then error('Attempt to cloneDict a non-table: ' .. type(dict), 2) end
	local new = {}

	for k, v in pairs(dict) do
		new[k] = v
	end

	return new
end

function exports.tableEqual(a, b)
	if type(a) ~= 'table' or type(b) ~= 'table' then return false end
	for k, v in pairs(a) do
		if b[k] ~= v then return false end
	end

	for k, v in pairs(b) do
		if a[k] ~= v then return false end
	end

	return true
end

function exports.filterProp(arg, name, val)
	if arg:sub(1, #name + 1) == name .. '=' then if arg:sub(#name + 2) ~= val then
		return false
	end elseif arg:sub(1, #name + 1) == name .. '!' then if arg:sub(#name + 2) == val then
		return false
	end elseif arg:sub(1, #name + 2) == name .. '~=' then if not val:find(arg:sub(#name + 3)) then
		return false
	end elseif arg:sub(1, #name + 2) == name .. '~!' then if val:find(arg:sub(#name + 3)) then
		return false
	end end

	return true
end