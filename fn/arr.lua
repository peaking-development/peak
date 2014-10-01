local arr; arr = {
	map = function(fn)
		return function(self)
			local res = {}
			for i, v in ipairs(self) do
				res[i] = fn(v, i, self)
			end
			return res
		end
	end;

	filter = function(fn)
		return function(self)
			local res = {}
			for i, v in ipairs(self) do
				if fn(v, i, self) then
					res[#res + 1] = v
				end
			end
			return res
		end
	end;

	find = function(fn)
		return function(self)
			for i, v in ipairs(self) do
				if fn(v, i, self) then
					return v
				end
			end
		end
	end;

	reduce = function(fn, initial)
		return function(self)
			local acc = initial

			for i, v in ipairs(self) do
				acc = fn(acc, v, i, self)
			end

			return acc
		end
	end;

	contains = function(elem)
		return function(self)
			for _, v in ipairs(self) do
				if v == elem then
					return true
				end
			end
			return false
		end
	end;

	indexOf = function(elem)
		return function(self)
			for i, v in ipairs(self) do
				if v == elem then
					return i
				end
			end
			return -1
		end
	end;

	remove = function(query)
		return arr.filter(function(elem)
			return elem ~= query
		end)
	end;

	join = function(sep)
		return function(self)
			return table.concat(self, sep)
		end
	end
}; return arr