--[=====[Peak Processes by CoderPuppy]=====]

local threads = require('./threads')
local utils   = require('peak-utils')

--[[process = {
	id             = process id,
	parent         = parent process,
	title          = name of process,
	-- These are annoying because no main thread, TODO: Remove them
	-- main           = the file to run in the main thread,
	-- args           = the arguments passed to this process,
	threads        = this process's threads,
	namespace      = the namespace this process is in,
	queue(ev, ...) = queue and event to all the threads

	-- PIDs should generally be numbers
}]]

exports.type    = {'PROCESS'}
exports.type[2] = exports.type

-- processes.newBase
-- Create a new process
function exports.newBase(parent, pid, title)
	local process = utils.eventEmitter({
		type    = exports.type,
		id      = pid,
		parent  = parent,
		title   = title,
		threads = {}
	})

	function process.queue(ev, ...)
		for i = 1, #process.threads do
			process.threads[i].queue(ev, ...)
		end
	end

	return process
end

-- TODO: figure out a way to switch namespaces
--[[namespace = utils.eventEmitter({
	registerChild(namespace): namespace = register a child namespace, returns the child,
	new(parent, title, ...): process = create a process,
	-- TODO: This probably needs a filtering mechanic
	list(): processes = get all the processes
})]]

-- processes.namespaceBase() = namespace, internal
-- Creates a new namespace
-- The difference between this and processes.namespace() is this also returns the internal data
function exports.namespaceBase()
	local namespace

	local internal = {
		processes = {},
		lastPid   = 1,
		pids      = {},
		children  = {}
	}

	function internal.importProcess(pid, process)
		local pid = internal.generatePid()
		internal.processes[pid] = process
		internal.pids[process]  = pid
		namespace.emit('new', pid, process)
	end

	function internal.generatePid()
		local pid = internal.lastPid

		while internal.processes[pid] ~= nil do
			pid = pid + 1
		end

		internal.lastPid = pid == namespace.maxPid and 1 or pid + 1

		return pid
	end

	namespace = utils.eventEmitter({
		maxPid = 4096
	})

	function namespace.registerChild(ns)
		local nsProcs = ns.list()
		for i = 1, #nsProcs do
			internal.importProcess(nil, nsProcs[i][2])
		end

		internal.children[#internal.children + 1] = ns

		ns.on('new', internal.importProcess)

		namespace.emit('newChild', ns)

		return ns
	end

	function namespace.list()
		local procs = {}

		for pid, proc in pairs(internal.processes) do
			procs[#procs + 1] = {pid, proc}
		end

		return procs
	end

	function namespace.new(parent, title, ...)
		local pid     = internal.generatePid()
		local process = exports.newBase(parent, pid, title, ...)

		internal.processes[pid] = process
		internal.pids[process]  = pid

		process.on('exit', function(status)
			internal.processes[pid] = nil
			internal.pids[process]  = nil
		end)

		namespace.emit('new', pid, process)

		return process
	end

	return namespace, internal
end

-- processes.kernelNamespace(kernel)
-- Creates a new namespace that can only have the kernel in it
-- That does not mean it only can list one process
-- Just that only on process can natively be in it
-- Other ones have to be in children
function exports.kernelNamespace(kernel)
	local namespace, internal = exports.namespaceBase()

	kernel.id             = 1
	kernel.namespace      = namespace
	internal.processes[1] = kernel
	internal.pids[kernel] = 1

	function namespace.new() error('Cannot create new processes in the kernel namespace, create a new one', 2) end

	return namespace
end

-- processes.namespace()
-- Creates a new namespace
-- This is just processes.namespaceBase() but without returning the internal data
function exports.namespace()
	return select(1, exports.namespaceBase())
end

-- processes.current()
-- Get the current process
function exports.current()
	local thread = threads.current()
	if thread ~= nil then return thread.process end
end