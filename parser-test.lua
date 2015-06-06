local parser = require'common/parser'
local text = [=[F15;/user/cpup/user15;/user/cpup/user15;/user/cpup/userHEYO;]=]
local read = parser(text)
print('type', read(1))
print('read user', read())
print('write user', read())
print('execute user', read())
print('content', read('sub', 4)('all'))
