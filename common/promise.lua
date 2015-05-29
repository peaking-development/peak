local lon = require 'common/lon'

local function isCallable(v)
	if type(v) == 'function' then return true end
	if type(v) ~= 'table' then return false end
	local mt = getmetatable(v)
	return mt and isCallable(mt.__call)
end

local Promise; Promise = setmetatable({}, {__call = function(self, first, ...)
	local filters = {...}

	if not isCallable(first) then error('first isn\'t callable') end
	for _, filter in ipairs(filters) do
		if not isCallable(filter) then
			error('filter #' .. tostring(_) .. ' isn\'t callable')
		end
	end

	local start

	if #filters == 0 then
		function start(first)
			return first
		end
	else
		function start(promise)
			for _, filter in ipairs(filters) do
				promise = filter(promise)
			end
			return promise
		end
	end

	if Promise.is(first) then
		return start(first)
	else
		return function(input)
			return start(first(input))
		end
	end
end})

function Promise.is(promise)
	return type(promise) == 'table' and isCallable(promise) and type(promise.resolved) == 'boolean'
end

function Promise.pending(mapper)
	local promise = {
		type = 'promise';

		resolved = false;
	}

	local handlers = {}

	setmetatable(promise, {__call = function(self, mapper)
		local promise, resolve = Promise.pending()
		if not isCallable(mapper) then error('Invalid mapper') end
		local function handler(ok, ...)
			--local ok, res = pcall(mapper, ok, ...)
			local res = mapper(ok, ...)
			--if ok then
				if res then
					res(resolve)
				else
					resolve(false)
				end
			--else
			--	fn.reerror(res, 2, 'promise#() handler')
			--end
		end
		if self.resolved then
			handler(self.ok, table.unpack(self.res))
		else
			handlers[#handlers + 1] = handler
		end
		return promise
	end})

	local function resolve(ok, ...)
		if promise.resolved then
			error('Already resolved', 2)
		end
		promise.resolved = true
		promise.ok = ok
		promise.res = {...}
		for i, handler in ipairs(handlers) do
			handler(ok, ...)
		end
		promise.handlers = nil
	end

	if type(mapper) == 'function' then
		mapper(resolve)
	end

	return promise, resolve
end

function Promise.resolved(ok, ...)
	if not ok then
		print(lon.to({...}))
		print(debug.traceback())
		error('', 0)
	end
	local promise, resolve = Promise.pending()
	resolve(ok, ...)
	return promise
end

function Promise.allResolved(...)
	local promise, resolve = Promise.pending()
	local resolved = 0
	local results = {}
	local promises = {...}
	for i, promise in ipairs(promises) do
		promise(function(ok, ...)
			resolved = resolved + 1
			results[i] = {ok, ...}
			if resolved >= #promises then
				resolve(true, table.unpack(results))
			end
		end)
	end
	return promise
end

-- Like allResolved but requires all to succeed
function Promise.all(...)
	return Promise(
		Promise.allResolved(...),
		Promise.flatMap(function(...)
			local errored = false
			local results = {}
			for i, result in ipairs({...}) do
				local res = {table.unpack(result)}
				local ok = table.remove(res, 1)
				if ok then
					if not errored then
						results[i] = res
					end
				else
					if not errored then
						errored = true
						results = {}
					end
					results[#results + 1] = res[1]
				end
			end
			return Promise.resolved(not errored, table.unpack(results))
		end)
	)
end

function Promise.firstResolved(...)
	local promise, resolve = Promise.pending()
	for i, promise in ipairs({...}) do
		promise(function(ok, ...)
			if not promise.resolved then
				resolve(true, i, ok, ...)
			end
		end)
	end
	return promise
end

function Promise.first(...)
	local promise, resolve = Promise.pending()
	for i, promise in ipairs({...}) do
		promise(function(ok, ...)
			if ok then
				resolve(true, i, ...)
			end
		end)
	end
	return promise
end

function Promise.anyResolved(...)
	return Promise(
		Promise.firstResolved(...),
		Promise.map(function(i, ok, ...)
			return ok, ...
		end)
	)
end

function Promise.any(...)
	return Promise(
		Promise.first(...),
		Promise.map(function(i, ...)
			return ...
		end)
	)
end

function Promise.flatMap(mapper, from)
	return function(promise)
		return promise(function(ok, ...)
			if ok then
				return mapper(...)
			else
				return Promise.resolved(false, ...)
			end
		end)
	end
end

function Promise.map(mapper)
	return Promise.flatMap(function(...)
		--return Promise.resolved(pcall(mapper, ...))
		return Promise.resolved(true, mapper(...))
	end)
end

function Promise.flatCatch(mapper)
	return function(promise)
		return promise(function(ok, ...)
			if ok then
				return Promise.resolved(true, ...)
			else
				return mapper(...)
			end
		end)
	end
end

function Promise.catch(mapper)
	return Promise.flatCatch(function(...)
		--return Promise.resolved(pcall(mapper, ...))
		return Promise.resolved(true, mapper(...))
	end)
end

function Promise.orError()
	return Promise.flatCatch(function(err, ...)
		print(lon.to({err, ...}))
		print(debug.traceback())
		error(err, 0)
	end)
end

return Promise
