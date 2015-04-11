--[[

	Script Name: iSwearSheWasKassadin
	Author: iSwearSheWas18
	Current Version: 0.01
	11.04.2015

]]--

if myHero.charName ~= "Kassadin" then return end
local autoupdate = true -- u can turn it off, if u don't want autoupdates
local version = 0.02

-- Required Libs
if FileExist(LIB_PATH .. "/SxOrbWalk.lua") then
	require("SxOrbWalk")
end
if FileExist(LIB_PATH .. "/VPrediction.lua") then
	require("VPrediction")
	VP = VPrediction()
end

-- Spell Information
local Qspell = {name = "Null Sphere", speed = 1400, range = 650, delay = 0.25, width = 60, Ready = function() return myHero:CanUseSpell(_Q) == READY end}
local Wspell = {name = "Nether Blade", range = 150, delay = nil, Ready = function() return myHero:CanUseSpell(_W) == READY end}
local Espell = {name = "Force Pulse", speed = nil, angle = 80, delay = 0.25, range = 700, Ready = function() return myHero:CanUseSpell(_E) == READY end}
local Rspell = {name = "Riftwalk", speed = nil, range = 500, delay = 0.25, width = 200, Ready = function() return myHero:CanUseSpell(_R) == READY end}
local Ignite = nil
local Melee = 150
local enemyMinions = minionManager(MINION_ENEMY, Qspell.range, myHero, MINION_SORT_MAXHEALTH_DEC)

-- CheckUpdate by Aroc

function CheckUpdate()
    if autoupdate then
        local scriptName = "iSwearSheWasKassadin"
        local ToUpdate = {}
        ToUpdate.Version = version
        ToUpdate.UseHttps = true
        ToUpdate.Host = "raw.githubusercontent.com"
        ToUpdate.VersionPath = "/iSwearSheWasEighteen/bol/master/version/"..scriptName..".version"
        ToUpdate.ScriptPath = "/iSwearSheWasEighteen/bol/master/"..scriptName..".lua"
        ToUpdate.SavePath = SCRIPT_PATH.._ENV.FILE_NAME
        ToUpdate.CallbackUpdate = function(NewVersion,OldVersion) PrintMessage("Updated to "..NewVersion..". Please reload with 2x F9.") end
        ToUpdate.CallbackNoUpdate = function(OldVersion) PrintMessage("No Updates Found.") end
        ToUpdate.CallbackNewVersion = function(NewVersion) PrintMessage("New Version found ("..NewVersion..").") end
        ToUpdate.CallbackError = function(NewVersion) PrintMessage("Error while downloading.") end
        _ScriptUpdate(ToUpdate.Version, ToUpdate.UseHttps, ToUpdate.Host, ToUpdate.VersionPath, ToUpdate.ScriptPath, ToUpdate.SavePath, ToUpdate.CallbackUpdate,ToUpdate.CallbackNoUpdate, ToUpdate.CallbackNewVersion,ToUpdate.CallbackError)
    end
end
function PrintMessage(message) 
    print("<font color=\"#6699ff\"><b>" .. scriptName .. ":</b></font> <font color=\"#FFFFFF\">" .. message .. "</font>") 
end


-- OnLoad Function
function OnLoad()
	Menu()
	DelayAction(function() CheckUpdate() end, 0.1)
	print("<b><font color=\"#FF0000\">iSwearSheWasKassadin:</font></b> <font color=\"#FFFFFF\">Script is in alpha!</font>")

end

-- OnTick Function
function OnTick()
	SelectedTarged = TargetSelector.target
	Check()
	-- Combo
	if Cel ~= nil and MenuKassadin.combocfg.docombo then
		SxOrb:EnableAttacks()
		Combo()
	end
	-- Harrass
	if Cel ~= nil and MenuKassadin.harrascfg.doharras then
		Harrass()
	end
	-- LaneClear
	if MenuKassadin.clearlane.dolaneclear then
		Clear()
	end
	--ignite
	if Ignite ~= nil and MenuKassadin.itemcfg.aIgnite then
		UseIgnite()
	end
	-- autozhonyas
	if (MenuKassadin.itemcfg.aZhon and GetInventorySlotItem(3157) ~= nil) then
		UseZhonyas()
	end
	-- auto seraphs
	if (MenuKassadin.itemcfg.aSeraph and GetInventorySlotItem(3040) ~= nil) then
		UseSeraphs()
	end

end

-- Function GetTarget() cause integrate SAC:R
function GetTarget()
	TargetSelector:update()
	if SxOrbloaded then return SxOrb:GetTarget(Qspell.range) end 
	return TargetSelector.target
end

-- Function check
function Check()
	if SelectedTarget ~= nil and ValidTarget(SelectedTarget, Qspell.range) then
		Cel = SelectedTarget
	else 
		Cel = GetTarget()
	end
	SxOrb:ForceTarget(Cel)
end

-- Function CastQ 
function CastQ(unit)
	if Qspell.Ready() and ValidTarget(unit, Qspell.range) then
		CastSpell(_Q, unit)
	end
end

-- Function CastW and ValidTartget(unit, Wspell.range+50)
function CastW(unit)
	if Wspell.Ready() and ValidTarget(unit, Wspell.range+50) then
		CastSpell(_W)
	end
end

-- Function CastE
function CastE(unit)
	if Espell.Ready() and ValidTarget(unit, Espell.range) then
		mainCastPosition, mainHitChance, maxHit = VP:GetConeAOECastPosition(unit, Espell.delay, Espell.angle, Espell.range, Espell.speed, myHero)
		if mainHitChance >=2 then
			CastSpell(_E, mainCastPosition.x, mainCastPosition.z)
		end
	end 
end
-- Function CastR
function CastR(unit)
	if Rspell.Ready() and ValidTarget(unit, Rspell.range) then
		Position, HitChance    = VP:GetPredictedPos(unit, Rspell.delay, Rspell.speed, myHero, false)
			if HitChance >= 2 and GetDistance(Position) <= Rspell.range then -- and TowerDive() then
				CastSpell(_R, Position.x, Position.z)
				-- CastW directly
				CastSpell(_W)
		end
	end
end

-- Function Harras Enemy
function Harrass()
	if MenuKassadin.harrascfg.HMode == 1 and ((myHero.mana/myHero.maxMana)*100) >= MenuKassadin.harrascfg.harrasmana then
		CastQ(Cel)
	end
	if MenuKassadin.harrascfg.HMode == 2 and ((myHero.mana/myHero.maxMana)*100) >= MenuKassadin.harrascfg.harrasmana then
		CastE(Cel)
	end
	if MenuKassadin.harrascfg.HMode == 3 and ((myHero.mana/myHero.maxMana)*100) >= MenuKassadin.harrascfg.harrasmana then
		CastQ(Cel)
		CastE(Cel)
	end
	
end

-- Function Combo
function Combo()
	if myHero.dead then return end
	if MenuKassadin.combocfg.useR and Rspell.Ready() then
		CastR(Cel)
	end
	if MenuKassadin.combocfg.useW and Wspell.Ready() then
		CastW(Cel)
		SxOrb:ForceTarget(Cel)
	end
	if MenuKassadin.combocfg.useE and Espell.Ready() then
		CastE(Cel)
	end 
	if MenuKassadin.combocfg.useQ and Qspell.Ready() then
		CastQ(Cel)
	end
end

--[[ Enable or Disable Autoattacks
function doAA()
		if MenuKassadin.combocfg.useAA then
			SxOrb:EnableAttacks()
		elseif not MenuKassadin.combocfg.useAA then
			SxOrb:DisableAttacks()
		end
end --]]

-- Function Auto Zhonyas
function UseZhonyas()
	local Slot = GetInventorySlotItem(3157)
		if Slot ~= nil and myHero:CanUseSpell(Slot) == READY then
			if ((myHero.health/myHero.maxHealth)*100) <= MenuKassadin.itemcfg.aZhonlife then
				CastSpell(Slot)
			end
		end
end

-- Function Auto Seraph's Embrace
function UseSeraphs()
	local Slot = GetInventorySlotItem(3040)
	if Slot ~= nil and myHero:CanUseSpell(Slot) == READY then
			if ((myHero.health/myHero.maxHealth)*100) <= MenuKassadin.itemcfg.aSeraphlife then
				CastSpell(Slot)
			end
	end
end

-- Autoignite
function UseIgnite()
	local igniteDmg = (70 + (20 * myHero.level))
	if myHero:CanUseSpell(Ignite) == READY then
		for _, enemy in ipairs(GetEnemyHeroes()) do
			local health = enemy.health
			if ( enemy ~= nil and GetDistance(enemy, myHero) <= 600 and ValidTarget(enemy, 600) and health <= igniteDmg) then
				if MenuKassadin.itemcfg.IgniteOverkill then
					if myHero.level >= 6 then
						if CheckIgniteOverkill(enemy) then
							CastSpell(Ignite, enemy)
						print("check hat funktioniert")
						end
					else
						CastSpell(Ignite, enemy)
					end
				else
					CastSpell(Ignite, enemy)
					--print("du bist im else")
				end
			end
		end
	end
end

-- IgniteOverkill

function CheckIgniteOverkill(unit)
	if (GetDistance(unit, myHero) >= (Qspell.range-100) and not Rspell.Ready() and not Qspell.Ready() and not Espell.Ready()) then
		return true
	else
		return false
	end
end

-- LaneClear
function Clear()
	enemyMinions:update()
	for j, minion in pairs(enemyMinions.objects) do
		if ((myHero.mana/myHero.maxMana)*100) >= MenuKassadin.clearlane.clearmana then
			if MenuKassadin.clearlane.useQF then
				CastQ(minion)
				print("Update klappt")
			end
			if MenuKassadin.clearlane.useWF and GetDistance(minion, myHero) <= Wspell.range then
				CastW(minion)
				SxOrb:ForceTarget(minion)
			end
			if MenuKassadin.clearlane.useEF then
				mainCastPosition, mainHitChance, maxHit = VP:GetConeAOECastPosition(minion, Espell.delay, Espell.angle, Espell.range, Espell.speed, myHero)
				if maxHit >=1 and mainHitChance >=0 then
					CastSpell(_E, mainCastPosition.x, mainCastPosition.z)
				end
			end
		end
	end
end

--[[ Function TowerdiveManager for R
function TowerDive()
	if Rspell.Ready() then
		for _, turret in pairs(GetTurrets()) do
			if turret ~= nil then
				if GetDistance(turret.object, myHero.pos) <= (Rspell.range+950) then
					if  MenuKassadin.extracfg.tdive then
						if ((myHero.health/myHero.maxHealth)*100) >= MenuKassadin.extracfg.tdivelife then
							print("Es funktioniert")
							return true
						else
							print("haha2")
							return false
						end
					end
				elseif GetDistance(turret.object, myHero.pos) > (Rspell.range+950) then
					print(GetDistance(turret.object, myHero.pos))
					return true
				end
			end
		end
	end
end --]]

-- Ingame Menu
function Menu()
	MenuKassadin = scriptConfig("iSwearSheWasKassadin "..version, "iSwearSheWasKassadin "..version)
	MenuKassadin:addSubMenu("[Kassadin]: Orbwalking", "Orbwalking")
		SxOrb:LoadToMenu(MenuKassadin.Orbwalking)
	TargetSelector = TargetSelector(TARGET_LOW_HP_PRIORITY, Qspell.range, DAMAGE_MAGIC)
	TargetSelector.name = "Kassadin"
	MenuKassadin:addTS(TargetSelector)
	MenuKassadin:addSubMenu("[Kassadin]: Combo Settings", "combocfg")
	MenuKassadin.combocfg:addParam("useQ", "Use " .. Qspell.name .. "(Q)", SCRIPT_PARAM_ONOFF, true)
	MenuKassadin.combocfg:addParam("qqq", "--------------------------------------------------------", SCRIPT_PARAM_INFO,"")
	MenuKassadin.combocfg:addParam("useW", "Use " .. Wspell.name .. "(W)", SCRIPT_PARAM_ONOFF, true)
	MenuKassadin.combocfg:addParam("qqq", "--------------------------------------------------------", SCRIPT_PARAM_INFO,"")
	MenuKassadin.combocfg:addParam("useE", "Use " .. Espell.name .. "(E)", SCRIPT_PARAM_ONOFF, true)
	MenuKassadin.combocfg:addParam("qqq", "--------------------------------------------------------", SCRIPT_PARAM_INFO,"")
	MenuKassadin.combocfg:addParam("useR", "Use " .. Rspell.name .. "(R)", SCRIPT_PARAM_ONOFF, true)
	MenuKassadin.combocfg:addParam("qqq", "--------------------------------------------------------", SCRIPT_PARAM_INFO,"")
	MenuKassadin.combocfg:addParam("useAA", "Use Auto Attacks in Combo", SCRIPT_PARAM_ONOFF, true)
	MenuKassadin.combocfg:addParam("qqq", "--------------------------------------------------------", SCRIPT_PARAM_INFO,"")
	MenuKassadin.combocfg:addParam("docombo", "Full Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)

	MenuKassadin:addSubMenu("[Kassadin]: Harras Settings", "harrascfg")
	MenuKassadin.harrascfg:addParam("harrasmana", "Min. MP% To Harass", SCRIPT_PARAM_SLICE, 30, 0, 100, 0)
	MenuKassadin.harrascfg:addParam("HMode", "Harras Mode:", SCRIPT_PARAM_LIST, 3, {"|Q|", "|E|", "|QE|"})
	MenuKassadin.harrascfg:addParam("doharras", "Harras", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("T"))

	MenuKassadin:addSubMenu("[Kassadin]: LaneClear Settings", "clearlane")
	MenuKassadin.clearlane:addParam("useQF", "Use " .. Qspell.name .. "(Q)", SCRIPT_PARAM_ONOFF, true)
	MenuKassadin.clearlane:addParam("qqq", "--------------------------------------------------------", SCRIPT_PARAM_INFO,"")
	MenuKassadin.clearlane:addParam("useWF", "Use " .. Wspell.name .. "(W)", SCRIPT_PARAM_ONOFF, true)
	MenuKassadin.clearlane:addParam("qqq", "--------------------------------------------------------", SCRIPT_PARAM_INFO,"")
	MenuKassadin.clearlane:addParam("useEF", "Use " .. Espell.name .. "(E)", SCRIPT_PARAM_ONOFF, true)
	MenuKassadin.clearlane:addParam("qqq", "--------------------------------------------------------", SCRIPT_PARAM_INFO,"")
	MenuKassadin.clearlane:addParam("clearmana", "Min. Mana to LaneClear", SCRIPT_PARAM_SLICE, 30, 0, 100, 0)
	MenuKassadin.clearlane:addParam("qqq", "--------------------------------------------------------", SCRIPT_PARAM_INFO,"")
	MenuKassadin.clearlane:addParam("dolaneclear", "Lane Clear", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("V"))

	MenuKassadin:addSubMenu("[Kassadin]: Draw Settings", "drawcfg")
	MenuKassadin.drawcfg:addParam("qDraw", "Draw Q", SCRIPT_PARAM_ONOFF, true)
	MenuKassadin.drawcfg:addParam("eDraw", "Draw E", SCRIPT_PARAM_ONOFF, true)
	MenuKassadin.drawcfg:addParam("rDraw", "Draw R", SCRIPT_PARAM_ONOFF, true)
	MenuKassadin.drawcfg:addParam("eReady", "E Ready", SCRIPT_PARAM_ONOFF, true)

	MenuKassadin:addSubMenu("[Kassadin]: Items/Summoners", "itemcfg")
	MenuKassadin.itemcfg:addParam("aZhon", "Use Auto Zhonya's", SCRIPT_PARAM_ONOFF, true)
	MenuKassadin.itemcfg:addParam("aZhonlife", "Use Zhonya's under % health", SCRIPT_PARAM_SLICE, 30, 0, 100, 0)
	MenuKassadin.itemcfg:addParam("aSeraph", "Use Auto Seraph's", SCRIPT_PARAM_ONOFF, true)
	MenuKassadin.itemcfg:addParam("aSeraphlife", "Use Seraph's under % health", SCRIPT_PARAM_SLICE, 30, 0, 100,0)

	MenuKassadin:addSubMenu("[Kassadin]: Extras", "extracfg")
	--[[MenuKassadin.extracfg:addParam("tdive", "Towerdive", SCRIPT_PARAM_ONOFF, true)
	MenuKassadin.extracfg:addParam("tdivelife", "Don't Towerdive if % health under", SCRIPT_PARAM_SLICE, 15, 0, 100, 0)--]]
		-- Ignite
		if myHero:GetSpellData(SUMMONER_1).name:find("summonerdot") then
			Ignite = SUMMONER_1
		elseif	myHero:GetSpellData(SUMMONER_2).name:find("summonerdot") then
			Ignite = SUMMONER_2
		end
	if Ignite ~= nil then
	MenuKassadin.itemcfg:addParam("aIgnite", "Use Auto Ignite", SCRIPT_PARAM_ONOFF, true)
	MenuKassadin.itemcfg:addParam("IgniteOverkill", "Avoid Ignite Overkill", SCRIPT_PARAM_ONOFF, true)
	end
	-- Additional Settings. WIP
	MenuKassadin.combocfg:permaShow("docombo")
	MenuKassadin.harrascfg:permaShow("doharras")

end

-- Function OnDraw
function OnDraw()
	if myHero.dead then return end
		if MenuKassadin.drawcfg.qDraw and Qspell.Ready() then
			DrawCircle(myHero.x, myHero.y, myHero.z, Qspell.range, 0x191970)
		end
		if MenuKassadin.drawcfg.eDraw and Espell.Ready() then
			DrawCircle(myHero.x, myHero.y, myHero.z, Espell.range, 0x191970)
		end
		if MenuKassadin.drawcfg.rDraw and Rspell.Ready() then
			DrawCircle(myHero.x, myHero.y, myHero.z, Rspell.range, 0x191970)
		end
		-- Annonce when E is ready for cast
		if MenuKassadin.drawcfg.eReady and Espell.Ready() then
		DrawText("Force Pulse available!", 18, 100, 100, ARGB(255,255,204,0))
		end
end




------------------Class Scriptupdate------------------
--[[
			Credits go to Aroc and iCreative
--]]

class "_ScriptUpdate"
function _ScriptUpdate:__init(LocalVersion, UseHttps, Host, VersionPath, ScriptPath, SavePath, CallbackUpdate, CallbackNoUpdate, CallbackNewVersion,CallbackError)
    self.LocalVersion = LocalVersion
    self.Host = Host
    self.VersionPath = '/BoL/TCPUpdater/GetScript'..(UseHttps and '3' or '4')..'.php?script='..self:Base64Encode(self.Host..VersionPath)..'&rand='..math.random(99999999)
    self.ScriptPath = '/BoL/TCPUpdater/GetScript'..(UseHttps and '3' or '4')..'.php?script='..self:Base64Encode(self.Host..ScriptPath)..'&rand='..math.random(99999999)
    self.SavePath = SavePath
    self.CallbackUpdate = CallbackUpdate
    self.CallbackNoUpdate = CallbackNoUpdate
    self.CallbackNewVersion = CallbackNewVersion
    self.CallbackError = CallbackError
    --AddDrawCallback(function() self:OnDraw() end)
    self:CreateSocket(self.VersionPath)
    self.DownloadStatus = 'Connect to Server for VersionInfo'
    AddTickCallback(function() self:GetOnlineVersion() end)
end

function _ScriptUpdate:OnDraw()
    DrawText('Download Status: '..(self.DownloadStatus or 'Unknown'),50,10,50,ARGB(255,255,255,255))
end

function _ScriptUpdate:CreateSocket(url)
    if not self.LuaSocket then
        self.LuaSocket = require("socket")
    else
        self.Socket:close()
        self.Socket = nil
        self.Size = nil
        self.RecvStarted = false
    end
    self.LuaSocket = require("socket")
    self.Socket = self.LuaSocket.tcp()
    self.Socket:settimeout(0, 'b')
    self.Socket:settimeout(99999999, 't')
    self.Socket:connect('sx-bol.eu', 80)
    self.Url = url
    self.Started = false
    self.LastPrint = ""
    self.File = ""
end

function _ScriptUpdate:Base64Encode(data)
    local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    return ((data:gsub('.', function(x)
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

function _ScriptUpdate:GetOnlineVersion()
    if self.GotScriptVersion then return end

    self.Receive, self.Status, self.Snipped = self.Socket:receive(1024)
    if self.Status == 'timeout' and not self.Started then
        self.Started = true
        self.Socket:send("GET "..self.Url.." HTTP/1.1\r\nHost: sx-bol.eu\r\n\r\n")
    end
    if (self.Receive or (#self.Snipped > 0)) and not self.RecvStarted then
        self.RecvStarted = true
        local recv,sent,time = self.Socket:getstats()
        self.DownloadStatus = 'Downloading VersionInfo (0%)'
    end

    self.File = self.File .. (self.Receive or self.Snipped)
    if self.File:find('</size>') then
        if not self.Size then
            self.Size = tonumber(self.File:sub(self.File:find('<si'..'ze>')+6,self.File:find('</s'..'ize>')-1)) + self.File:len()
        end
        self.DownloadStatus = 'Downloading VersionInfo ('..math.round(100/self.Size*self.File:len(),2)..'%)'
    end
    if not (self.Receive or (#self.Snipped > 0)) and self.RecvStarted and self.Size and math.round(100/self.Size*self.File:len(),2) > 95 then
        self.DownloadStatus = 'Downloading VersionInfo (100%)'
        local HeaderEnd, ContentStart = self.File:find('<scr'..'ipt>')
        local ContentEnd, _ = self.File:find('</sc'..'ript>')
        if not ContentStart or not ContentEnd then
            if self.CallbackError and type(self.CallbackError) == 'function' then
                self.CallbackError()
            end
        else
            self.OnlineVersion = tonumber(self.File:sub(ContentStart + 1,ContentEnd-1))
            if self.OnlineVersion ~=nil and self.OnlineVersion > self.LocalVersion then
                if self.CallbackNewVersion and type(self.CallbackNewVersion) == 'function' then
                    self.CallbackNewVersion(self.OnlineVersion,self.LocalVersion)
                end
                self:CreateSocket(self.ScriptPath)
                self.DownloadStatus = 'Connect to Server for ScriptDownload'
                AddTickCallback(function() self:DownloadUpdate() end)
            else
                if self.CallbackNoUpdate and type(self.CallbackNoUpdate) == 'function' then
                    self.CallbackNoUpdate(self.LocalVersion)
                end
            end
        end
        self.GotScriptVersion = true
    end
end

function _ScriptUpdate:DownloadUpdate()
    if self.GotScriptUpdate then return end
    self.Receive, self.Status, self.Snipped = self.Socket:receive(1024)
    if self.Status == 'timeout' and not self.Started then
        self.Started = true
        self.Socket:send("GET "..self.Url.." HTTP/1.1\r\nHost: sx-bol.eu\r\n\r\n")
    end
    if (self.Receive or (#self.Snipped > 0)) and not self.RecvStarted then
        self.RecvStarted = true
        local recv,sent,time = self.Socket:getstats()
        self.DownloadStatus = 'Downloading Script (0%)'
    end

    self.File = self.File .. (self.Receive or self.Snipped)
    if self.File:find('</si'..'ze>') then
        if not self.Size then
            self.Size = tonumber(self.File:sub(self.File:find('<si'..'ze>')+6,self.File:find('</si'..'ze>')-1)) + self.File:len()
        end
        self.DownloadStatus = 'Downloading Script ('..math.round(100/self.Size*self.File:len(),2)..'%)'
    end
    if not (self.Receive or (#self.Snipped > 0)) and self.RecvStarted and self.Size and math.round(100/self.Size*self.File:len(),2) > 95 then
        self.DownloadStatus = 'Downloading Script (100%)'
        local HeaderEnd, ContentStart = self.File:find('<sc'..'ript>')
        local ContentEnd, _ = self.File:find('</scr'..'ipt>')
        if not ContentStart or not ContentEnd then
            if self.CallbackError and type(self.CallbackError) == 'function' then
                self.CallbackError()
            end
        else
            local f = io.open(self.SavePath,"w+b")
            f:write(self.File:sub(ContentStart + 1,ContentEnd-1))
            f:close()
            if self.CallbackUpdate and type(self.CallbackUpdate) == 'function' then
                self.CallbackUpdate(self.OnlineVersion,self.LocalVersion)
            end
        end
        self.GotScriptUpdate = true
    end
end
