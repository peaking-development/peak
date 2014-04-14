local utils = exports

local threads

function utils.eventEmitter(t, debug)
	local events = {}
	local queues = {}
	local lastEvent

	function t:emit(ev, ...)
		if utils.tableEqual(lastEvent, { ev, ... }) then return t end

		lastEvent = { ev, ... }

		if type(events[ev]) == 'table' then
			local handlers = events[ev]
			if #handlers == 2 and type(handlers[2]) == 'function' then
				handlers:queue(ev, ...)
			else
				for i, handler in ipairs(handlers) do
					handler:queue(ev, ...)
				end
			end
		elseif debug then
			print('Unhandled event: ' .. ev)
		end

		return t
	end

	function t:on(ev, thread)
		if not threads.isThread(thread) then
			error('Attempt to register non-thread as handler', 2)
		end

		self:emit('newListener', ev, thread)

		local handlers = events[ev]
		if handlers == nil then
			events[ev] = thread
		elseif type(handlers) == 'table' then
			if type(handlers[2] == 'function') then
				events[ev] = {handlers, thread}
			else
				handlers[#handlers + 1] = thread
			end
		else
			print('what is going on here? ', type(handlers))
			print('someone messed with the events table')
		end

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