return {
	time = function(proc)
		return Promise.resolved(true, peak.time)
	end;

	timer = function(proc, time)
		local timer = peak.timers.set(time)
		peak.timers.grab(timer)
		return timer.promise
	end;
}