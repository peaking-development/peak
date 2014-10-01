local fn = require('./fn')
fn.arr = require('./fn/arr')

return function(kernel)
	local self = {}

	self.kernel = kernel
	self.namespaces = {}

	function self.spawn(opts)
		if type(opts) ~= 'table' then error('opts are required (expected table, got ' .. textutils.serialize(opts) .. ')', 2) end
		opts.pid = type(opts.pid) == 'number' and opts.pid or self.genPID()
		opts.args = type(opts.args) == 'table' and opts.args or {}
		if type(opts.path) ~= 'table' then error('a path is required (expected table, got ' .. textutils.serialize(opts.path) .. ')', 2) end
		local proc = {
			namespace = namespace;
			pid = opts.pid;
			path = opts.path;
			args = opts.args;
			eventQueue = {};
			fds = {};
		}
		local inode = kernel.fs.get(proc.path)
		local handle = inode.open('r')
		local fn, err = loadstring(handle.read('*a'), fn(proc.path, fn.arr.join('/')))
		if fn then
			--setfenv(fn, {}) -- TODO: this is temporarily disabled
			proc.co = coroutine.create(fn)
			local ok, err = coroutine.resume(proc.co)
			if not ok then
				error(err, 2)
			end
		else
			error(err, 2)
		end
		handle.close()
		inode.release()
		self[opts.pid] = proc
		return proc
	end

	return self
end