dofile'dev/reload.lua'
local S = require 'common/id-serialize'
local t = {}
t[1] = t
local serialized = S.to({ 1, 2, 3, t })
print(serialized)
local un = S.un(serialized)
print(un[1], un[4] == un[4][1])
