local str; str = {
	split = function(sep, plain)
		return function(self)
			local parts = {''}
			local partsIndex = 1
			local i = 1
			while i < #self do
				local begin, finish = self:find(sep, i, plain)
				if begin == i then
					i = finish + 1
					parts[#parts + 1] = ''
					partsIndex = partsIndex + 1
				else
					if begin == nil then
						begin = #self + 1
					end
					parts[partsIndex] = parts[partsIndex] .. self:sub(i, begin - 1)
					i = begin
				end
			end
			return parts
		end
	end
}; return str