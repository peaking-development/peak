local timers = {}
local lastTID = peak.config.startID

local function set(time)
	local tid = lastTID
	do
		local looped = false
		while timers[tid] do
			if tid >= peak.config.maxID then
				if looped then
					error('No available timer id')
				else
					tid = startID
					looped = true
				end
			else
				tid = tid + 1
			end
		end
		if tid == lastTID then
			lastTID = lastTID + 1
		end
	end

	local timer = {
		id = tid;
		time = time;
		refs = 0;
	}
	timer.promise, timer.resolve = Promise.pending()
	timer.promise.timer = timer
	timers[tid] = timer
	return timer
end

local function get(tid)
	if not timers[tid] then error('Non-existent timer: ' .. tostring(tid)) end
	return timers[tid]
end

local function grab(timer)
	timer.refs = timer.refs + 1
end

local function release(timer)
	timers.refs = timer.refs - 1
	if timer.refs <= 0 then
		timers[timer.id] = nil
	end
end

local function process()
	for tid, timer in pairs(timers) do
		if peak.time >= timer.time then
			timer.resolve(true, peak.time)
			timers[tid] = nil
		end
	end
end

local function nextTime()
	local nextTime = math.huge
	for tid, timer in pairs(timers) do
		if peak.time < timer.time then
			nextTime = math.min(nextTime, timer.time)
		end
	end
	return nextTime
end

return {
	set = set;
	get = get;
	grab = grab;
	release = release;
	process = process;
	nextTime = nextTime;
}