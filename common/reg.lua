return function()
	local reg = {}
	local ids = setmetatable({}, {__mode = 'k'})

	function reg.register(v)
		local id = {}
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
			if type(k) == 'table' and #k == 0 then
				return ids[k]
			end
		end;

		__pairs = function(self)
			return pairs(ids)
		end;
	})

	return reg
end
