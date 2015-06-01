return {
	time = function(proc)
		return Promise.resolved(true, peak.time)
	end;

	timer = function(proc, time)
		return peak.timers.set(time).promise
	end;
}
