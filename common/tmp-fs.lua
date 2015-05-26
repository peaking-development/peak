local FS = require 'common/fs'
local E = require 'common/error'
local Promise = require 'common/promise'

return function()
	local data = {
		[''] = {
			type = 'folder';
		}
	}
	return FS(function(path, op, ...)
		local pd = data[FS.serialize_path(path)]
		return (({
			stat = function()
				if pd then
					return Promise.resolved(true, {
						exists = true;
						type = pd.type;
					})
				else
					return Promise.resolved(true, { exists = false; })
				end
			end;
		})[op] or error('unhandled operation: ' .. tostring(op)))(...)
	end)
end
