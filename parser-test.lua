local parser = require'common/parser'
local text = [=[B15:/user/cpup/user15:/user/cpup/user15:/user/cpup/userHEYO]=]
parser(function()
	if #text == 0 then return nil end
	local ret = text:sub(1, 10)
	text = text:sub(11)
	return ret
end, function(read)
	print('type', read(1))
	print('read user', read())
	print('write user', read())
	print('execute user', read())
	print('content', read('all'))
end)
