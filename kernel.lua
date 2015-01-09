local peak = {}
_G.peak = peak

local Promise = require 'promise'
_G.Promise = Promise

peak.config = require 'config'
peak.syscalls = require 'syscalls'
peak.timers = require 'timers'
peak.processes = require 'processes'

peak.status = 'ready'

function peak.boot()
	if peak.status ~= 'ready' then error('Invalid status for driver.boot: ' .. peak.status) end
	peak.status = 'on'
	peak.processes.spawn {
		code = function()
			local function sleep(time)
				local ok, _, cur = coroutine.yield('wait', coroutine.yield('time'))
				if ok then
					coroutine.yield('wait', coroutine.yield('timer', cur + time))
				else
					error(_)
				end
			end
			coroutine.yield('continue')
			print('sleeping')
			-- sleep(1)
			-- print('more sleeping')
			-- sleep(1)
			sleep(2)
			print('hi')
		end
	}
end

function peak.tick()
	if peak.status ~= 'on' then error('Invalid status for driver.tick: ' .. peak.status) end

	peak.timers.process()

	peak.processes.run()

	if peak.processes.get(0).status == 'finished' then
		peak.status = 'off'
	end
end

return require('driver')