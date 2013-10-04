-- v8test.lua
print()
print("v8test.lua")

local ffi = require("ffi")
local js
if ffi.os == "Windows" then
  js = ffi.load("libV8") -- local js = require "v8"
else
  js = ffi.load("V8") -- local js = require "v8"
end

ffi.cdef([[
	int32_t runScript( uint8_t *script, int32_t scriptSize, uint8_t *resultBuffer, int32_t resultBufferSize);
]])

local function cstr( str )
	local len = #str+1
  local typeStr = "uint8_t[" .. len .. "]"
  return ffi.new( typeStr, str ) --  #str+1 will be set to zero, null terminated string
end

local script = "'Hello ' + Math.floor((Math.random()*200)+1) + ' World, from Lua!'"
local scriptBuffer = cstr(script)
local scriptBufferSize = #script
local resultSize = scriptBufferSize * 2
local resultBufferSize = ffi.new("int32_t", resultSize) -- must be big enough
local resultBuffer = ffi.new("int8_t[?]", resultBufferSize)

print('js.runScript( "'..script..'", '..scriptBufferSize..', resultBuffer, '..resultSize..')')
local count = 10000
local time = os.clock()
local size
for i=1,count do
	size = js.runScript( scriptBuffer, scriptBufferSize, resultBuffer, resultSize )
	if i%1000 == 0 then
		print(i .." / "..count)
    local result = ffi.string(resultBuffer, size)
    print("javascript out: " ..  result.. ", length: " .. size)
	end
end
time = os.clock() - time
print()
print(string.format("elapsed time    : %.2f", time))
print(string.format("operations / sec: %.8f", count / time))
print(string.format("sec / operation : %.8f", time / count))
local result = ffi.string(resultBuffer, size)
print("javascript out: " ..  result.. ", length: " .. size)
print()

