function test(mode)
	print('testing', mode)
	io.open('test', 'w'):close()
	local h = io.open('test', mode)
	h:write('hello world')
	h:seek('set')
	h:write('heyo')
	h:close()
	h = io.open('test', 'r')
	print(h:read('*a'))
	h:close()
end

test'r+'
test'w'
test'w+'
test'a'
test'a+'
