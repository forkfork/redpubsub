local _M = {}

local cuturl = require("cuturl")

_M.publish = function(redis)

  local subject = cuturl.pub(ngx.var.uri)

  ngx.req.read_body()
  local body_data = ngx.req.get_body_data()
  redis:multi()
  redis:set(subject, body_data)
  redis:publish(subject, body_data)
  redis:exec()  
end

return _M
