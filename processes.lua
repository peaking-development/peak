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
		}
		self[opts.pid] = proc
		local handle = kernel.fs.get(proc.path).open('r')
		local ok, err = load(handle.read, fn(proc.path, fn.arr.join('/')))
		handle.close()
	end

	return self
end