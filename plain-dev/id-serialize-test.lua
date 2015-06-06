dofile'dev/reload.lua'
local S1 = require 'common/id-serialize' (true)
local S2 = require 'common/id-serialize' ()
local t = {}
t[1] = t
local serialized = S1.to({ 1, 2, 3, t })
print(serialized)
print(S1.to(t))
local un = S2.un(serialized)
un[4][2] = un[4]
local a = S2.to(un[4])
print(a)
print(un[1], un[4] == un[4][1])
