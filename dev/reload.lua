for file in pairs(package.loaded) do
	if file:sub(1, 7) == 'kernel/' or file:sub(1, 7) == 'common/' or file:sub(1, 4) == 'dev/' then
		package.loaded[file] = nil
	end
end
