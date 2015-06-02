local timers = require 'common/reg' {}

local function set(time)
	local timer = {
		time = time;
	}
	timer.id = timers.register(timer)
	timer.promise, timer.resolve = Promise.pending()
	timer.promise.timer = timer
	return timer
end

local function get(tid)
	if not timers[tid] then error('Non-existent timer: ' .. tostring(tid)) end
	return timers[tid]
end

local function process()
	for tid, timer in pairs(timers) do
		if peak.time >= timer.time then
			timer.resolve(true, peak.time)
			timers[tid] = nil
		end
	end
end

local function next_time()
	local next_time = math.huge
	for tid, timer in pairs(timers) do
		if peak.time < timer.time then
			next_time = math.min(next_time, timer.time)
		end
	end
	return next_time
end

return {
	set = set;
	get = get;
	process = process;
	next_time = next_time;
}
