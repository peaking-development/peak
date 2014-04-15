local utils = exports

local threads

function utils.eventEmitter(t, debug)
	local events = {}
	local lastEvent

	local function callHandler(handler, ...)
		if type(handler) ~= 'table' or type(handler[2]) ~= 'function' then error('Bad handler', 2) end
		if threads.isThread(handler[1]) then
			threads.runInThread(handler[1], handler[2], ...)
		else
			if handler[1] ~= nil then
				error('Bad handler: It\'s not a thread but it\'s not nil', 2)
			end

			handler[2](...)
		end
	end

	function t:emit(ev, ...)
		if utils.tableEqual(lastEvent, { ev, ... }) then return t end

		lastEvent = { ev, ... }

		if type(events[ev]) == 'table' then
			local handlers = events[ev]
			for i, handler in ipairs(handlers) do
				callHandler(handler, ...)
			end
		elseif debug then
			print('Unhandled event: ' .. ev)
		end

		return t
	end

	function t:on(ev, handler)
		if threads.isThread(handler) then
			local thread = handler
			handler = function(...)
				thread:queue(ev, ...)
			end
		end

		if type(handler) ~= 'function' then error('Attempt to register non-function as event handler', 2) end

		handler = {threads.current(), handler}

		self:emit('newListener', ev, function(...)
			callHandler(handler, ...)
		end)

		local handlers = events[ev]
		if handlers == nil then
			handlers = {}
			events[ev] = handlers
		end

		handlers[#handlers + 1] = handler

		return t
	end

	return t
end

function utils.cloneArr(arr)
	if type(arr) ~= 'table' then error('Attempt to cloneArr a non-table: ' .. type(dict), 2) end
	local new = {}

	for i = 1, #arr do
		new[i] = arr[i]
	end

	return new
end

function utils.cloneDict(dict)
	if type(dict) ~= 'table' then error('Attempt to cloneDict a non-table: ' .. type(dict), 2) end
	local new = {}

	for k, v in pairs(dict) do
		new[k] = v
	end

	return new
end

function utils.tableEqual(a, b)
	if type(a) ~= 'table' or type(b) ~= 'table' then return false end
	for k, v in pairs(a) do
		if b[k] ~= v then return false end
	end

	for k, v in pairs(b) do
		if a[k] ~= v then return false end
	end

	return true
end

function utils.filterProp(arg, name, val)
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

function utils.reerror(err, level)
	error(err:gsub('^pcall: ', ''), level == 0 and 0 or level + 1)
end

function utils.reerrorCall(level, fn, ...)
	local ok, rtn = pcall(fn, ...)

	if not ok then
		utils.reerror(rtn, level == 0 and 0 or level + 1)
	end

	return rtn
end

function utils.curry(fn, ...)
	local args = {...}

	return function(...)
		return fn(unpack(args), ...)
	end
end

function utils.split(str, splitter, pattern)
	local found = true
	local last = 0
	local parts = {}

	-- print(str)

	while found do
		local match = {str:find(splitter, last, not pattern)}

		-- print(table.concat(match, ', '))

		if #match > 0 then
			parts[#parts + 1] = str:sub(last, match[1] - 1)
			last = match[1] + 1
		else
			found = false
		end
	end

	parts[#parts + 1] = str:sub(last)

	-- print(textutils.serialize(parts))

	return parts
end

function utils.slice(t, from, to)
	local res = {}

	for i = from, to do
		res[#res + 1] = t[i]
	end

	return res
end

threads = require('peak-tasks/threads')