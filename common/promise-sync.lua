local Promise = require 'common/promise'
local lon = require 'common/lon'

local function sync(fn, ...)
	local args = table.pack(...)
	local stack = debug.traceback()
	local co = coroutine.create(function()
		local ok, res = xpcall(fn, function(err)
			-- print(err)
			print(lon.to(err))
			print(debug.traceback())
			print(stack)
			print(' - ')
			-- if type(err) == 'string' then
			-- 	return err .. '\n' .. debug.traceback()
			-- elseif type(err) == 'table' and type(err[1]) == 'string' then
			-- 	return err[1] .. '\n' .. lon.to({table.unpack(err, 2)}) .. '\n' .. debug.traceback()
			-- else
				return err
			-- end
		end, table.unpack(args, 1, args.n))
		if ok then
			return res
		else
			error(res)
		end
	end)
	local promise, resolve = Promise.pending()

	local function run(...)
		local res = table.pack(coroutine.resume(co, ...))
		local ok = table.remove(res, 1)
		if ok then
			if coroutine.status(co) == 'dead' then
				resolve(true, table.unpack(res))
			else
				res[1](function(ok, ...)
					run(ok, ...)
				end)
			end
		else
			-- print'sync error'
			-- print(lon.to(res))
			resolve(false, type(res[1]) == 'table' and table.unpack(res[1]) or res[1])
		end
	end
	run(...)

	return promise
end

local function wait(prom)
	if not Promise.is(prom) then
		print(debug.traceback())
	end
	local res = table.pack(coroutine.yield(prom))
	if res[1] then
		return table.unpack(res, 2, res.n)
	else
		-- print'wait error'
		-- print(lon.to(res))
		-- print(debug.traceback())
		error({table.unpack(res, 2)})
	end
end

return setmetatable({
	wait = wait;
}, { __call = function(self, ...) return sync(...) end; })
