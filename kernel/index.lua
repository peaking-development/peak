local lon = require 'common/lon'

local peak = {}
_G.peak = peak

local Promise = require 'promise'

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
			-- local fd = wait(K.open({'oc-component-bus', '23e7e38c-9224-406c-a46e-c5fbae2353df'}, {
			-- 	type = 'api';
			-- 	execute = true;
			-- }))
			-- wait(K.call(fd, 'bind', '8668c677-17d3-442c-8d68-c789d3f309c9'))
			-- wait(K.call(fd, 'set', 1, 2, 'heyo'))
			-- wait(K.close(fd))
			-- local fd = wait(K.open({'oc-component-bus'}, {
			-- 	type = 'folder';
			-- }))
			-- local res
			-- repeat
			-- 	res = wait(K.read(fd))
			-- 	if res then print(res) end
			-- until res == nil
			-- wait(K.close(fd))
			local fd = wait(K.open({'test-api'}, {
				type = 'api';
				create = true;
				provide = true;
				execute = true;
			}))
			wait(K.provide(fd, 'hello world', 'Say "Hello World!"'))
			p(wait(K.list(fd)))
			local call = K.call(fd, 'hello world')
			local req = table.pack(wait(K.read(fd)))
			local id = table.remove(req, 1)
			local name = table.remove(req, 1)
			if name == 'hello world' then
				print('Hello World')
				wait(K.respond(fd, id, true))
			else
				print(req[2])
			end
			wait(call)
			wait(K.close(fd))
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
