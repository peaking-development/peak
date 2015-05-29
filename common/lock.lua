local Promise = require 'common/promise'

return function()
	local locked = false
	local queue = {}
	local give, unlock
	function give(resolve)
		locked = true
		resolve(true, function()
			unlock()
		end)
	end
	function unlock()
		locked = false
		if #queue > 0 then
			give(table.remove(queue, 1))
		end
	end
	return function()
		local prom, resolve = Promise.pending()
		if locked then
			queue[#queue + 1] = resolve
		else
			give(resolve)
		end
		return prom
	end
end
