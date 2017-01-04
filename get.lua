local _M = {}

local cuturl = require("cuturl")
local util = require("util")

local get_and_sub = function(redis, subject, details)
  -- atomically (wrapped in multi+exec) read state for [details] keys in $subject
  -- NOTE: This leaves redis in a SUBSCRIBE state - use redis:read_reply() to read
  local initial_states = {}
  redis:multi()
  for i = 1, #details do
    -- queue up GETs in multi
    redis:get(details[i])
  end
  for i = 1, #details do
    -- list subscriptions
    redis:subscribe(details[i])
  end
  -- exec queued items
  local queued_items = redis:exec()
  for i = 1, #details do
    -- pull out the responses to the GETs
    initial_states[i] = queued_items[i]
  end
  return initial_states
end

_M.subscribe = function(redis)

  -- subject - the namespace
  -- details - the list of ids being subscribed to within the namespace
  local subject, details = cuturl.sub(ngx.var.uri)
  for i = 1, #details do
    details[i] = subject .. "/" .. details[i]
  end
  local initial_states = get_and_sub(redis, subject, details)
  for i = 1, #initial_states do
    ngx.say(initial_states[i])
  end
  ngx.flush()
  
  local err = nil
  local res

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

_M.poll = function(redis)
  
  -- subject - the namespace
  -- details - the list of ids being subscribed to within the namespace
  local subject, details = cuturl.sub(ngx.var.uri)
  for i = 1, #details do
    details[i] = subject .. "/" .. details[i]
  end
  local initial_states = get_and_sub(redis, subject, details)
 
  local content_etag = util.calc_md5(initial_states)
  local consumer_etag = ngx.var.http_if_none_match

  -- do etags match? if yes then already have this, wait for the next thing and send just it
  -- not match? send what we have with a tag
  -- 
  if content_etag ~= consumer_etag then
    ngx.header["ETag"] = content_etag
    -- we differ from consumer, send our state
    for i = 1, #initial_states do
      -- pull out the responses to the GETs
      if initial_states[i] ~= ngx.null then
        if i == #initial_states then
          ngx.print(initial_states[i])
        else
          ngx.say(initial_states[i])
        end
      end
    end
    ngx.flush()
  else
    -- we match consumer, wait for state change
    local err, res
    while not err do
      res, err = redis:read_reply()
      if not err then
        util.override_arraypair(details, initial_states, res[2], res[3])
        local upd_etag = util.calc_md5(initial_states)
        ngx.header["ETag"] = upd_etag
        ngx.say(res[3])
        break
      else
        if err == "timeout" then
          -- nginx will set the status to 304 here due to matching ETag
          ngx.header["ETag"] = consumer_etag
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
end

return _M
