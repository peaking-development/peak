--[=====[Peak Threading by CoderPuppy]=====]
-- Threads and scheduler
-- This might have to be specific to peak
-- Mainly the processes have their own threads

local processes = require('./processes')
local utils     = require('./utils')
local users     = require('./users')

local current

--[[thread = {
	paused        = whether this thread is paused,
	running       = whether this thread is currently running, -- Not really necessary
	alive         = 
	eventQueue    = all the events that are queued for this thread in the form { ev, unpack(args) },
	process       = the process this thread is associated with,
	env           = environment variables,
	files         = file descriptors,
	queue(...)    = queue an event,
	queueNOW(...) = queue an event for the next run,
	interupt(...) = queue and run an event,
	run(iters: 1) = run a specific number of events,
	fs            = {
		root    = root of the filesystem as seen by this thread,
		current = current directory of this thread
	},
	-- Everything in info is optional
	info          = {
		file = the file that is running in this thread,
		args = the initial arguments
	}
}]]

-- Totally unique, though it doesn't serialize
exports.type    = {'THREAD'}
exports.type[2] = exports.type

-- threads.newBase(process)
-- Create a new process that doesn't have run function
-- IMPLEMENT IT!
function exports.newBase(process)
	local thread = utils.eventEmitter({
		type       = exports.type,
		alive      = false,
		paused     = true,
		running    = false,
		eventQueue = {},
		info       = {},
		process    = process,
		env        = {},
		fs         = {}
	})

	function thread.queue(...)
		local args = {...}
		-- if #args < 1 then print('Warning: Queuing an event with no arguments, this could cause problems', 2) end
		thread.eventQueue[#thread.eventQueue + 1] = args
		return #thread.eventQueue
	end

	function thread.queueNOW(...)
		local args = {...}
		if #args < 1 then error('Attempt to queueNOW an event with no arguments', 2) end
		table.insert(thread.eventQueue, 1, args)
		return 1
	end

	function thread.clearQueue()
		thread.eventQueue = {}
	end

	function thread.interupt(...)
		local ok, iters = pcall(thread.queue, ...)
		if not ok then error(iters, 2) end
		local ok, rtn = pcall(thread.run, iters)
		if not ok then error(rtn, 2) end
		return rtn
	end

	return thread
end

-- threads.new(process, [fn, ...])
-- Creates a new thread in process, optionally running fn(...)
function exports.new(process, fn, ...)
	local thread = exports.newBase(process)

	-- Maybe this should return how many iterations it got through
	function thread.run(iters)
		if type(iters) ~= 'number' then iters = 1 end

		if type(thread.coroutine) ~= 'thread' then return false end

		for i = 1, iters do
			if #thread.eventQueue == 0 then return false end
			local prev = current
			current = thread
			coroutine.resume(thread.coroutine, unpack(table.remove(thread.eventQueue)))
			current = prev
		end
	end

	if type(fn) == 'function' then
		exports.exec(thread, fn, ...)
	end

	return thread
end

-- threads.exec(thread, fn, ...)
-- Replace what's running in thread with fn(...)
function exports.exec(thread, fn, ...)
	-- TODO: Permissions
	thread.clearQueue()
	thread.queue(...)
	thread.coroutine = coroutine.create(fn)
	thread.alive = true
end

-- threads.clone(parent: thread, opts, fn: function, ...)
-- clones the parent thread
--[[opts = {
	process   = default: share, new: creates a new process, share: just associates with the existing process,
	namespace = only relevant with process = new, default: share, new: create a new namespace, share: use the existing namespace,
	args      = default: new, clone: clone the argument list (doesn't clone each argument), share: keep the same argument list, new: create a new argument list,
	files     = default: new, share: share the file descriptor table (and all file descriptors in it), new: create a new table,
	fs        = default: clone, clone: copy the fs info over, share: use the same fs info (means that chdir will affect them both),
	env       = default: clone, clone: copy the environment over, share: use the same environment
}]]
function exports.clone(parent, opts, fn, ...)
	-- TODO: Permissions
	if type(opts) ~= 'table' then error('opts is not a table', 2) end

	local pproc = parent.process

	local process = pproc -- if opts.process = 'share'

	if opts.process == 'new' then
		local namespace = process.namespace -- if opts.namespace == 'share'

		if opts.namespace == 'new' then
			namespace = namespace.registerChild(processes.namespace())
		end

		process = namespace.new(pproc, pproc.title, (function(opt)
			if opt == 'clone' then
				return utils.cloneArr(pproc.args)
			elseif opt == 'share' then
				return pproc.args
			else -- if opt == 'new' then
				return {}
			end
		end)(opts.args))
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
		-- 	current = fs.current,
		-- 	root    = fs.root
		-- }
	end

	if opts.env == 'share' then
		thread.env = parent.env
	elseif opts.env == 'clone' then
		thread.env = utils.cloneDict(parent.env)
	end

	process.emit('newThread', thread)

	return thread
end

-- threads.scheduler()
-- WIP
function exports.scheduler()
	local scheduler = utils.eventEmitter({ threads = {} })

	function scheduler.run(iters)
		if type(iters) ~= 'number' then iters = 1 end

		for i = 1, iters do
			for thread in pairs(scheduler.threads) do
				if thread.alive and not thread.paused then
					thread.run()
				end
			end
		end
	end

	function scheduler.queue(...)
		for thread in pairs(scheduler.threads) do
			thread.queue(...)
		end
	end

	function scheduler.add(thread)
		scheduler.threads[thread] = thread
		scheduler.emit('add', thread)
	end

	function scheduler.remove(thread)
		scheduler.emit('remove', thread)
		scheduler.threads[thread] = nil
	end

	return scheduler
end

function exports.current() return current end

function exports.isThread(thread)
	return type(thread) == 'table' and thread.type == exports.type
end