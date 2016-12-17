local _M = {}

-- explode(string, separator)
local explode = function(p,d)
  local t, ll
  t={}
  ll=0
  if(#p == 1) then return {p} end
    while true do
      local l=string.find(p,d,ll,true) -- find the next d in the string
      if l~=nil then -- if "not not" found then..
        table.insert(t, string.sub(p,ll,l-1)) -- Save it in our array.
        ll=l+1 -- save just after where we found it for searching next time.
      else
        table.insert(t, string.sub(p,ll)) -- Save what's left in our array.
        break -- Break at end, as it should be, according to the lua manual.
      end
    end
  return t
end

_M.sub = function(uri)
  local first, last = string.find(uri, "/sub/", 1, true)
  if not last then
    return "", {}
  end
  local sub_cut = string.sub(uri, last+1)
  first, last = string.find(sub_cut, "/", 1, true)
  if not first then
    return "", {}
  end
  local subject = string.sub(sub_cut, 1, first - 1)
  local detail = string.sub(sub_cut, last + 1)
  local details = explode(detail, ",")
  return subject, details
end

_M.pub = function(uri)
  local first, last = string.find(uri, "/pub/", 1, true)
  if not last then
    return "", {}
  end
  local pub_cut = string.sub(uri, last+1)
  return pub_cut
end

return _M
