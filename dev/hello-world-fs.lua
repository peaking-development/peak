local FS = require 'common/fs'
local Promise = require 'common/promise'

return function()
	return FS(function(path, op, ...)
		return (({
			stat = function()
				if #path == 0 then
					return Promise.resolved(true, {
						exists = true;
						type = 'folder';
						perms = {
							read = '*a';
						};
					})
				else
					return Promise.resolved(true, {
						exists = true;
						type = 'file';
						perms = {
							read = '*a';
						};
					})
				end
			end;

			open = function(opts)
				if #path == 0 then
					return Promise.resolved(true, {
						read = function() return Promise.resolved(true, nil) end;
						close = function() return Promise.resolved(true) end;
					})
				else
					return Promise.resolved(true, FS.wrap_buffer(FS.wrap_stream(function()
						return Promise.resolved(true, 'hello world\n')
					end)))
				end
			end;
		})[op] or error('unhandled operation: ' .. tostring(op)))(...)
	end)
end
