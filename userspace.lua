--[=====[Peak Userspace by CoderPuppy]=====]
-- TODO: More sandboxing
-- TODO: More libs

local kernel = setfenv(function(A)
	local _ = A
	A = nil

	return {
		kernel = setmetatable({
			-- Userspace doesn't need interupt, right...
			-- interupt = function(...) return _.interupt(...) end
		}, {
			__index = function(t, k)
				if k == 'fs' then return _.fs
				elseif k == 'namespace' then return _.namespace
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
	table = table,
	setmetatable = setmetatable,
	error = error
})

exports.kernel = kernel