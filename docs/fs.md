# File System API

## FS

## INode
- `mkfile()` - Make the indoe into a file
- `mkpipe()` - Make the indoe into a pipe
- `mkdir()` - Make the inode into a directory
- `exists` - Whether the inode exists
- `type` - The type of the inode (`'file'`, `'dir'`, `'pipe'` or `nil`)
- `readonly` - Whether the inode is readonly (nil if nonexistent)
- `open(mode)` - Create a handle for the inode, (`mode` can be `'r'` or `'w'`)
- `move(from)` - Move everything from `from`
- `delete()` - Delete the inode

## Handle