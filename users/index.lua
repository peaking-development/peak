--[=====[Peak Users by CoderPuppy]=====]

local processes = require('peak-tasks/processes')

--[[user = {
	-- id: number -- maybe?
	name: string
	groups: table(group)
	granters: table(granter)
	checkPermission: function(perm: string, ...: string): boolean
}]]

-- users.newBase(name)
-- Creates a new user that doesn't have a checkPermission function
-- IMPLEMENT IT!
function exports.newBase(name)
	local user = {
		name = name
	}

	return user
end

function exports.new(name)
	local user = exports.newBase(name)

	user.granters = {}

	function user.checkPermission(perm, ...)
		for i = 1, #user.granters do
			local res = user.granters[i](perm, ...)

			if res == true then
				return true
			elseif res == false then
				return false
			end
		end
	end

	return user
end

function exports.current()
	local process = processes.current()
	if process ~= nil then return process.user end
	-- else return root end -- TODO: Handle this case
end