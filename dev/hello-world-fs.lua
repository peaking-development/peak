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
					})
				else
					return Promise.resolved(true, {
						exists = true;
						type = 'file';
					})
				end
			end;
		})[op] or error('unhandled operation: ' .. tostring(op)))(...)
	end)
end
