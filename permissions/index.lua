--[=====[Peak Permissions by CoderPuppy]=====]

--[[
Idea:

so a permission is like read(fd)
probably better to just be lua code

so a user can have multiple granters
granters can give or take permissions
there would be some default ones like fs or kernel

maybe the kernel user would be better off just overriding the permission check method

so user = {
	id: number -- maybe?
	name: string
	groups: table(group)
	granters: table(granter)
	checkPermission: function(perm: string, ...: string): boolean
}

custom granters per user: Yes!
inheriting granters?: yes!
hmm inheriting granters, how?

a granter is just a function(perm, ...): boolean
if it returns nil then the checkPermission continues on to the next granter
]]