local util = require 'common/util'

return function(fs, subpath)
	return function(path, ...)
		return fs(util.concat(subpath, path), ...)
	end
end
