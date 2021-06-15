local _M = {}

---------------------------------------------------
-- common
---------------------------------------------------

--[[
	支持打印多种数据类型的变量
	支持返回打印的信息
	@param mixed var 变量
	@param stream out 输出方式
		stdout	: 控制台 （默认）
		ngx		: ngx.say
		log.info: ngx.log(ngx.INFO, str)
		log.err : ngx.log(ngx.ERR, str)
		callable: out(str)
]]
function _M.print(var, out)

	local function output(str)
		if out == nil or out == 'stdout' then
			print(str)
		elseif out == 'ngx' then
			ngx.say(str)
		elseif out == 'log.info' then
			ngx.log(ngx.INFO, str)
		elseif out == 'log.err' then
			ngx.log(ngx.ERR, str)
		elseif type(out) == 'function' then
			out(str)
		end
	end

	local function print_line(str, tab_size)
		tab_size = tab_size or 0
		if tab_size > 0 then
			str = string.rep("    ", tab_size) .. str
		end
		output(str)
	end

	local function print_r_internal(data, depth, prestr)
		depth = depth or 0
		prestr = prestr or ''
		if type(data) == 'table' then
			print_line(prestr .. tostring(data) .. ' {', depth)
			for k, v in pairs(data) do
				print_r_internal(v, depth + 1, '[' .. tostring(k) .. '] => ')
			end
			print_line('}', depth)
		else
			print_line(prestr .. tostring(data), depth)
		end
	end

	print_r_internal(var)

end

---------------------------------------------------
-- string extension
---------------------------------------------------

--[[
	字符串切割
	@param string str 字符串
	@param string delimiter 分隔符
]]
function string.split(str, delimiter)
	local list = {}
	string.gsub(str, '[^'.. delimiter .. ']*', function(val)
		if string.len(val) > 0 then
			table.insert(list, val)
		end
	end)
	return list
end

--[[
	清除首尾的空白字符
	@param string str
]]
function string.trim(str)
	return (str:gsub("^%s*(.-)%s*$", "%1"))
end

-- 计算一个字符的字节长度
local function utf8_charsize(ch)
	if not ch then return 0
	elseif ch >=252 then return 6
	elseif ch >= 248 and ch < 252 then return 5
	elseif ch >= 240 and ch < 248 then return 4
	elseif ch >= 224 and ch < 240 then return 3
	elseif ch >= 192 and ch < 224 then return 2
	elseif ch < 192 then return 1
	end
end


--[[
	计算utf8字符串的长度
	@param string ch
	@return int
]]
function string.utf8len(str)

	local len = 0
	local aNum = 0 --字母个数
	local hNum = 0 --汉字个数
	local currentIndex = 1
	while currentIndex <= #str do
		local char = string.byte(str, currentIndex)
		local cs = utf8_charsize(char)
		currentIndex = currentIndex + cs
		len = len +1
		if cs == 1 then
			aNum = aNum + 1
		elseif cs >= 2 then
			hNum = hNum + 1
		end
	end
	return len, aNum, hNum
end

--[[
	截取utf8 字符串
	str			: 要截取的字符串
	startChar	: 开始字符下标,从1开始
	numChars	: 要截取的字符长度
]]
function string.utf8sub(str, startChar, numChars)
	local startIndex = 1
	while startChar > 1 do
		local char = string.byte(str, startIndex)
		startIndex = startIndex + utf8_charsize(char)
		startChar = startChar - 1
	end

	local currentIndex = startIndex

	while numChars > 0 and currentIndex <= #str do
		local char = string.byte(str, currentIndex)
		currentIndex = currentIndex + utf8_charsize(char)
		numChars = numChars -1
	end
	return str:sub(startIndex, currentIndex - 1)
end

--[[
	字符串切片
	str		: 要截取的字符串
	length	: 切片长度
]]
function string.utf8slice(str, length)
	local list = {}

	local start = 1
	local len = string.utf8len(str)

	while len > 0 do
		table.insert(list, string.utf8sub(str, start, length))
		start = start + length
		len = len - length
	end

	return list

end

---------------------------------------------------
-- table extension
---------------------------------------------------

--[[
	获取table的所有键名
	@param table t
]]
function table.keys( t )
	if type(t) ~= 'table' then
		return nil, 'type(table) is supported'
	end
    local keys = {}
    local idx = 1
    for k, _ in pairs( t ) do
        keys[idx] = k
        idx = idx + 1
    end
    return keys, nil
end

--[[
	table继承，将src数据合并到dest，键名相同时覆盖
	数字类型的键值不会覆盖，变为追加

	@param table dest 被合并的table
	@param table src 合并的table
	@param bool depth 深度合并标识, 默认为false
	@return table,string
]]
function table.extend(dest, src, depth)
	depth = depth == nil and false or true
	if type(dest) ~= 'table' then
		return nil, "arguments#1 must a table value(" .. type(dest) .. " given)"
	end
	if type(src) ~= 'table' then
		return nil, "arguments#2 must a table value(" .. type(src) .. " given)"
	end
	for k, v in pairs(src) do
		if depth and type(dest[k]) == 'table' and type(v) == 'table' then
			local tmp = dest[k]
			local ok, err = table.extend(tmp, v, depth)
			if ok then
				dest[k] = tmp
			else
				return nil, err
			end
		elseif type(k) == 'number' then
			-- 数字类型的键值不会覆盖
			table.insert(dest, v)
		else
			dest[k] = v
		end
	end
	return dest, nil
end





return _M