local FS = require 'common/fs'
local Promise = require 'common/promise'
local lon = require 'common/lon'
local util = require 'common/util'

return function(component)
	return FS(function(path, op, ...)
		return (({
			stat = function()
				local comp_stat = {
					exists = true;
					type = 'api';
					perms = {
						read = '*a';
						execute = '*a';
						write = nil;
					}
				}
				local folder_stat = {
					exists = true;
					type = 'folder';
				}
				if #path == 0 then
					return Promise.resolved(true, folder_stat)
				elseif #path == 1 then
					if component.list()[path[1]] then
						return Promise.resolved(true, comp_stat)
					else
						for _, typ in component.list() do
							if typ == path[1] then
								return Promise.resolved(true, folder_stat)
							end
						end
						return Promise.resolved(true, { exists = false; })
					end
				elseif #path == 2 then
					if component.type(path[2]) == path[1] then
						return Promise.resolved(true, comp_stat)
					else
						return Promise.resolved(true, { exists = false; })
					end
				else
					return Promise.resolved(true, { exists = false; })
				end
			end;
			
			open = function(opts)
				local h = {}
				local function list(typ)
					local co = coroutine.create(function()
						local sent = {}
						for id, _typ in (typ and component.list(typ, true) or component.list()) do
							coroutine.yield(id)
							if not typ and not sent[_typ] then
								coroutine.yield(_typ)
								sent[_typ] = true
							end
						end
					end)
					function h.read()
						if coroutine.status(co) == 'dead' then return Promise.resolved(true, nil) end
						local ok, res = coroutine.resume(co)
						if coroutine.status(co) == 'dead' then return Promise.resolved(true, nil) end
						return ret(Promise.resolved(ok, res))
					end
					function h.close()
						return Promise.resolved(true)
					end
				end
				local function provide(id)
					function h.list()
						return Promise.resolved(true, component.methods(id))
					end

					if opts.execute then
						function h.call(name, ...)
							-- print('calling component ' .. tostring(id) .. '.' .. name .. '(' .. table.concat(util.map({...}, lon.to), ', ') .. ')')
							return ret(Promise.resolved(xpcall(component.invoke, function(err)
								return lon.to(err) .. '\n' .. debug.traceback()
							end, id, name, ...)))
						end
					end

					if opts.provide then
						error('trying to provide to component')

						-- h.provide(name, doc)
						-- h.unprovide(name)
						-- h.read(): id, name, ...
						-- h.respond(id, ...)
					end

					function h.close()
						return Promise.resolved(true)
					end
				end
				if #path == 0 then
					list()
				elseif #path == 1 then
					local comps = component.list()
					if comps[path[1]] then
						provide(path[1])
					else
						for _, typ in comps do
							if typ == path[1] then
								list(typ)
								break
							end
						end
					end
				elseif #path == 2 and component.list()[path[2]] then
					provide(path[2])
				else
					error('bad')
				end
				return Promise.resolved(true, h)
			end;
		})[op] or error('unhandled operation: ' .. tostring(op)))(...)
	end)
end
