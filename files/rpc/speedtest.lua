local cjson = require "cjson"
local utils = require "vuci.utils"
local socket = require "socket"

local M = {}

function M.start_test(params)

    os.execute("rm /tmp/download_results.json")
    os.execute("rm /tmp/upload_results.json")
    local cmd = "netspeed.lua"
    if params.country ~= nil then
        cmd = cmd .." -c "..params.country
    end
    if params.id ~= nil then
        cmd = cmd .." --id "..params.id
    end
    io.popen(cmd)
    return {message = "Test Started"}
end

function M.get_server_list(params)
    cmd = ""
    os.execute("rm /tmp/serverList.json")
    local serverList = {}
    if params.country then
        cmd ="netspeed.lua -c " ..params.country 
        os.execute(cmd)   
    else 
        cmd = "netspeed.lua --getserverlist"
        os.execute(cmd)
    end
		serverList = cjson.decode(utils.readfile("/tmp/serverlist.json"))
    return {status = "ok", serverList = serverList, message = "List rendered", cmd = cmd } 
end

function M.get_user_info (params)
    cmd = "netspeed.lua --getuserlocation"
    os.execute(cmd)
    local userData = cjson.decode(utils.readfile("/tmp/user_data.json"))

    return {ok = true,data = userData, message = "User info sent"}
end

function M.get_test_results()
    file = utils.readfile("/tmp/download_results.json")
    if(file == nil or file == "") then
			return{status = "error", message = "Test failed, check your internet connection and try again"}
		end
    downloadResults = cjson.decode( file )
    if(downloadResults.status == "finished") then
      up_file = utils.readfile("/tmp/upload_results.json")
      if(up_file ~= nil and up_file ~= "") then
        uploadResults = cjson.decode(up_file)
      end
			return {status = "ok", download_results = downloadResults, upload_results = uploadResults}
    end
		return {status = "ok", download_results = downloadResults}
    
end

function M.get_best_server()
    cmd = "netspeed.lua --getbestserver"
    os.execute(cmd)
    local bestServer = cjson.decode(utils.readfile("/tmp/best_server.json"))
    return {status = "ok", best_server_info = bestServer}
end

return M