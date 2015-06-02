local FS = require 'common/fs'
local Promise = require 'common/promise'

return function(fs, path)
	local api_prom = fs(path, 'open', {
		type = 'api';
		execute = true;
	})
	return FS(function(path, op, ...) local args = table.pack(...); return Promise(api_prom, Promise.flat_map(function(api)
		if op == 'open' then
			local opts = args[1]
			return Promise(
				api.call(op, path, opts),
				Promise.map(function(id)
					local h = {}

					local function gen(name)
						h[name] = function(...)
							return api.call(name, id, ...)
						end
					end

					gen'close'

					if opts.type == 'file' then
						gen'read'
						gen'seek'
						if opts.write then
							gen'write'
							gen'flush'
						end
					elseif opts.type == 'folder' then
						gen'read'
					elseif opts.type == 'api' then
						gen'list'
						if opts.execute then
							gen'call'
						end
						if opts.provide then
							gen'provide'
							gen'unprovide'
							gen'read'
							gen'respond'
						end
					else
						error('unhandled type: ' .. tostring(opts.type))
					end

					return h
				end)
			)
		else
			return api.call(op, path, table.unpack(args, 1, args.n))
		end
	end)) end)
end
