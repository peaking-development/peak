local fn = require('./fn')
fn.arr = require('./fn/arr')
fn.str = require('./fn/str')

return function(mounts)
	mounts = type(mounts) == 'table' and mounts or {}

	return function(kernel)
		local self = {}

		self.mounts = {}
		function self.mount(path, fs)
			if type(self.mounts[path]) ~= 'table' then self.mounts[path] = {} end
			local mounts = self.mounts[path]
			if fn(mounts, fn.arr.indexOf(fs)) == -1 then
				mounts[#mounts + 1] = fs
				--print('mounting something: ' .. tostring(fs))
				--print(table.concat(path, '/') .. ': ' .. #mounts)
				--print(textutils.serialize(mounts))
				--for k, v in pairs(self.mounts) do print(table.concat(k, '/') .. ': ' .. #v) end
			else
				error('mountfs.mount(): Already mounted here', 2)
			end
		end
		function self.unmount(path, fs)
			if fs == nil then
				self.mounts[path] = nil
				return true
			end
			local mounts = self.mounts[path]
			if type(mounts) ~= 'table' then return false, 'Not mounted there' end
			local index = fn(mounts, fn.arr.indexOf(fs))
			if index == -1 then
				return false, 'Not mounted there'
			else
				table.remove(mounts, index)
				return true
			end
		end

		function self.get(path)
			local pathStr = fn(path, fn.arr.join('/'))
			for mountPath, mounts in pairs(self.mounts) do
				local mountPathStr = fn(mountPath, fn.arr.join('/'))
				if pathStr:sub(0, #mountPathStr) == mountPathStr then
					local subPathStr = pathStr:sub(#mountPathStr)
					local subPath = fn(subPathStr, fn.str.split('/', true))
					local inode
					for _, mount in ipairs(mounts) do
						inode = mount.get(subPath)
						print(subPathStr, inode.exists)
						if inode.exists then
							if #subPath == 0 then
								function inode.delete()
									self.unmount(mountPath)
								end
							end
							return inode
						end
					end
				end
			end
		end

		return self
	end
end