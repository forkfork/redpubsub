local _M = {}

local cuturl = require("cuturl")

_M.subscribe = function(redis)

  local subject, details = cuturl.sub(ngx.var.uri)

  redis:multi()
  for i = 1, #details do
    redis:get(details[i])
  end
  for i = 1, #details do
    redis:subscribe(details[i])
  end
  local initial_states = redis:exec()
  for i = 1, #details do
    ngx.say(initial_states[i])
  end
  ngx.flush()
  local err = nil
  local res

  while not err do
    res, err = redis:read_reply()
    if res then
      ngx.say(res[3])
      ngx.flush()
    else
      if err == "timeout" then
        ngx.log(ngx.ERR, "TIMEOUT")
        break
      else
        ngx.log(ngx.ERR, "OTHER ERROR")
        ngx.log(ngx.ERR, err)
        break
      end
    end
  end

end

return _M
