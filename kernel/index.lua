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
			-- write to screen
			if false then
				local fd = wait(K.open({'oc-component-bus', '23e7e38c-9224-406c-a46e-c5fbae2353df'}, {
					type = 'api';
					execute = true;
				}))
				wait(K.call(fd, 'bind', '8668c677-17d3-442c-8d68-c789d3f309c9'))
				wait(K.call(fd, 'set', 1, 2, 'heyo'))
				wait(K.close(fd))
			end

			-- list components
			if false then
				local fd = wait(K.open({'oc-component-bus'}, {
					type = 'folder';
				}))
				local res
				repeat
					res = wait(K.read(fd))
					if res then print(res) end
				until res == nil
				wait(K.close(fd))
			end

			-- play with api (say hello world)
			if false then
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
				local id = req[1]
				local name = req[2]
				req = table.pack(table.unpack(req, 2, req.n))
				if name == 'hello world' then
					print('Hello World')
					wait(K.respond(fd, id, true))
				else
					print(req[2])
				end
				wait(call)
				wait(K.close(fd))
			end

			-- apis with processes
			if false then
				local fd = wait(K.open({'test-api'}, {
					type = 'api';
					create = true;
					provide = true;
					execute = true;
				}))
				wait(K.provide(fd, 'ready'))
				wait(K.fork(function()
					local fd = wait(K.open({'test-api'}, {
						type = 'api';
						create = true;
						provide = true;
						execute = true;
					}))
					wait(K.provide(fd, 'hello world'))
					wait(K.provide(fd, 'fizbuz'))
					wait(K.provide(fd, 'close'))
					wait(K.call(fd, 'ready'))
					while true do
						local req = table.pack(wait(K.read(fd)))
						local id, name, req = req[1], req[2], table.pack(table.unpack(req, 2, req.n))
						if name == 'hello world' then
							print('Hello World')
							wait(K.respond(fd, id, true))
						elseif name == 'fizbuz' then
							print('fizbuz')
							wait(K.respond(fd, id, true))
						elseif name == 'close' then
							wait(K.respond(fd, id, true))
							wait(K.close(fd))
							break
						else
							wait(K.respond(fd, id, false, 'unknown: ' .. name))
						end
					end
				end))
				local req = table.pack(wait(K.read(fd)))
				local id, name, req = req[1], req[2], table.pack(table.unpack(req, 2, req.n))
				if name == 'ready' then
					wait(K.respond(fd, id, true))
					wait(K.call(fd, 'hello world'))
					wait(K.call(fd, 'fizbuz'))
					wait(K.call(fd, 'close'))
					wait(K.close(fd))
				else
					wait(K.respond(fd, id, false, 'unknown: ' .. name))
				end
			end

			-- play with fuse
			if false then
				local fd = wait(K.open({'test-fs-api'}, {
					type = 'api';
					create = true;
					provide = true;
				}))
				wait(K.provide(fd, 'stat'))
				wait(K.mount({'test-fs'}, {'test-fs-api'}, 10))
				local stat = K.stat({'test-fs'})
				local req = table.pack(wait(K.read(fd)))
				local id = req[1]
				local name = req[2]
				local path = req[3]
				req = table.pack(table.unpack(req, 4, req.n))
				if name == 'stat' then
					p(path, req)
					wait(K.respond(fd, id, true, { exists = true; type = 'folder'; }))
				else
					wait(K.respond(fd, id, false, 'unknown'))
				end
				p(wait(stat))
			end

			-- fork, exec and env vars
			if false then
				wait(K.setenv('heyo', 'fizbuz'))
				local pid = wait(K.fork(function()
					print(wait(K.getenv('heyo')))
					print(table.concat(wait(K.listenv()), ', '))
					print('forked')
					wait(K.exec({'test-exec'}, {'arg'}))
				end))
				print('pid', pid)
				wait(K.wait_exit(pid))
			end

			-- play with streams
			if false then
				local fd = wait(K.open({'test-stream'}, {
					type = 'stream';
					create = true;
					write = true;
				}))
				local write = K.write(fd, 'hello')
				p(wait(K.read(fd)))
				wait(write)
				wait(K.close(fd))
			end

			-- oc signal bus
			if true then
				local fd = wait(K.open({'oc-signal-bus'}, {
					type = 'stream';
				}))
				for i = 1, 10 do
					p(wait(K.read(fd)))
				end
				wait(K.close(fd))
			end
		end;
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
