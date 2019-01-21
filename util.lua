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