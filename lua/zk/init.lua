local zk = {}

zk.default_config = {}

local extend_config = function(opts)
  opts = opts or {}
  if next(opts) == nil then
    return
  end
  for key, value in pairs(opts) do
    if zk.default_config[key] == nil then
      error(string.format("[Zk] Key %s does not exist in config values", key))
      return
    end
    if type(zk.default_config[key]) == "table" then
      for k, v in pairs(value) do
        zk.default_config[key][k] = v
      end
    else
      zk.default_config[key] = value
    end
  end
end

function zk.init(opts)
  extend_config(opts)
end

return zk
