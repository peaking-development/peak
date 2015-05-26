return setmetatable({
	nonexistent = 'NOEXT';
	access_denied = 'NOPERM';
	wrong_type = 'WRNTYP';
	invalid_type = 'IVLDTYPE';
	invalid_mode = 'IVLDMODE';
}, {
	__index = function(self, k)
		error('Invalid error: ' .. k)
	end
})
