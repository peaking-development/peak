local fn = require('./fn')
fn.arr = require('./fn/arr')

return function(opts)
	opts = type(opts) == 'table' and opts or {}
	opts.mounts = type(opts.mounts) == 'table' and opts.mounts or {}
	opts.initPath = type(opts.initPath) == 'table' and #opts.initPath >= 1 and opts.initPath or {'init'}

	local self = {}

	self.fs = require('./mountfs')()(self)
	self.mount = self.fs.mount
	self.unmount = self.fs.unmount

	self.processes = require('./processes')(self)
	self.spawnProcess = self.processes.spawn

	for _, mount in ipairs(opts.mounts) do
		self.mount(mount[1], mount[2](self))
	end
	
	self.spawnProcess{
		pid = 1;
		path = opts.initPath;
		args = {};
	}
	return self
end