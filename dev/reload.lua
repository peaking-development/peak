print 'reloading'
for file in pairs(package.loaded) do
	if file:sub(1, 7) == 'kernel/' or file:sub(1, 7) == 'common/' or file:sub(1, 4) == 'dev/' or file:sub(1, 3) == 'oc/' then
		package.loaded[file] = nil
		print('reloaded ' .. file)
	end
end
