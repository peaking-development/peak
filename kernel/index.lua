local peak = {}
_G.peak = peak

local Promise = require 'promise'
_G.Promise = Promise

peak.config = require 'config'
peak.syscalls = require 'syscalls'
peak.timers = require 'timers'
peak.processes = require 'processes'

peak.fs = require 'common/mount-fs' ()

peak.status = 'ready'

function peak.boot()
	if peak.status ~= 'ready' then error('Invalid status for driver.boot: ' .. peak.status) end
	peak.status = 'on'
	peak.processes.spawn {
		code = function()
			local K = setmetatable({}, {
				__index = function(self, k)
					local function call(...) return coroutine.yield(k, ...) end
					rawset(self, k, call)
					return call
				end;
			})

			local function wait(prom)
				local res = {K.wait(prom)}
				table.remove(res, 1) -- remove the index
				local ok = table.remove(res, 1)
				if ok then
					return table.unpack(res)
				else
					error(res[1])
				end
			end

			local function sleep(time)
				local ok, _, cur = wait(K.time())
				if ok then
					wait(K.timer(cur + time))
				else
					error(_)
				end
			end
			local fd = wait(K.open({'oc-component-bus', '918d8e46-a5ed-4576-ba38-7814e16be5d8'}, {
				type = 'api';
				execute = true;
			}))
			wait(K.call(fd, 'bind', '8668c677-17d3-442c-8d68-c789d3f309c9'))
			wait(K.call(fd, 'set', 1, 2, 'heyo'))
			wait(K.close(fd))
			-- local fd = wait(K.open({'oc-component-bus'}, {
			-- 	type = 'folder';
			-- }))
			-- local res
			-- repeat
			-- 	res = wait(K.read(fd))
			-- 	if res then print(res) end
			-- until res == nil
			-- wait(K.close(fd))
			-- local fd = wait(K.open({'test-api'}, {
			-- 	type = 'api';
			-- 	create = true;
			-- 	provide = true;
			-- }))
			-- wait(K.close(fd))
		end
	}
end

local queue = {}
peak.queue = queue

function peak.tick()
	if peak.status ~= 'on' then error('Invalid status for driver.tick: ' .. peak.status) end

	peak.timers.process()

	if #queue > 0 then
		table.remove(queue, 1)()
	end

	if peak.processes.get(0).status == 'finished' then
		peak.status = 'off'
	end
end

return require('driver')
