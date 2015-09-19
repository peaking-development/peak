wait(K.close(wait(K.open({'oc-bus'}, {
	type = 'folder';
	create = true;
}))))

local fd = wait(K.open({'oc-signal-bus'}, {
	type = 'stream';
}))

while true do
	local ev = table.pack(wait(K.read(fd)))
	if ev[1] == 'component_added' then
		wait(K.close(wait(K.open({'oc-bus', ev[2]}, {
			type = 'folder';
			create = true;
		}))))
		wait(K.x
end
