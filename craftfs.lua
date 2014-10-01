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
						local content = ''
						local ch = cfs.open(fn(path, fn.arr.join('/')), mode)

						function handle.read(length)
							length = (type(length) == 'string' or type(length) == 'number') and length or '*l'
							local remaining = content:sub(handle.offset)

							if length == '*l' then
								while remaining:find('\n', 1, true) == nil do
									local data = ch.readLine()
									if #data == 0 then
										break
									end
									content = content .. data .. '\n'
									remaining = content:sub(handle.offset)
									--print(remaining, ', ', content, ', ', handle.offset)
								end

								local nl = remaining:find('\n', 1, true)

								if nl then
									return remaining:sub(1, nl - 1)
								else
									return remaining
								end
							elseif length == '*a' then
								return remaining .. ch.readAll()
							elseif type(length) == 'number' then
								while #remaining < length do
									content = content .. ch.readLine()
									remaining = content:sub(handle.offset)
								end

								return remaining:sub(1, length)
							end
						end

						function handle.close()
							ch.close()
						end

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

				function inode.release() end
			end
			regen()
			return inode
		end
		return fs
	end
end