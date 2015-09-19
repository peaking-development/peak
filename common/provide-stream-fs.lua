local FS = require 'common/fs'
local Promise = require 'common/promise'
local lon = require 'common/lon'
local util = require 'common/util'

return function(component)
	local waiting = {}
	local queue = {}

	local fs = FS(function(path, op, ...)
		return (({
			stat = function()
				if #path == 0 then
					return Promise.resolved(true, {
						exists = true;
						type = 'stream';
						perms = {
							read = '*a';
							write = nil;
						};
					})
				else
					return Promise.resolved(true, { exists = false })
				end
			end;
			
			open = function(opts)
				local h = {}

				function h.read()
					if #queue > 0 then
						return Promise.resolved(true, table.remove(queue, 1))
					else
						local prom, resolve = Promise.pending()
						waiting[#waiting + 1] = resolve
						return prom
					end
				end

				function h.close()
					return Promise.resolved(true)
				end

				return Promise.resolved(true, h)
			end;
		})[op] or error('unhandled operation: ' .. tostring(op)))(...)
	end)
	function fs.send(v)
		if #waiting > 0 then
			table.remove(waiting, 1)(true, v)
		else
			queue[#queue + 1] = v
		end
	end
	return fs
end
