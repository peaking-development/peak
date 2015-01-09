local function tick(t)
	peak.time = t

	peak.tick()

	if peak.processes.anyReady() then
		return 0
	else
		return peak.timers.nextTime() - peak.time
	end
end

return {
	boot = peak.boot;
	tick = tick;
	status = function() return peak.status end
}