local FS = require 'common/fs'
local E = require 'common/error'
local Promise = require 'common/promise'
local buffer = require 'common/buffer'

local function new_node(typ)
	local node = {
		type = typ;
		perms = {};
	}
	if typ == 'folder' then
		node.children = {}
	elseif typ == 'file' then
		node.data = ''
	end
	return node
end

return function()
	local data = new_node('folder')

	local function find(path, typ, create)
		local curr = data
		for i, part in ipairs(path) do
			if curr.children[part] then
				curr = curr.children[part]
				if i == #path and typ and curr.type ~= typ then
					error({E.wrong_type, typ, curr.type})
				end
			elseif create then
				local child = new_node(typ)
				child.parent = curr
				curr.children[part] = child
				curr = child
			else
				return
			end
		end
		return curr
	end

	return FS(function(path, op, ...)
		local pd = find(path)
		return (({
			stat = function()
				if pd then
					return Promise.resolved(true, {
						exists = true;
						type = pd.type;
					})
				else
					return Promise.resolved(true, { exists = false; })
				end
			end;

			open = function(opts)
				local h = {}
				if opts.type == 'file' then
					buffer(h, function(d)
						if d then
							pd.data = d
						else
							return pd.data
						end
					end, opts.write)
				elseif opts.type == 'folder' then
					local last, done
					function h.read()
						if done then return Promise.resolved(true, nil) end
						last = next(pd.children, last)
						if last == nil then
							done = true
						end
						return Promise.resolved(true, last)
					end
				end
				return Promise.resolved(true, h)
			end;

			create = function(opts)
				if opts.type ~= 'file' and opts.type ~= 'folder' then
					return Promise.resolved(false, E.invalid_type, opts.type)
				end
				local folder = find({table.unpack(path, 1, #path - 1)}, 'folder')
				local node = new_node(opts.type)
				folder.children[path[#path]] = node
				return Promise.resolved(true)
			end;
		})[op] or error('unhandled operation: ' .. tostring(op)))(...)
	end)
end
