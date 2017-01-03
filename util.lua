local resty_md5 = require "resty.md5"
local resty_str = require "resty.string"

local _M = {}


_M.override_arraypair = function(names, values, override_name, override_value)
  -- {{'aaa', 'bbb'}, {123, 456}, 'bbb', 789} => overrides {123, 456} to {123, 789}
  for i = 1, #values do
    if names[i] == override_name then
      values[i] = override_value
    end
  end
end

_M.calc_md5 = function(values)
  -- calculate md5 for set of values
  local md5 = resty_md5:new()
  for i = 1, #values do
    if values[i] ~= ngx.null then
      md5:update(values[i])
    end
  end
  local digest = md5:final()
  return resty_str.to_hex(digest)
end

return _M
