return function()
	local reg = {}
	local ids = {}
	local lastid = 0

	-- the maximum value that can be represented
	reg.max = bit32.bnot(0)

	function reg.genid(id)
		local id = type(id) == 'number' and id or lastid
		local looped = false
		while ids[id] do
			if id == reg.max then
				id = 0
				if looped then
					error('No available ID')
				end
				looped = true
			else
				id = id + 1
			end
		end
		return id
	end

	function reg.register(v, id)
		local id = reg.genid(id)
		lastid = id
		ids[id] = v
		return id
	end

	function reg.release(id)
		ids[id] = nil
	end

	function reg.get(id)
		return ids[id]
	end

	setmetatable(reg, {
		__index = function(self, k)
			if type(k) == 'number' and k >= 0 and k <= reg.max then
				return ids[k]
			end
		end;

		__newindex = function(self, k, v)
			if type(k) == 'number' and k >= 0 and k <= reg.max then
				ids[k] = v
			else
				rawset(self, k, v)
			end
		end;

		__pairs = function(self)
			return pairs(ids)
		end;
	})

	return reg
end
