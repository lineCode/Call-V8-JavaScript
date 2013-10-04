-- v8test.lua
print()
print("v8test.lua")

local ffi = require("ffi")
local js = ffi.load("v8") -- local js = require "v8"
ffi.cdef([[
	int32_t runScript( uint8_t *script, int32_t scriptSize, uint8_t *resultBuffer, int32_t resultBufferSize);
]])

local function cstr( str )
	local len = #str+1
  local typeStr = "uint8_t[" .. len .. "]"
  return ffi.new( typeStr, str ) --  #str+1 will be set to zero, null terminated string
end

local script = "'Hello ' + 'World, from Lua!'"
local scriptBuffer = cstr(script)
local scriptBufferSize = #script
local resultSize = scriptBufferSize * 2
local resultBufferSize = ffi.new("int32_t", resultSize) -- must be big enough
local resultBuffer = ffi.new("int8_t[?]", resultBufferSize)

print('js.runScript( "'..script..'", '..scriptBufferSize..', resultBuffer, '..resultSize..')')
local resultSize = js.runScript( scriptBuffer, scriptBufferSize, resultBuffer, resultSize )
local result = ffi.string(resultBuffer, resultSize)
print("javascript out: " ..  result.. ", length: " .. resultSize)
print()

