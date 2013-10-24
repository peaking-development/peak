--[=====[Peak Userspace by CoderPuppy]=====]
-- TODO: More sandboxing
-- TODO: More libs

module.exports = setfenv(function(A)
	local _ = A
	A = nil

	return {
		kernel = setmetatable({
			-- Userspace doesn't need interupt, right...
			-- interupt = function(...) return _.interupt(...) end
		}, {
			__index = function(t, k)
				if k == 'fs' then return _.fs
				elseif k == 'proc' then return _.proc
				else return nil end
			end,
			__newindex = function(t, k, v)
				error('Attempt to modify kernel', 2)
			end,
			__metatable = 'Kernel'
		}),
		coroutine = coroutine,
		string = string,
		table = table
	}
end, {
	coroutine = coroutine,
	string = string,
	table = table
})