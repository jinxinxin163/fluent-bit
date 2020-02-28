mytable = {}

local function reportMA(pn, number, value)
	return true
end
local function haveQuota(pn, number, value)
	return true
end

function do_filter(tag, timestamp, record)
	-- generate key and timekey
    record["datacenter"] = "dc1"
    record["cluster"] = "cluster1"
    record["workspace"] = "wp1"
	datacenter = record["datacenter"]
	cluster = record["cluster"]
	workspace = record["workspace"]
	local key = datacenter .. "-" ..  cluster .. "-" .. workspace
	local timekey = "time-" .. datacenter .. "-" ..  cluster .. "-" .. workspace
	
    -- init or update counter
    if  mytable[key] == nil then
        mytable[key] = 1
		mytable[timekey] = os.time()
    else
        mytable[key] = mytable[key] + 1
    end
	
	-- report to MA
	local now = os.time()	
	if now - mytable[timekey] >= 60 then
		print("report to MA, key:", key, "value:", mytable[key])
		local pn = "xxxxxx"
		if reportMA(pn, key, mytable[key]) then
			mytable[key] = nil
			mytable[timekey] = nil
			print("report MA success")
		else 
			print("report MA fail")
		end
	end
	if haveQuota(pn, key, mytable[key]) then
		-- Record not modified so 'code' return value is 0 (first parameter)
    	return 0, 0, 0
	else
		-- drop
		return -1, 0, 0 
	end
end
