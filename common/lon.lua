local function serialize(data)
	local path = {} -- {{tbl, idx, last idx}*}
	local curr = data
	local out = ''
	local continue = true
	local function next_key(pe)
		curr = pe[1][pe[2]]
		if type(pe[2]) == 'number' then
			if pe[2] > pe[3] + 1 then
				-- print(pe[3], pe[2])
				for i = pe[3] + 2, pe[2] do
					out = out .. 'nil; '
				end
			end
			pe[3] = pe[2]
		elseif type(pe[2]) == 'string' and pe[2]:match('[a-zA-Z_][a-z0-9A-Z_]*') then
			out = out .. pe[2] .. ' = '
		else
			out = out .. '[' .. serialize(pe[2]) .. '] = '
		end
	end
	local function escape()
		if #path > 0 then
			local pe = path[#path]
			local pk = pe[2]
			-- print('next key', pe[2], #path)
			pe[2] = next(pe[1], pe[2])
			if pe[2] == nil then
				-- print('escaping', pk, #path)
				path[#path] = nil
				if #path > 0 then
					curr = path[#path][1]
				else
					continue = false
				end
				out = out .. '; }'
				if continue then escape() end
			else
				out = out .. '; '
				next_key(pe)
			end
		else
			continue = false
		end
	end
	while continue do
		if type(curr) == 'table' then
			-- print('nesting', (path[#path] or {})[2])
			out = out .. '{ '
			local pe = {curr, next(curr), 0}
			if pe[2] == nil then
				out = out .. '}'
				escape()
			else
				path[#path + 1] = pe
				next_key(pe)
			end
		else
			if type(curr) == 'string' then
				out = out .. '\'' .. curr:gsub('\'', '\\\''):gsub('\\', '\\\\'):gsub('\n', '\\n'):gsub('\r', '\\r') .. '\''
			else
				out = out .. tostring(curr)
			end
			escape()
		end
	end
	return out
end

local function unserialize(str)
	return loadstring(str)
end

return {
	serialize = serialize;
	to = serialize;

	unserialize = unserialize;
	un = serialize;
}
