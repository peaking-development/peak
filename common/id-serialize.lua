local parser = require 'common/parser'
local var = parser.var
local num = parser.num
local function serialize(v)
	local next_id = 0
	local function gen_id()
		local res = next_id
		next_id = next_id + 1
		return res
	end
	local ids = {}
	local queue = {}
	local function gen_ref(v)
		if type(v) == 'table' then
			local id
			if ids[v] then
				id = ids[v]
			else
				id = gen_id()
				ids[v] = id
				queue[#queue + 1] = {id, v}
			end
			return 'R' .. num(id)
		elseif type(v) == 'string' then
			return 'S' .. var(v)
		elseif type(v) == 'number' then
			return 'N' .. num(v)
		elseif type(v) == 'boolean' then
			return v and 'T' or 'F'
		elseif v == nil then
			return 'U'
		else
			error('bad: ' .. type(v))
		end
	end
	local res = gen_ref(v)

	while #queue > 0 do
		local id, v = table.unpack(table.remove(queue, 1), 1, 2)
		local tbl_res = num(id)
		for k, v in pairs(v) do
			tbl_res = tbl_res .. gen_ref(k) .. gen_ref(v)
		end
		res = res .. var(tbl_res)
	end

	return res
end

local function unserialize(read)
	read = parser(read)
	local tbls = {}
	local function get_tbl(id)
		local tbl = tbls[id]
		if tbl == nil then
			tbl = {}
			tbls[id] = tbl
		end
		return tbl
	end
	local function read_ref(read)
		local t = read(1)
		if t == 'R' then
			return get_tbl(read('num'))
		elseif t == 'S' then
			return read()
		elseif t == 'N' then
			return read('num')
		elseif t == 'T' then
			return true
		elseif t == 'F' then
			return false
		elseif t == 'U' then
			return nil
		else
			error('bad: ' .. t)
		end
	end
	local res = read_ref(read)
	while not read.done() do
		local tbl_read = read('sub')
		local id = tbl_read('num')
		local tbl = get_tbl(id)
		while not tbl_read.done() do
			local k = read_ref(tbl_read)
			local v = read_ref(tbl_read)
			tbl[k] = v
		end
	end
	return res
end

return {
	to = serialize;
	un = unserialize;
}
