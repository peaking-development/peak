local Promise = require 'common/promise'
local E = require 'common/error'

local FS; FS = {
	validate_type = function(typ)
		return typ == 'file' or typ == 'folder' or typ == 'stream' or typ == 'user'
	end;
}

setmetatable(FS, { __call = function(self, fs)
	local function rfs(path, op, ...)
		local args = {...}
		local function run()
			return fs(path, op, table.unpack(args))
		end
		return (({
			open = function(opts)
				return Promise(
					rfs(path, 'stat'),
					Promise.flatCatch(function(err, ...)
						if err == E.nonexistent and opts.create then
							if not FS.validate_type(opts.type) then return Promise.resolved(false, E.invalid_type) end

							return Promise(
								rfs(path, 'create', {
									type = opts.type;
								}),
								Promise.flatMap(function()
									return rfs(path, 'stat')
								end)
							)
						else
							return Promise.resolved(false, err, ...)
						end
					end),
					Promise.flatMap(function(stat)
						local realOpts = {}
						if not realOpts.type then realOpts.type = stat.type end
						if stat.type ~= realOpts.type then return Promise.resolved(false, E.wrong_type) end
						if stat.type == 'file' or stat.type == 'stream' then
							if not FS.validate_mode(realOpts.type, opts.mode) then return Promise.resolved(false, E.invalid_mode) end
							realOpts.mode = opts.mode
							if realOpts.mode == 'write' and opts.append == true then realOpts.append = true end
						end

						if stat.exists then
							return Promise(
								fs(path, 'open', realOpts),
								Promise.map(function(h)
									h.type = stat.type
									h.opts = realOpts
									return h
								end)
							)
						else
							return Promise.resolved(false, E.nonexistent, 'fs')
						end
					end)
				)
			end;

			stat = function()
				return Promise(
					fs(path, 'stat'),
					Promise.flatMap(function(stat)
						if not FS.validate_type(stat.type) then return Promise.resolved(false, E.invalid_type) end
						return Promise.resolved(true, stat)
					end)
				)
			end;

			create = function(opts)
				return fs(path, 'create', opts)
			end;
		})[op] or function() return Promise.resolved(false, 'Unhandled operation: ' .. tostring(op)) end)(...)
	end
	return setmetatable({}, { __call = function(self, ...) return rfs(...) end })
end })

function FS.validate_mode(mode)
	return true -- TODO: validate_type
end

function FS.validate_type(typ)
	return true -- TODO: validate_type
end

function FS.serialize_path(path)
	local out = {}
	for i, v in ipairs(path) do
		out[i] = v:gsub('\\', '\\\\'):gsub('/', '\\/')
	end
	return table.concat(out, '/')
end

local function unescape(str)
	return str:gsub('\\\\', '\\'):gsub('\\/', '/')
end

function FS.unserialize_path(path)
	local pat = '(\\*)/'
	local out = {}
	local pre, tmp
	local last_index = 0
	while not (pre and #pre % 2 == 0) do
		pre = path:match(pat)
		local index = path:find(pat)
		last_index = index + #pre + 1
		tmp = path:sub(0, index - 1)
	end
	-- print(last_index, tmp)
	for pre in path:gmatch(pat) do
		-- print('pre', #pre % 2, pre)
		-- print('past', path:sub(0, last_index))
		local index = path:find(pat, last_index + 1)
		if #pre % 2 == 0 then
			-- print('adding\\\\', ('\\'):rep(#pre / 2))
			tmp = tmp .. ('\\'):rep(#pre / 2)
			-- print('splitting', tmp, last_index)
			out[#out + 1] = tmp
			tmp = ''
		else
			tmp = tmp .. ('\\'):rep((#pre - 1) / 2) .. '/'
			-- print('adding\\', pre .. '/', tmp)
		end
		-- print('sub', last_index, index, index and path:sub(last_index, index - 1) or path:sub(last_index))
		-- print('adding', (index and path:sub(last_index + 1, index - 1) or path:sub(last_index + 1)), tmp)
		tmp = tmp .. unescape(index and path:sub(last_index + 1, index - 1) or path:sub(last_index + 1))
		if index then
			last_index = index + #pre
		end
	end
	out[#out + 1] = tmp
	return out
end

return FS
