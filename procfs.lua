local fn = require('./fn')
fn.arr = require('./fn/arr')

return function() return function(kernel)
	local function isProcPath(path)
		return #path == 1 and kernel.processes[tonumber(path[1])]
	end
	return function(path)
		local nothing = {
			path = path;
			exists = false;
		}
		if #path >= 1 and kernel.processes[tonumber(path[1])] then
			local proc = kernel.processes[tonumber(path[1])]
			if #path == 1 then
				return {
					path = path;
					type = 'dir';
					readonly = true;
					exists = true;
				}
			else
				return nothing
			end
		elseif #path == 0 then
			return {
				path = path;
				type = 'dir';
				readonly = false;
				exists = true;
			}
		else
			return nothing
		end
	end
end end