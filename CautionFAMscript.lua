script_name('CautionFAM Helper')
script_author('Marlon')
script_description('helper')





require 'lib.moonloader'

local dlstatus = require('moonloader').download_status

local broadcaster = import('lib/broadcaster.lua')

local copas = require 'copas'
local http = require 'copas.http'

local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8

local ffi = require("ffi")
ffi.cdef[[
    int __stdcall GetVolumeInformationA(
    const char* lpRootPathName,
    char* lpVolumeNameBuffer,
    uint32_t nVolumeNameSize,
    uint32_t* lpVolumeSerialNumber,
    uint32_t* lpMaximumComponentLength,
    uint32_t* lpFileSystemFlags,
    char* lpFileSystemNameBuffer,
    uint32_t nFileSystemNameSize
    );
]]

local inicfg = require 'inicfg'
local directIni = 'CautionFAM.ini'
local ini = inicfg.load(inicfg.load({
    main = {
        room = 'SOS',
        debug = false,
        ignore = false,
        myColor = '{ff004d}',
        colorIndex = 2,
        showSosTag = true,
    },
}, directIni))
inicfg.save(ini, directIni)

local room = ini.main.room
local DEBUG = ini.main.debug
local ignore = ini.main.ignore
local colorIndex = ini.main.colorIndex
local showSosTag = ini.main.showSosTag

function save()
    ini.main.room = room
    ini.main.debug = DEBUG
    ini.main.ignore = ignore
    ini.main.colorIndex = colorIndex
    inicfg.save(ini, directIni)
end

local ipblue = '54.37.142.74:7777'

local tag = '{e3cc1b}[CautionFAM]{FFFFFF} - '

local main_color = 0xFFFFFF
local second_color = 0xe3cc1b
local yellow_color = 0xddf21b
local bluelight_color = 0x1b7fe3

local main_color_text = '{FFFFFF}'
local second_color_text = '{e3cc1b}'
local yellow_color_text = '{ddf21b}'
local bluelight_color_text = '{1b7fe3}'

update_state = false

local script_vers = 2
local script_vers_text = "1.01"

local update_url = "https://raw.githubusercontent.com/Marlon000/scripts/main/update.ini" -- òóò òîæå ñâîþ ññûëêó
local update_path = getWorkingDirectory() .. "/update.ini" -- è òóò ñâîþ ññûëêó

local script_url = "https://raw.githubusercontent.com/Marlon000/scripts/main/CautionFAMscript.lua" -- òóò ñâîþ ññûëêó
local script_path = thisScript().path

function main()

	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(100) end

	CHECKERFORSCRIPT()

	wait(1000)

	downloadUrlToFile(update_url, update_path, function(id, status)
			if status == dlstatus.STATUS_ENDDOWNLOADDATA then
				-updateIni = inicfg.load(nil, update_path)
					if tonumber(updateIni.info.vers) > script_vers then
							sampAddChatMessage(tag .. "Íàéäåíî îáíîâëåíèå! Âåðñèÿ: " .. updateIni.info.vers_text, main_color)
							update_state = true
					end
					os.remove(update_path)
			end
	end)

	while true do
		wait(0)

		if update_state then
				downloadUrlToFile(script_url, script_path, function(id, status)
						if status == dlstatus.STATUS_ENDDOWNLOADDATA then
								sampAddChatMessage(tag .. "Ñêðèïò áûë óñïåøíî îáíîâëåí! Ñåé÷àñ âûïîëíèòñÿ ïåðåçàãðóçêà ñêðèïòà.", main_color)
								thisScript():reload()
						end
				end)
				break
		end

	end
end

function cmd_update(arg)
    sampShowDialog(1000, "Àâòîîáíîâëåíèå v2.0", "{FFFFFF}Ýòî óðîê ïî îáíîâëåíèþ\n{FFF000}Íîâàÿ âåðñèÿ", "Çàêðûòü", "", 0)
end

function httpRequest(request, body, handler) -- copas.http -- ÔÓÍÊÖÈß HTTP ÇÀÏÐÎÑÀ
    -- start polling task
    if not copas.running then
        copas.running = true
        lua_thread.create(function()
            wait(0)
            while not copas.finished() do
                local ok, err = copas.step(0)
                if ok == nil then error(err) end
                wait(0)
            end
            copas.running = false
        end)
    end
    -- do request
    if handler then
        return copas.addthread(function(r, b, h)
            copas.setErrorHandler(function(err) h(nil, err) end)
            h(http.request(r, b))
        end, request, body, handler)
    else
        local results
        local thread = copas.addthread(function(r, b)
            copas.setErrorHandler(function(err) results = {nil, err} end)
            results = table.pack(http.request(r, b))
        end, request, body)
        while coroutine.status(thread) ~= 'dead' do wait(0) end
        return table.unpack(results)
    end
end

function getSerialNumber() -- ïîëó÷åíèå ñåðèéíèêà
    local serial = ffi.new("unsigned long[1]", 0)
    ffi.C.GetVolumeInformationA(nil, nil, 0, serial, nil, nil, nil, 0)
    return serial[0]
end

function checkipserver() -- ïðîâåðêà ip ñåðâåðà
    local ip, port = sampGetCurrentServerAddress()
        if ipblue == ip..':'..port then
            if ipblue == '54.37.142.74:7777' then
                servername = key
                return true
            end
        end
    return false
end

function CHECKERFORSCRIPT()
	httpRequest('https://text-host.ru/raw/bez-zagolovka-1365', nil, function(response, code, headers, status)
			if response then
				if not response:find(getSerialNumber() .. ',') then
					sampAddChatMessage(tag .. 'Åáàòü òû ÷îðò ïàøîë íàõóé', main_color)
					thisScript():unload()
				end
			end
	end)

	if not checkipserver() then
  	sampAddChatMessage(tag .. 'Äàííûé ñêðèïò ïðèâÿçàí ê ñåðâåðó ' .. bluelight_color_text .. 'Advance RP BLUE' .. main_color_text .. '. Ïðîèçîøëà âûãðóçêà.', main_color)
    thisScript():unload()
  else
		sampAddChatMessage(tag .. 'Ñêðèïò áûë óñïåøíî çàãðóæåí.', main_color)
  end
end
