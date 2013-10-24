--[=====[Peak Threading by CoderPuppy]=====]
-- Threads and scheduler
-- This might have to be specific to peak
-- Mainly the processes have their own threads

function exports.new(fn, ...)
	local thread = {
		type = exports.type,
		running = false,
		eventQueue = { {...} },
		coroutine = coroutine.create(fn)
	}

	-- Maybe this should return how many iterations it got through
	function thread.run(iters)
		if type(iters) ~= 'number' then iters = 1 end

		for i = 1, iters do
			if #thread.eventQueue == 0 then return false end
			coroutine.resume(thread.coroutine, unpack(table.remove(thread.eventQueue)))
		end
	end

	function thread.queue(ev, ...)
		thread.eventQueue[#thread.eventQueue + 1] = { ev, ... }
		return #thread.eventQueue
	end

	function thread.interupt(ev, ...)
		return thread.run(thread.queue(ev, ...))
	end

	return thread
end

function exports.scheduler()
	local scheduler = {
		threads = {}
	}

	function scheduler.interupt(ev, ...)

	end

	return scheduler
end

-- Totally unique, though it doesn't serialize
exports.type = {'THREAD'}
exports.type[2] = exports.type

exports.root = {
	type = exports.type,
	running = true,
	eventQueue = {},
	run = function() end,
	filter = function() end,
	queue = function() end
}
exports.current = exports.root