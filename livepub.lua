local _M = {}

_M.subscribe = function(redis)
  local res, err = redis:get("snapshot:scores")
  if res ~= ngx.null then
    ngx.say(res)
    ngx.flush()
  end
  redis:subscribe("delta:scores")
  while not err do
    res, err = redis:read_reply()
    if res then
      ngx.log(ngx.ERR, "subject is " .. res[2])
      ngx.log(ngx.ERR, "details is " .. res[3])
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

_M.delta = function(redis)
  ngx.req.read_body()
  local body_data = ngx.req.get_body_data()
  redis:publish("delta:scores", body_data)
end

_M.snapshot = function(redis)
  ngx.req.read_body()
  local body_data = ngx.req.get_body_data()
  redis:set("delta:snapshot", body_data, "ex", 60*20)
end

return _M
