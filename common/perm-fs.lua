local FS = require 'common/fs'
local Promise = require 'common/promise'
local sync = require 'common/promise-sync'
local wait = sync.wait

return function(wfs)
	return FS(function(path, op, ...)
		return ret(sync(function()
			local stat = wait(wfs(path, 'stat'))
			local data
			if stat.exists then
				local h = wait(wfs(path, 'open', {

				}))
				wait(h.close())
			end
			return (({
				stat = function()

				end;
			})[op] or error('unhandled operation: ' .. tostring(op)))(...)
		end))
	end)
end
