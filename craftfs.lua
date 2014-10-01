local fn = require('./fn')
fn.arr = require('./fn/arr')

return function(cfs)
	return function(kernel)
		local fs = {}
		function fs.get(path)
			local inode = {
				fs = fs;
				path = path;
			}
			local strPath = fn(path, fn.arr.join('/'))
			local function regen()
				inode.exists = cfs.exists(strPath)
				if inode.exists then
					if cfs.isDir(strPath) then
						inode.type = 'dir'
					else
						inode.type = 'file'
					end

					inode.readonly = cfs.isReadOnly(strPath)

					function inode.open(mode)
						local handle = {
							fs = fs;
							inode = inode;
							path = path;
							offset = 0;
						}
						local ch = cfs.



						return handle
					end

					function inode.mkdir()
						error('inode.mkdir(): ' .. strPath .. ' already exists', 2)
					end
				else
					inode.type = nil
					inode.readonly = nil

					function inode.mkdir()
						local ok, res = pcall(cfs.makeDir, strPath)
						if ok then
							regen()
						else
							error('inode.mkdir(): ' .. res, 2)
						end
					end
				end
			end
			regen()
			return inode
		end
		return fs
	end
end