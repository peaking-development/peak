local Promise = require 'common/promise'
local FS = require 'common/fs'
local buffer = require 'buffer'
local E = require 'common/error'

return function(fs)
	return FS(function(path, op, ...)
		path = table.concat(path, '/')
		return (({
			stat = function()
				if fs.exists(path) then
					local stat = {
						exists = true;
						type = fs.isDirectory(path) and 'folder' or 'file';
					}
					if stat.type == 'file' then stat.size = fs.size(path) end
					return Promise.resolved(true, stat)
				else
					return Promise.resolved(true, { exists = false; })
				end
			end;

			open = function(opts)
				local h = {}

				if opts.type == 'file' then
					local rh
					if opts.mode == 'read' then
						local mode = 'r' .. (opts.binary and 'b' or '')
						rh = buffer.new(mode, fs.open(path, mode))

						function h.read(len)
							if len == math.huge then len = '*a' end
							if len == nil then len = '*L' end
							if len == 'line' then len = '*l' end
							return Promise.resolved(true, rh:read(len))
						end

						function h.seek(whence, offset)
							rh:seek(whence, offset)
						end
					elseif opts.mode == 'write' then
						rh = fs.open(path, opts.preserve and 'a' or 'w')

						function h.write(data)
							rh:write(data)
							return Promise.resolved(true)
						end
					end

					function h.close()
						rh:close()
						return Promise.resolved(true)
					end
				elseif opts.type == 'folder' then
					local list = fs.list(path)
					function h.read()
						return Promise.resolved(true, list())
					end

					function h.close()
						list = nil
						return Promise.resolved(true)
					end
				end
					
				return Promise.resolved(true, h)
			end;

			create = function(opts)
				local h = fs.open(path, 'w')
				h:close()
				return Promise.resolved(true)
			end;
		})[op] or error('Unhandled filesystem operation: ' .. tostring(op)))(...)
	end)
end
