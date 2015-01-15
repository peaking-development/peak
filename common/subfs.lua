return function(fs, subpath)
	return function(path, ...)
		return fs({table.unpack(subpath), table.unpack(path)}, ...)
	end
end