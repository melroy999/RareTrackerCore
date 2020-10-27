-- Redefine often used functions locally.
local floor = floor

-- Redefine often used variables locally.
local table = table

-- The characters to be used in the base64 string.
local digits = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local base = #digits

-- A cheat sheet used to easily convert back to decimal.
local inverse_map = {}
for i = 1, #digits do
	local c = digits:sub(i,i)
	inverse_map[c] = i - 1
end

-- Convert a decimal number to a base64 string.
function RareTracker:ToBase64(number)
    local t = {}
	
	if number < 0 then
		number = 0
	end
	
    repeat
        local d = (number % base) + 1
        number = floor(number / base)
        table.insert(t, 1, digits:sub(d, d))
    until number == 0
	
    return table.concat(t, "")
end

-- Convert a decimal number to a base64 string.
function RareTracker:ToBase10(base64)
	local n = 0
	local j = 1
	
	for i = 1, #base64 do
		local k = #base64 - i + 1
		local c = base64:sub(k, k)
		n = n + j * inverse_map[c]
		j = j * base
	end
	
	return n
end