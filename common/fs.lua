local Promise = require 'common/promise'
local sync = require 'common/promise-sync'
local wait = sync.wait
local E = require 'common/error'
local xtend = require 'common/xtend'

local FS; FS = {
	validate_type = function(typ)
		return typ == 'file' or typ == 'folder' or typ == 'stream' or typ == 'user'
	end;
}

setmetatable(FS, { __call = function(self, ...)
	local fs_opts = {}
	local fs
	for i = 1, select('#', ...) do
		local arg = select(i, ...)
		if type(arg) == 'table' then
			fs_opts = xtend(fs_opts, arg)
		elseif type(arg) == 'function' then
			fs = arg
		else
			error('bad arg: ' .. tostring(arg) .. ' @ ' .. tostring(i))
		end
	end
	if fs_opts.open_stat == nil then fs_opts.open_stat = true end
	if not fs then error 'no filesystem' end
	local function rfs(path, op, ...)
		-- print(FS.serialize_path(path), op)
		local args = {...}
		local function run()
			return fs(path, op, table.unpack(args))
		end
		return (({
			open = function(opts)
				if fs_opts.open_stat then
					return ret(sync(function()
						local stat = wait(rfs(path, 'stat'))
						if not stat.exists and opts.create then
								if not FS.validate_type(opts.type) then return ret(Promise.resolved(false, E.invalid_type)) end

								wait(rfs(path, 'create', xtend(type(opts.create) == 'table' and opts.create or {}, {
									type = opts.type;
								})))
								stat = wait(rfs(path, 'stat'))
						end

						local realOpts = {}
						if not realOpts.type then realOpts.type = stat.type end
						if stat.type ~= realOpts.type then return ret(Promise.resolved(false, E.wrong_type)) end
						if realOpts.type == 'file' then
							if opts.write then realOpts.write = true end
							if opts.clear then realOpts.clear = true end
						elseif realOpts.type == 'api' then
							if opts.execute then realOpts.execute = true end
							if opts.provide then realOpts.provide = true end
						end

						if stat.exists then
							local h = wait(fs(path, 'open', realOpts))
							h = FS.wrap_handle[realOpts.type](h)
							h.type = stat.type
							h.opts = realOpts
							return h
						else
							error({E.nonexistent, 'fs'})
						end
					end))
				else
					return fs(path, 'open', opts)
				end
			end;

			stat = function()
				return Promise(
					fs(path, 'stat'),
					Promise.flatMap(function(stat)
						if not FS.validate_type(stat.type) then return ret(Promise.resolved(false, E.invalid_type)) end
						return Promise.resolved(true, stat)
					end)
				)
			end;

			create = function(opts)
				return fs(path, 'create', opts)
			end;
		})[op] or function() return ret(Promise.resolved(false, 'Unhandled operation: ' .. tostring(op))) end)(...)
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

function FS.wrap_stream(_pull)
	local buffer = ''
	local done = false
	local function pull(len)
		if len then
			while not done and #buffer < len do
				pull()
			end
		else
			if done then return end
			local res = wait(_pull())
			if res then
				buffer = buffer .. res
			else
				done = true
			end
		end
	end
	return function(len)
		return ret(sync(function()
			if done and #buffer == 0 then return end
			local res
			if len == math.huge then
				pull(math.huge)
				res = buffer
				buffer = ''
			elseif len == 'line' then
				while not done and not buffer:find('[\n\r]') do
					pull()
				end
				local index = buffer:find('[\n\r]')
				local m = buffer:match('[\n\r]*')
				if index then
					local l
					if m:sub(0, 2) == '\r\n' then
						l = 2
					else
						l = 1
					end
					res = buffer:sub(0, index - 1)
					buffer = buffer:sub(index + l)
				else
					res = buffer
					buffer = ''
				end
			elseif type(len) == 'number' and len > 0 then
				pull(len)
				res = buffer:sub(0, len + 1)
				buffer = buffer:sub(len)
			else
				pull()
				res = buffer
				buffer = ''
			end
			return res
		end))
	end
end

function FS.wrap_buffer(_pull)
	local buffer = ''
	local pos = 1
	local done = false
	local h = {}
	local function pull(len)
		if len then
			while not done and #buffer < len do
				pull()
			end
		else
			if done then return end
			local res = wait(_pull())
			if res then
				buffer = buffer .. res
			else
				done = true
			end
		end
	end
	local function read(len)
		if #buffer < pos + len then
			pull(pos + len)
		end
		local res = buffer:sub(pos, pos + len - 1)
		pos = pos + len
		if pos > #buffer then pos = #buffer end
		return res
	end
	function h.read(len)
		return ret(sync(function()
			local res
			if len == math.huge then
				pull(math.huge)
				res = buffer:sub(pos)
				pos = #buffer
			elseif len == 'line' then
				local index = buffer:find('[\n\r]', pos)
				local m = buffer:match('[\n\r]*', pos)
				while not done and not index do
					pull()
					index = buffer:find('[\n\r]', pos)
					m = buffer:match('[\n\r]*', pos)
				end
				res = read(index - pos)
			elseif type(len) == 'number' and len > 0 then
				res = read(len)
			else
				res = read(10)
			end
			return res
		end))
	end
	function h.seek(whence, offset)
		if whence == 'set' then
			pos = offset + 1
		elseif whence == 'cur' then
			pos = pos + offset
		else
			error('invalid whence: ' .. tostring(whence))
		end
		return Promise.resolved(true, pos - 1)
	end
	function h.close()
		done = true
		return Promise.resolved(true)
	end
	return h
end

FS.wrap_handle = {}
function FS.wrap_handle.file(h)
	local rh = {}
	function rh.read(len)
		return h.read(len)
	end
	function rh.seek(whence, offset)
		if whence == nil then
			whence = 'cur'
			offset = 0
		end
		if type(whence) == 'number' then
			offset = whence
			whence = 'cur'
		end
		if offset == nil then
			offset = 0
		end
		return h.seek(whence, offset)
	end
	function rh.close()
		return h.close()
	end
	if h.write then
		function rh.write(data)
			return h.write(data)
		end

		function rh.flush()
			return h.flush()
		end
	end
	return rh
end

function FS.wrap_handle.folder(h)
	local rh = {}
	local done = false
	function rh.read()
		if done then
			return Promise.resolved(true, nil)
		end
		return Promise(
			h.read(),
			Promise.map(function(n)
				if n == nil then
					done = true
				end
				return n
			end)
		)
	end
	function rh.close()
		done = true
		return Promise.resolved(true)
	end
	return rh
end

function FS.wrap_handle.api(h)
	return h
end

return FS
