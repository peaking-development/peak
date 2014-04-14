--[=====[Peak Threading by CoderPuppy]=====]
-- Threads and scheduler

local processes = require('./processes')
local utils     = require('peak-utils')
local users     = require('peak-users')

local current

--[[thread = {
	paused        = whether this thread is paused;
	running       = whether this thread is currently running, -- Not really necessary;
	alive         = whether this thread hasn't exited
	eventQueue    = all the events that are queued for this thread in the form { ev, unpack(args) };
	process       = the process this thread is associated with;
	env           = environment variables;
	files         = file descriptors;
	queue(...)    = queue an event;
	queueNOW(...) = queue an event for the next run;
	interupt(...) = queue and run an event;
	run(iters: 1) = run a specific number of events;
	fs            = {
		root    = root of the filesystem as seen by this thread;
		current = current directory of this thread;
	};
	-- Everything in info is optional
	info          = {
		file = the file that is running in this thread;
		args = the initial arguments;
	};
}]]

-- Totally unique, though it doesn't serialize
exports.type    = {'THREAD'}
exports.type[2] = exports.type

-- threads.newBase(process)
-- Create a new thread that doesn't have run function
-- IMPLEMENT IT!
function exports.newBase(process)
	local self = utils.eventEmitter({
		type       = exports.type;
		alive      = false;
		paused     = true;
		running    = false;
		eventQueue = {};
		file       = {};
		info       = {};
		process    = process;
		env        = {};
		fs         = {};
	})

	function self:queue(...)
		local args = {...}
		-- if #args < 1 then print('Warning: Queuing an event with no arguments, this could cause problems', 2) end
		self.eventQueue[#self.eventQueue + 1] = args
		return #self.eventQueue
	end

	function self:queueNOW(...)
		local args = {...}
		if #args < 1 then error('Attempt to queueNOW an event with no arguments', 2) end
		table.insert(self.eventQueue, 1, args)
		return 1
	end

	function self:clearQueue()
		self.eventQueue = {}
	end

	function self:interupt(...)
		local ok, iters = pcall(self.queue, self, ...)
		if not ok then error(iters, 2) end
		local ok, rtn = pcall(self.run, self, iters)
		if not ok then error(rtn, 2) end
		return rtn
	end

	table.insert(process.threads, self)

	return self
end

-- threads.new(process, [fn, ...])
-- Creates a new thread in process, optionally running fn(...)
function exports.new(process, fn, ...)
	local self = exports.newBase(process)

	local function runCoroutine(...)
		local prev = current
		current = self
		local rtn = exports.runInThread(self, coroutine.resume, self.coroutine, ...)
		current = prev

		if utils.isPromise(rtn) then
			self.promise = rtn
		end
	end

	-- Maybe this should return how many iterations it got through
	function self:run(iters)
		if type(iters) ~= 'number' then iters = 1 end

		if type(self.coroutine) ~= 'thread' then return false end

		if self.promise ~= nil and self.promise.done then
			runCoroutine(unpack(self.promise.result))
			self.promise = nil
		end

		for i = 1, iters do
			if #self.eventQueue == 0 then return false end
			if self.promise ~= nil then break end
			runCoroutine(unpack(table.remove(self.eventQueue)))
		end
	end

	if type(fn) == 'function' then
		exports.exec(self, fn, ...)
	end

	return self
end

-- threads.exec(thread, fn, ...)
-- Replace what's running in thread with fn(...)
function exports.exec(thread, fn, ...)
	-- TODO: Permissions
	thread:clearQueue()
	thread:queue(...)
	thread.coroutine = coroutine.create(fn)
	thread.alive = true
end

-- threads.clone(parent: thread, opts, fn: function, ...)
-- clones the parent thread
--[[opts = {
	process   = default: share, new: creates a new process, share: just associates with the existing process;
	namespace = only relevant with process = new, default: share, new: create a new namespace, share: use the existing namespace;
	args      = default: new, clone: clone the argument list (doesn't clone each argument), share: keep the same argument list, new: create a new argument list;
	files     = default: new, share: share the file descriptor table (and all file descriptors in it), new: create a new table;
	fs        = default: clone, clone: copy the fs info over, share: use the same fs info (means that chdir will affect them both);
	env       = default: clone, clone: copy the environment over, share: use the same environment;
}]]
function exports.clone(parent, opts, fn, ...)
	-- TODO: Permissions
	if type(opts) ~= 'table' then error('opts is not a table', 2) end

	local pproc = parent.process

	local process = pproc -- if opts.process = 'share'

	if opts.process == 'new' then
		local namespace = process.namespace -- if opts.namespace == 'share'

		if opts.namespace == 'new' then
			namespace = namespace:registerChild(processes.namespace())
		end

		process = namespace:new(pproc, pproc.title, unpack((function(opt)
			if opt == 'clone' then
				return utils.cloneArr(pproc.args)
			elseif opt == 'share' then
				return pproc.args
			else -- if opt == 'new' then
				return {}
			end
		end)(opts.args)))
	end

	local thread = exports.new(process, fn, ...)

	if opts.files == 'share' then
		thread.files = parent.files
	-- elseif opts.file == 'new' then thread.files = {}
	end

	if opts.fs == 'share' then
		thread.fs = parent.fs
	else -- if opts.fs == 'clone' then
		-- local fs  = parent.fs
		-- thread.fs = {
		-- 	current = fs.current;
		-- 	root    = fs.root;
		-- }
	end

	if opts.env == 'share' then
		thread.env = parent.env
	elseif opts.env == 'clone' then
		thread.env = utils.cloneDict(parent.env)
	end

	process:emit('newThread', thread)

	return thread
end

-- threads.scheduler()
-- WIP
function exports.scheduler()
	local self = utils.eventEmitter({ threads = {} })

	function self:run(iters)
		if type(iters) ~= 'number' then iters = 1 end

		for i = 1, iters do
			for thread in pairs(self.threads) do
				if thread.alive and not thread.paused then
					thread:run()
				end
			end
		end
	end

	function self:queue(...)
		for thread in pairs(self.threads) do
			thread:queue(...)
		end
	end

	function self:add(thread)
		self.threads[thread] = thread
		self:emit('add', thread)
	end

	function self:remove(thread)
		self:emit('remove', thread)
		self.threads[thread] = nil
	end

	return self
end

do
	local self = exports.newBase(processes.craftosProcess)

	function self:run(iters)
		if type(iters) ~= 'number' then iters = 1 end

		for i = 1, iters do
			if #self.eventQueue == 0 then break end
			local ev = table.remove(self.eventQueue)
			os.queueEvent(unpack(ev))
		end

		return true
	end

	processes.craftosProcess:emit('newThread', self)

	exports.craftosThread = self
end

function exports.current() return current or exports.craftosThread end

function exports.runInThread(thread, fn, ...)
	if type(fn) ~= 'function' then error('Not a function', 2) end
	local prev = current
	current = thread
	local rtn = fn(...)
	current = prev
	return rtn
end

function exports.isThread(thread)
	return type(thread) == 'table' and
	       thread.type  == exports.type
end