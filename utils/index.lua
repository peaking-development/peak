local threads = require('peak-tasks/threads')

function exports.eventEmitter(t, debug)
	local events = {}
	local queues = {}
	local lastEvent
	
	local function callHandler(handler, ...)
		if type(handler[2]) ~= 'function' then error('Bad handler', 2) end
		if handler[1] == nil then
			handler[2](...)
		elseif threads.isThread(handler[1]) then
			threads.runInThread(unpack(handler), ...)
		else
			error('Bad handler', 2)
		end
	end

	function t.emit(ev, ...)
		if exports.tableEqual(lastEvent, { ev, ... }) then return t end

		lastEvent = { ev, ... }

		-- TODO: Make this optional
		if type(events[ev]) == 'table' then
			local handlers = events[ev]
			if #handlers == 2 and threads.isThread(handlers[1]) and type(handlers[2]) == 'function' then
				callHandler(handlers, ...)
			else
				for i = 1, #handlers do
					exports.reerrorCall(2, callHandler, handlers[i], ...)
				end
			end
		elseif debug then
			print('Unhandled event: ' .. ev)
		end

		-- if type(events[ev]) == 'function' then
		-- 	callHandler(events[ev], ...)
		-- elseif type(events[ev]) == 'table' then
		-- 	local handlers = events[ev]
		-- 	for i = 1, #handlers do
		-- 		callHandler(handlers[i], ...)
		-- 	end
		-- elseif debug then
		-- 	print('Unhandled event: ' .. ev)
		-- end

		for i = 1, #queues do
			queues[i](ev, ...)
		end

		return t
	end

	function t.on(ev, handler)
		if type(handler) ~= 'function' then error('Attempt to register non-function as interupt handler', 2) end

		-- TODO: Make this optional
		handler = {threads.current(), handler}

		t.emit('newListener', ev, function(...)
			return callHandler(handler, ...)
		end)

		local handlers = events[ev]
		if handlers == nil then
			events[ev] = handler
		elseif type(handlers) == 'table' then
			handlers[#handlers + 1] = handler
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

function exports.defer()
	local deferred = exports.eventEmitter({
		done = false
	})

	function deferred.resolve(...)
		if not deferred.done then
			deferred.done   = true
			deferred.ok     = true
			deferred.result = {...}

			deferred.emit('resolved', ...)
		end

		return deferred
	end

	function deferred.reject(...)
		if not deferred.done then
			deferred.done   = true
			deferred.ok     = false
			deferred.result = {...}

			deferred.emit('rejected', ...)
		end

		return deferred
	end

	function deferred.promise()
		local promise = exports.eventEmitter({})

		setmetatable(promise, {
			__index = function(t, k)
				if k     == 'done'   then return deferred.done
				elseif k == 'ok'     then return deferred.ok
				elseif k == 'result' then return deferred.result
				else
					return rawget(t, k)
				end
			end
		})

		deferred.on('resolved', function(...) promise.emit('resolved', ...) end)
		deferred.on('rejected', function(...) promise.emit('rejected', ...) end)

		promise.on('newListener', function(event, listener)
			if promise.done then
				if event == 'resolved' and promise.ok then
					listener(unpack(promise.result))
				elseif event == 'rejected' and not promise.ok then
					listener(unpack(promise.result))
				end
			end
		end)

		setmetatable(promise, {
			__call = function(t, callback, errback)
				if type(callback) == 'function' then
					promise.on('resolved', callback)
				end

				if type(errback) == 'function' then
					promise.on('rejected', errback)
				end
			end
		})

		return promise
	end

	deferred.on('newListener', function(event, listener)
		if deferred.done then
			if event == 'resolved' and deferred.ok then
				listener(unpack(deferred.result))
			elseif event == 'rejected' and not deferred.ok then
				listener(unpack(deferred.result))
			end
		end
	end)

	setmetatable(deferred, {
		__call = function(t, callback, errback)
			if type(callback) == 'function' then
				deferred.on('resolved', callback)
			end

			if type(errback) == 'function' then
				deferred.on('rejected', errback)
			end
		end
	})

	return deferred
end

function exports.isPromise(p)
	return type(p)      == 'table' and
	       type(p.on)   == 'function' and
	       type(p.done) == 'boolean'
end