local function tick(t)
	peak.time = t

	peak.tick()

	return #peak.queue > 0, peak.timers.nextTime() - peak.time
end

return {
	boot = peak.boot;
	tick = tick;
	fs = peak.fs;
	status = function() return peak.status end
}
