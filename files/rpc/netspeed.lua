#!/usr/bin/env lua

local argparse = require ("argparse")
local cURL = require "cURL"
local cjson = require "cjson"
local socket = require "socket"
local utils = require "vuci.utils"

local parser = argparse("netspeed", "Test your internet download and upload speed")
parser:option("-c --country", "Selected country code")
parser:option("-i --id", "Selected server id")
parser:option("--host", "Select witch server to connect by host name")
parser:flag("--getuserlocation", "Gets user Location")
parser:flag("--getserverlist", "Get server list")
parser:flag("--getbestserver", "Finds best server with lowest latency")

local args = parser:parse()

function writeServerList()
    -- open output file
    f = io.open("/tmp/serverlist.json", "w")
    serverInfo = {}
    c = cURL.easy{
    url = "https://raw.githubusercontent.com/NeilasAnta/SpeedTestServerList/main/speedtest_server_list.json"}
    :setopt_writefunction(f)
    
    c:perform()
    c:close()
    -- close output file
    f:close()
end

function readServerList()
    local lines = {}
    for line in io.lines("/tmp/serverlist.json") do
        lines[#lines + 1] = line
    end
    serverInfo =  cjson.decode(lines[1])
    return serverInfo
end

function getUserLocation()
    local results = {}

    c = cURL.easy{
        url            = "https://api.myip.com/",
        writefunction  = function(str)
            succeed = succeed or (string.find(str, "srcId:%s+SignInAlertSupressor--"))
            results.result = str
        end
    }
    c:perform()
    UserInfo =cjson.decode(results.result)

    user_data = io.open("/tmp/user_data.json", "w")
    user_data:write(cjson.encode({
        status = "Done",
        user_data = UserInfo
    }))
    io.close(user_data)
    
    local Test = cjson.encode(UserInfo)
    return UserInfo
end

function getDownloadSpeed(bestServer)
    MAXRETRIES = 10
    retries = 0
    prevdlnow = 0

    if bestServer == nil then
		sendError("Please provide a server for download speed test using", "/tmp/download_results.json")
		return
	end
    f = io.open("/dev/null", "w")

    print(string.format("\r%-10s %-35s %-15s %-15s","Download: ", "Server", "Now(MB)", "Speed, Mbps"))

    local end_time = socket.gettime()
    c = cURL.easy({
        httpheader = {
			"Cache-Control: no-cache"
		},
    })
        :setopt_url(bestServer.host.."/download")
        :setopt_useragent('Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36')
        :setopt_timeout(15)
        :setopt_connecttimeout(2)
        :setopt_accepttimeout_ms(2)
        :setopt_writefunction(f)
        :setopt_noprogress(false)
        :setopt_progressfunction(function(dltotal, dlnow)

            if retries >= MAXRETRIES then
                c:close()
            end

            end_time = socket.gettime()
            local elapsed_time = end_time - start_time
            down_speed = dlnow / (1024*1024) / elapsed_time * 8
            -- io.write(string.format("\r%-10s %-35s %-15s %-15s","", bestServer.host, dlnow/ (1024*1024), down_speed))
            down_data = io.open("/tmp/download_results.json", "w")
            down_data:write(cjson.encode({
                status = "working",
                host = bestServer.host,
                download_speed = down_speed,
                reconnect = retries
            }))

            io.close(down_data)

            if(dlnow == prevdlnow and elapsed_time > 1) then 
                retries = retries +1
            else
                retries = 0
            end

            prevdlnow = dlnow
        end)

        
    local status, error = pcall(function()
        start_time = socket.gettime()
        c:perform()  
    end)

    if error == "[CURL-EASY][BAD_FUNCTION_ARGUMENT] Error (43)" then
        sendError("Lost Internet Connection", "/tmp/download_results.json")
    end

    c:close()

    if(error == "[CURL-EASY][OPERATION_TIMEDOUT] Error (28)") then
        down_data = io.open("/tmp/download_results.json", "w")
        down_data:write(cjson.encode({
            status = "finished",
            host = bestServer.host,
            download_speed = down_speed,
            retries = retries,
            MAXRETRIESS = MAXRETRIES
        }))
        io.close(down_data)

    end


    
    f:close()
end

function getUploadSpeed(bestServer)
    MAXRETRIES = 10
    retries = 0
    prevdlnow = 0
    

    print(string.format("\n\r%-10s %-35s %-15s %-15s","Upload: ", "Server", "Now(MB)", "Speed, Mbps"))
    c = cURL.easy({

        url = bestServer.host.."/upload",
        post =true ,
        httppost = cURL.form({
            file0 = {
                file= "/dev/zero" ,
                type= "text/plain",
                name= "upload.lua"
            }
        })
    })
    :setopt_useragent('Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36')
    :setopt_timeout(11)
    :setopt_connecttimeout(2)
    :setopt_accepttimeout_ms(2)
    :setopt_noprogress(false)
    :setopt_progressfunction(function(_, _, ultotal, ulnow)

        if retries > MAXRETRIES then
            c:close()
        end

        end_time = socket.gettime()
        local elapsed_time = end_time - start_time
        upload_speed = ulnow / (1024*1024) / elapsed_time *8
        -- io.write(string.format("\r%-10s %-35s %-15s %-15s ","",bestServer.host, ulnow/ (1024*1024), upload_speed))
        
        upload_data = io.open("/tmp/upload_results.json", "w")
        upload_data:write(cjson.encode({
            status = "working",
            host = bestServer.host,
            upload_speed = upload_speed,
            reconnect = retries,
            elapsed_time = elapsed_time
        }))
        io.close(upload_data)

        if(ulnow == prevulnow and elapsed_time > 1) then 
            retries = retries +1
        else
            retries = 0
        end
        prevulnow = ulnow
    end)

    local status, error = pcall(function()
        start_time = socket.gettime()
        c:perform()
    end)

    if error == "[CURL-EASY][BAD_FUNCTION_ARGUMENT] Error (43)" then
        sendError("Lost Internet Connection", "/tmp/upload_results.json")
    end

    c:close()

    if(error == "[CURL-EASY][OPERATION_TIMEDOUT] Error (28)") then
        upload_data = io.open("/tmp/upload_results.json", "w")
        upload_data:write(cjson.encode({
            status = "finished",
            host = bestServer.host,
            upload_speed = upload_speed,
            elapsed_time = elapsed_time
        }))
        io.close(upload_data)
    end

end

function getBestServer(selectedCountry)
    f = io.open("/dev/null", "w")
    if selectedCountry == nil then
        getUserLocation()
        selectedCountry = sortByCountry(UserInfo.country)
    end

    for i=1, table.getn(selectedCountry) do

        c = cURL.easy()
        :setopt_url(selectedCountry[i].host)
        :setopt_useragent('Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36')
        :setopt_timeout(1)
        :setopt_accepttimeout_ms(1)
        :setopt_writefunction(f)

        local status, error = pcall(function()
            c:perform()
        end)

        if(c:getinfo_response_code() == 200) then
            selectedCountry[i].Latency = c:getinfo_total_time()
        end
    end
    c:close()
    for i = 1, table.getn(selectedCountry) do
        if(selectedCountry[i].Latency == nil) then
            selectedCountry[i].Latency = 1
        end
    end
    table.sort(selectedCountry, function(a,b) return a.Latency < b.Latency end)
    best_server = io.open("/tmp/best_server.json", "w")
    best_server:write(cjson.encode({
        status = "Done",
        best_server = selectedCountry[1],
    }))
    io.close(best_server)
end 

function sortByCountry(country)
    
    selectedCountry= {}
    readServerList()
    table.sort(serverInfo, function(a,b) return a.country < b.country end)
    for i=1, table.getn(serverInfo) do
        if(country == serverInfo[i].country) then
            table.insert(selectedCountry, serverInfo[i])
        end
    end
    local json = cjson.encode({
		status = "done",
		host = country,
		serverList = selectedCountry
	})
    selected_country_list = io.open("/tmp/serverlist.json", "w")
    selected_country_list:write(json)

    io.close(selected_country_list)
    return selectedCountry
end

function checkSereverStatus(server)
    serverStatus = 0
    f = io.open("/dev/null", "w")

    c = cURL.easy()
        :setopt_url(server.host)
        :setopt_useragent('Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36')
        :setopt_timeout(1)
        :setopt_accepttimeout_ms(1)
        :setopt_writefunction(f)

        local status, error = pcall(function()

            c:perform()
        end)
        
    if(c:getinfo_response_code() == 200) then
        serverStatus = 1
    else
        sendError("Selected Server is Down!", "/tmp/download_results.json")
    end
    
    c:close()
    f:close()
    return serverStatus
end

function sendError(message, jsonFile)
    error = io.open(jsonFile, "w")
            error:write(cjson.encode({
                status = "error",
                message = message
    }))
    io.close(error)
end



writeServerList()
--Requests full server list

if (args.getserverlist) then
    readServerList()
end

if (args.country) then
    sortByCountry(args.country)
end

if (args.id) then
    readServerList()
    for i = 1, table.getn(serverInfo) do
        if ( args.id == tostring(serverInfo[i].id)) then
            if (checkSereverStatus(serverInfo[i]) == 1) then
                getDownloadSpeed(serverInfo[i])
                getUploadSpeed(serverInfo[i])
            end
        end
    end
end

if (args.getuserlocation) then
    getUserLocation()
end

if (args.getbestserver) then
    getUserLocation()
    sortByCountry(UserInfo.country)
    getBestServer(selectedCountry)
end