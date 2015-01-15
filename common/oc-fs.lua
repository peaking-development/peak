local Promise = require 'common/promise'

return function(fs)
	return function(path, op, ...)
		path = table.concat(path, '/')
		return (({
			stat = function()
				if fs.exists(path) then
					return Promise.resolved(true, {
						exists = true;
						type = fs.isDirectory(path) and 'dir' or 'file';
						size = fs.size(path);
					})
				else
					return Promise.resolved(false, 'NOEXI')
				end
			end;

			open = function(opts)
				local h = {
					type = 'file';
				}
				local rh
				if opts.mode == 'read' then
					rh = fs.open(path, 'r' .. (opts.binary and 'b' or ''))
				elseif opts.mode == 'write' then
					rh = fs.open(path, opts.preserve and 'a' or 'w')
				return Promise.resolved(true, h)
			end;
		})[op] or error('Unhandled filesystem operation: ' .. tostring(op)))(...)
	end
end