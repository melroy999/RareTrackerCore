-- Redefine often used functions locally.
local floor = floor

-- The characters to be used in the base64 string.
local digits = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- A cheat sheet used to easily convert back to decimal.
local inverse_map = {}
for i = 1, #digits do
	local c = digits:sub(i,i)
	inverse_map[c] = i - 1
end

-- Convert a decimal number to a base64 string.
function RT.toBase64(number)
    local t = {}
	
	if number < 0 then
		number = 0
	end
	
    repeat
        local d = (number % 64) + 1
        number = floor(number / 64)
        table.insert(t, 1, digits:sub(d, d))
    until number == 0
	
    return table.concat(t, "")
end

-- Convert a decimal number to a base64 string.
function RT.toBase10(base64)
	local n = 0
	local j = 1
	
	for i = 1, #base64 do
		local k = #base64 - i + 1
		local c = base64:sub(k, k)
		n = n + j * inverse_map[c]
		j = j * 64
	end
	
	return n
end