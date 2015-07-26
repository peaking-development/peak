-- REF: Monster Munch
local FS = require 'common/fs'
local Path = require 'common/path'
local Promise = require 'common/promise'
local xtend = require 'common/xtend'
local sync = require 'common/promise-sync'
local wait = sync.wait

local type_map = {
	api = 'A';
	file = 'F';
	user = 'U';
	group = 'G';
}
do
	local t = type_map
	type_map = xtend(type_map)
	for k, v in pairs(t) do
		type_map[v] = k
	end
end

return function(fs)
	local apis = {}

	return FS(function(path, op, ...)
		return (({
			stat = function()
				return ret(sync(function()
					local stat = wait(fs(path, 'stat'))
					if stat.exists and stat.type == 'file' then
						local stat = xtend(stat)
						local h = wait(fs(path, 'open', {
							type = 'file';
						}))
						local t = wait(h.read(1))
						stat.type = type_map[t]
						if not stat.type then
							error('invalid type: [' .. tostring(t) .. ']')
						end
						wait(h.close())
						return stat
					else
						return stat
					end
				end))
			end;
			create = function(opts)
				if opts.type == 'folder' then
					return fs(path, 'create', opts)
				else
					return ret(sync(function()
						local h = wait(fs(path, 'open', xtend(opts, { type = 'file'; create = opts; write = true; })))
						wait(h.write(type_map[opts.type]))
						wait(h.close())
					end))
				end
			end;
			open = function(opts)
				if opts.type == 'folder' then
					return fs(path, 'open', opts)
				else
					return ret(sync(function()
						local h = wait(fs(path, 'open', xtend(opts, { type = 'file'; })))
						local rh = {}
						if opts.type == 'api' then
							wait(h.close())
							local api = apis[Path.serialize(path)]
							if not api then
								api = {
									methods = {};
									queue = {};
									resolves = {};
								}
								apis[Path.serialize(path)] = api
							end
							local proc = {}
							local provided = {}

							function rh.list()
								local res = {}
								for name, method in pairs(api.methods) do
									res[#res + 1] = {name, method.doc}
								end
								return Promise.resolved(true, res)
							end

							if opts.execute then
								function rh.call(name, ...)
									local id = {}
									local method = api.methods[name]
									if not method then
										return Promise.resolved(false, 'UNKNWNMETH', name)
									end
									local promise, resolve = Promise.pending()
									api.resolves[id] = resolve
									if #method.waiting > 0 then
										table.remove(method.waiting, 1)(id, name, ...)
									else
										api.queue[#api.queue + 1] = table.pack(id, name, ...)
									end
									return promise
								end
							end
							
							if opts.provide then
								local waits = {}
								function rh.provide(name, doc)
									local method = api.methods[name]
									if not method then
										method = {
											name = name;
											num = 0;
											providers = {};
											doc = doc;
											waiting = {};
										}
										api.methods[name] = method
									end
									provided[name] = true
									if not method.providers[proc] then
										method.num = method.num + 1
									end
									method.providers[proc] = true
									if #waits > 0 then
										local t = waits
										waits = {}
										for _, run in ipairs(t) do
											rh.read()(function(ok, ...)
												run(...)
											end)
										end
									end
									return Promise.resolved(true)
								end

								function rh.unprovide(name)
									local method = api.methods[name]
									if method then
										if method.providers[proc] then
											method.num = method.num - 1
										end
										provided[name] = nil
										method.providers[proc] = nil
										if method.num == 0 then
											api.methods[name] = nil
										end
									end
									return Promise.resolved(true)
								end

								function rh.read()
									for i, req in ipairs(api.queue) do
										if provided[req[2]] then
											table.remove(api.queue, i)
											return Promise.resolved(true, table.unpack(req, 1, req.n))
										end
									end
									local promise, resolve = Promise.pending()
									local function run(...)
										for name in pairs(provided) do
											local waiting = api.methods[name].waiting
											for i, r_ in ipairs(waiting) do
												if r_ == run then
													table.remove(waiting, i)
												end
											end
										end
										resolve(true, ...)
									end
									waits[#waits + 1] = run
									for name in pairs(provided) do
										local method = api.methods[name]
										method.waiting[#method.waiting + 1] = run
									end
									return promise
								end

								function rh.respond(id, ok, ...)
									local resolve = api.resolves[id]
									if not resolve then
										return Promise.resolved(false, 'UNKNWNID', id)
									end
									if type(ok) ~= 'boolean' then
										return Promise.resolved(false, 'IVLDOK', ok)
									end
									resolve(ok, ...)
									return Promise.resolved(true)
								end
							end

							function rh.close()
								return Promise.resolved(true)
							end
						elseif opts.type == 'file' then
							function rh.seek(whence, offset)
								if whence == 'set' and offset <= 0 then
									offset = 1
								end
								return ret(sync(function()
									local pos = wait(h.seek(whence, offset))
									if pos <= 0 then
										pos = wait(h.seek('set', 1))
									end
									return pos
								end))
							end
							rh.seek('set', 0)
							rh.read = h.read

							if opts.write then
								rh.write = h.write
								rh.flush = h.flush
							end

							rh.close = h.close
						else
							error('unhandled type: ' .. tostring(opts.type))
						end

						return rh
					end))
				end
			end;
		})[op] or error('unhandled operation: ' .. tostring(op)))(...)
	end)
end
