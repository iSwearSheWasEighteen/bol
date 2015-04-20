--[[ Script Name: iSwearSheWasKassadin ]]--

if myHero.charName ~= "Kassadin" then return end
local autoupdate = true -- u can turn it off, if u don't want autoupdates
local version = 0.02

-- Required Libs
if not _G.Reborn_Loaded then
    if FileExist(LIB_PATH .. "/SxOrbWalk.lua") then
	    require("SxOrbWalk")
    end
else GetSida()
end
if FileExist(LIB_PATH .. "/VPrediction.lua") then
	require("VPrediction")
	VP = VPrediction()
end

-- Spell Information
local Qspell = {name = "Null Sphere", speed = 1400, range = 650, delay = 0.25, width = 60, dmg = 0, Ready = function() return myHero:CanUseSpell(_Q) == READY end}
local Wspell = {name = "Nether Blade", range = 200, delay = nil, dmg = 0, Ready = function() return myHero:CanUseSpell(_W) == READY end}
local Espell = {name = "Force Pulse", speed = nil, angle = 80, delay = 0.25, range = 700, dmg = 0, Ready = function() return myHero:CanUseSpell(_E) == READY end}
local Rspell = {name = "Riftwalk", speed = nil, range = 500, delay = 0.25, width = 200, dmg = 0, Ready = function() return myHero:CanUseSpell(_R) == READY end}
local Ignite = nil
local Melee = 150
local attackdmg = 0
local enemyMinions = minionManager(MINION_ENEMY, Qspell.range, myHero, MINION_SORT_MAXHEALTH_DEC)
local jungleMinions =  minionManager(MINION_JUNGLE, Qspell.range, myHero, MINION_SORT_MAXHEALTH_DEC)
local sacrLoaded,sacrinjected = false, false
local maxRiftWalk = 4

-- local UltStacks = 0

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
        ScriptUpdate(ToUpdate.Version, ToUpdate.UseHttps, ToUpdate.Host, ToUpdate.VersionPath, ToUpdate.ScriptPath, ToUpdate.SavePath, ToUpdate.CallbackUpdate,ToUpdate.CallbackNoUpdate, ToUpdate.CallbackNewVersion,ToUpdate.CallbackError)
    end
end

-- Update Message
function PrintMessage(message) 
    print("<font color=\"#6699ff\"><b>" .. "iSwearSheWasKassadin" .. ":</b></font> <font color=\"#FFFFFF\">" .. message .. "</font>") 
end

-- OnLoad Function
function OnLoad()
    GetSida()
	Menu()
	DelayAction(function() CheckUpdate() end, 0.1)
	print("<b><font color=\"#FF0000\">iSwearSheWasKassadin:</font></b> <font color=\"#FFFFFF\">Enjoy guys!</font>")
	DelayAction(SetMaxRiftWalk, 2)
end

-- Function SetUltStacks()
function SetMaxRiftWalk()
	maxRiftWalk = MenuKassadin.combocfg.comboUltStacks
end

-- OnTick Function
function OnTick()
	SelectedTarged = TargetSelector.target
	Check()
    if opponent ~= nil then
        GetMySpellDmg(opponent)
    end
	-- Combo
	if opponent ~= nil and MenuKassadin.combocfg.docombo then
		if not sacrLoaded then
			SxOrb:EnableAttacks()
		end
		Combo()
	end
	-- AutoHarras
	if opponent ~= nil and MenuKassadin.harrascfg.autoHarras and GetDistance(opponent, myHero) <= Qspell.range then
		Harrass()
	end
	-- Harrass
	if opponent ~= nil and MenuKassadin.harrascfg.doharras then
	--print(myHero:GetSpellData(_Q).mana)
		Harrass()
	end
	-- LaneClear
	if MenuKassadin.clearlane.dolaneclear then
		Clear()
	end
    -- JungleClear
    if MenuKassadin.clearjungle.dojungleclear then
        JungleClear()
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

-- Orbwalker Sac:R or SxOrbWalker
function GetSida()
	if _G.Reborn_Initialised then
		_G.AutoCarry.Keys:RegisterMenuKey(MenuKassadin.combocfg, "docombo", AutoCarry.MODE_AUTOCARRY) -- AutoCarry Key
		_G.AutoCarry.Keys:RegisterMenuKey(MenuKassadin.harrascfg, "doharras", AutoCarry.MODE_MIXEDMODE) -- Harras Key
		_G.AutoCarry.Keys:RegisterMenuKey(MenuKassadin.clearlane, "dolaneclear", AutoCarry.MODE_LANECLEAR) -- LaneClear Key
		-- _G.AutoCarry.Keys:RegisterMenuKey() -- LastHit Key
		_G.AutoCarry.Keys:RegisterKey(string.byte("X"), AutoCarry.MODE_LASTHIT)
		sacrLoaded = true
	elseif _G.Reborn_Loaded then
		 DelayAction(GetSida, 2)
         sacrinjected = true
	--[[else
		if FileExist(LIB_PATH .. "/SxOrbWalk.lua") then
		require("SxOrbWalk")
		end--]]
	end
end



-- Function GetTarget() cause integrate SAC:R
function GetTarget()
	TargetSelector:update()
	if _G.Reborn_Loaded then
		if _G.AutoCarry and _G.AutoCarry.Crosshair and _G.AutoCarry.Attack_Crosshair and _G.AutoCarry.Attack_Crosshair.target then
			return _G.AutoCarry.Attack_Crosshair.target		
		end
	end
	return TargetSelector.target
end

-- Function check
function Check()
	if SelectedTarget ~= nil and ValidTarget(SelectedTarget, Qspell.range) then
		opponent = SelectedTarget
	else 
		opponent = GetTarget()
	end
	--[[if sacrLoaded and MenuKassadin.combocfg.force then
		_G.AutoCarry.Orbwalker:Orbwalk(opponent)
	elseif not sacrLoaded and MenuKassadin.combocfg.force then
		SxOrb:ForceTarget(opponent)
	end--]]
end

-- Function CastQ 
function CastQ(unit)
	if Qspell.Ready() and ValidTarget(unit, Qspell.range) then
		CastSpell(_Q, unit)
	end
end

-- Function CastW and ValidTartget(unit, Wspell.range)
function CastW(unit)
	if Wspell.Ready() and ValidTarget(unit, Wspell.range) then
		CastSpell(_W)
		myHero:Attack(unit)
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
			if HitChance >= 2 and GetDistance(Position) <= Rspell.range then
                if TargetUnderTurret(unit) and MenuKassadin.extracfg.towerdive then
                    if TowerDiveKillable(unit) and MenuKassadin.extracfg.towerdivekillable and ((myHero.health/myHero.maxHealth)*100 >= MenuKassadin.extracfg.towerdivelife) then
                    CastSpell(_R, Position.x, Position.z)
				    -- CastW directly
				    CastSpell(_W)
				    myHero:Attack(unit)
                    end
                else
                    CastSpell(_R, Position.x, Position.z)
				    -- CastW directly
				    CastSpell(_W)
				    myHero:Attack(unit)
                end
		end
	end
end

-- Function Harras Enemy
function Harrass()
	if MenuKassadin.harrascfg.HMode == 1 and ((myHero.mana/myHero.maxMana)*100) >= MenuKassadin.harrascfg.harrasmana then
		CastQ(opponent)
	end
	if MenuKassadin.harrascfg.HMode == 2 and ((myHero.mana/myHero.maxMana)*100) >= MenuKassadin.harrascfg.harrasmana then
		CastE(opponent)
	end
	if MenuKassadin.harrascfg.HMode == 3 and ((myHero.mana/myHero.maxMana)*100) >= MenuKassadin.harrascfg.harrasmana then
		CastQ(opponent)
		CastE(opponent)
	end
end

-- Function Combo
function Combo()
	if myHero.dead then return end
	if MenuKassadin.combocfg.useR and Rspell.Ready() and (GetDistance(opponent, myHero) >= 210) then
		CastR(opponent)
	end
	if MenuKassadin.combocfg.useW and Wspell.Ready() then
		CastW(opponent)
	end
	if MenuKassadin.combocfg.useE and Espell.Ready() then
		CastE(opponent)
	end 
	if MenuKassadin.combocfg.useQ and Qspell.Ready() then
		CastQ(opponent)
	end
end

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
						end
					else
						CastSpell(Ignite, enemy)
					end
				else
					CastSpell(Ignite, enemy)
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

-- Function GetMySpellDamage
function GetMySpellDmg(unit)
    	--[[Qspell.dmg = (70+(myHero:GetSpellData(_Q).level*25-25)+myHero.ap*0.7)
		Wspell.dmg = (40+(myHero:GetSpellData(_W).level*25-25)+myHero.ap*0.6)
		Espell.dmg = (80+(myHero:GetSpellData(_E).level*25-25)+myHero.ap*0.7) ]]--
        Qspell.dmg = getDmg("Q", unit, myHero)
        Wspell.dmg = getDmg("W", unit, myHero)
        Espell.dmg = getDmg("E", unit, myHero)
        Rspell.dmg = getDmg("R", unit, myHero)
        attackdmg = getDmg ("AD", unit, myHero)
end

-- LaneClear
function Clear()
	enemyMinions:update()
	for j, minion in pairs(enemyMinions.objects) do
		--[[local myQdmg = getDmg("Q", minion, myHero ) --(70+(myHero:GetSpellData(_Q).level*25-25)+myHero.ap*0.7)
		local myWdmg = getDmg("W", minion, myHero)  --(40+(myHero:GetSpellData(_W).level*25-25)+myHero.ap*0.6)
		local myEdmg = getDmg("E", minion, myHero)  --(80+(myHero:GetSpellData(_E).level*25-25)+myHero.ap*0.7)  --]]
		if ((myHero.mana/myHero.maxMana)*100) >= MenuKassadin.clearlane.clearmana then
			if MenuKassadin.clearlane.useQF and (minion.health <= getDmg("Q", minion, myHero )) then
				CastQ(minion)
			end
			if MenuKassadin.clearlane.useWF and GetDistance(minion, myHero) <= Wspell.range and (minion.health <= getDmg("W", minion, myHero)) then
				CastW(minion)
				myHero:Attack(minion)
			end
			if MenuKassadin.clearlane.useEF then
				mainCastPosition, mainHitChance, maxHit = VP:GetConeAOECastPosition(minion, Espell.delay, Espell.angle, Espell.range, Espell.speed, myHero)
				if maxHit >=1 and mainHitChance >=0 and (minion.health <= getDmg("E", minion, myHero)) then
					CastSpell(_E, mainCastPosition.x, mainCastPosition.z)
				end
			end
		end
	end
end

-- Function JungleClear() it wont lasthit with skills -- simple
function JungleClear()
	jungleMinions:update()
	for j, minion in pairs(jungleMinions.objects) do
		if ((myHero.mana/myHero.maxMana)*100) >= MenuKassadin.clearjungle.junglemana then
			if MenuKassadin.clearjungle.jungleQF then
				CastQ(minion)
			end
			if MenuKassadin.clearjungle.jungleWF and GetDistance(minion, myHero) <= Wspell.range then
				CastW(minion)
				myHero:Attack(minion)
			end
			if MenuKassadin.clearjungle.jungleEF then
				mainCastPosition, mainHitChance, maxHit = VP:GetConeAOECastPosition(minion, Espell.delay, Espell.angle, Espell.range, Espell.speed, myHero)
				if maxHit >=1 and mainHitChance >=0 then
					CastSpell(_E, mainCastPosition.x, mainCastPosition.z)
				end
			end
		end
	end
end

-- Function EnemyUnderTurret
function TargetUnderTurret(unit)
    if unit ~= nil and ValidTarget(unit, 1000) then
        for j, turrets in pairs(GetTurrets()) do
            if turret ~= nil and GetDistanceSqr(myHero, turret) < math.pow(2000,2) then
                if turret.team ~= myHero.team and GetDistanceSqr(unit, turret) < math.pow(turret.range,2) then
               -- print("enemy is under turret")
                    return true
                end
            end
        end        
    end
    return false
end

-- Function TowerdiveKillable(); returns boolean
function TowerDiveKillable(unit)
    if unit ~= nil and ValidTarget(unit, Rspell.range) then
        if Rspell.Ready() and TargetUnderTurret(unit) then
            if ( Qspell.Ready() or Wspell.Ready() or Espell.Ready() ) then
                local totaldmg, Qdmg, Wdmg, Edmg, Rdmg, AAdmg = 0, ((Qspell.Ready() and getDmg("Q", unit, myHero)) or 0), ((Wspell.Ready() and getDmg("W", unit, myHero)) or 0), ((Espell.Ready() and getDmg("E", unit, myHero)) or 0), ((Rspell.Ready() and getDmg("R", unit, myHero)) or 0), getDmg("AD", unit, myHero)
                totaldmg = Qdmg+Wdmg+Edmg+Rdmg+AAdmg
                print("das ist total dmg")  --debug
                print(totaldmg)
                if unit.health <= totaldmg then
                    return true
                end
            end
        end
    end
    return false
end

--[[ Function ResetUltStacks()
function ResetUltStacks()
	if UltStacks > 0 then
		UltStacks = UltStacks -1
		print("Ult Stack -1")
		print(UltStacks)
	end
end ]]--

-- Ingame Menu
function Menu()
	MenuKassadin = scriptConfig("iSwearSheWasKassadin "..version, "iSwearSheWasKassadin "..version)
		if not _G.Reborn_Loaded then
		MenuKassadin:addSubMenu("[Kassadin]: Orbwalking", "Orbwalking")
			SxOrb:LoadToMenu(MenuKassadin.Orbwalking)
		end
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
			MenuKassadin.combocfg:addParam("force", "Force to attack the target with AA", SCRIPT_PARAM_ONOFF, true)
			MenuKassadin.combocfg:addParam("qqq", "--------------------------------------------------------", SCRIPT_PARAM_INFO,"")
			MenuKassadin.combocfg:addParam("comboUltStacks", "Max. Stacks on Ult: (WIP)", SCRIPT_PARAM_LIST, 4, {"1 Stack", "2 Stacks", "3 Stacks", "4 Stacks"})
			MenuKassadin.combocfg:addParam("qqq", "If u change UltStacks, press 2xF9", SCRIPT_PARAM_INFO,"")
			MenuKassadin.combocfg:addParam("qqq", "--------------------------------------------------------", SCRIPT_PARAM_INFO,"")
			MenuKassadin.combocfg:addParam("docombo", "Full Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)

		MenuKassadin:addSubMenu("[Kassadin]: Harras Settings", "harrascfg")
			MenuKassadin.harrascfg:addParam("harrasmana", "Min. MP% To Harass", SCRIPT_PARAM_SLICE, 30, 0, 100, 0)
			MenuKassadin.harrascfg:addParam("qqq", "--------------------------------------------------------", SCRIPT_PARAM_INFO,"")
			MenuKassadin.harrascfg:addParam("HMode", "Harras Mode:", SCRIPT_PARAM_LIST, 3, {"|Q|", "|E|", "|QE|"})
			MenuKassadin.harrascfg:addParam("qqq", "--------------------------------------------------------", SCRIPT_PARAM_INFO,"")
			MenuKassadin.harrascfg:addParam("autoHarras", "Auto Harras", SCRIPT_PARAM_ONOFF, true)
			MenuKassadin.harrascfg:addParam("qqq", "--------------------------------------------------------", SCRIPT_PARAM_INFO,"")
			MenuKassadin.harrascfg:addParam("doharras", "Harras", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))

		MenuKassadin:addSubMenu("[Kassadin]: LaneClear Settings", "clearlane")
			MenuKassadin.clearlane:addParam("useQF", "Use " .. Qspell.name .. "(Q)", SCRIPT_PARAM_ONOFF, true)
			MenuKassadin.clearlane:addParam("qqq", "--------------------------------------------------------", SCRIPT_PARAM_INFO,"")
			MenuKassadin.clearlane:addParam("useWF", "Use " .. Wspell.name .. "(W)", SCRIPT_PARAM_ONOFF, false)
			MenuKassadin.clearlane:addParam("qqq", "--------------------------------------------------------", SCRIPT_PARAM_INFO,"")
			MenuKassadin.clearlane:addParam("useEF", "Use " .. Espell.name .. "(E)", SCRIPT_PARAM_ONOFF, true)
			MenuKassadin.clearlane:addParam("qqq", "--------------------------------------------------------", SCRIPT_PARAM_INFO,"")
			MenuKassadin.clearlane:addParam("clearmana", "Min. Mana to LaneClear", SCRIPT_PARAM_SLICE, 30, 0, 100, 0)
			MenuKassadin.clearlane:addParam("qqq", "--------------------------------------------------------", SCRIPT_PARAM_INFO,"")
			MenuKassadin.clearlane:addParam("dolaneclear", "Lane Clear", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("V"))

        MenuKassadin:addSubMenu("[Kassadin]: JungleClear Settings", "clearjungle")
			MenuKassadin.clearjungle:addParam("jungleQF", "Use " .. Qspell.name .. "(Q)", SCRIPT_PARAM_ONOFF, true)
			MenuKassadin.clearjungle:addParam("qqq", "--------------------------------------------------------", SCRIPT_PARAM_INFO,"")
			MenuKassadin.clearjungle:addParam("jungleWF", "Use " .. Wspell.name .. "(W)", SCRIPT_PARAM_ONOFF, false)
			MenuKassadin.clearjungle:addParam("qqq", "--------------------------------------------------------", SCRIPT_PARAM_INFO,"")
			MenuKassadin.clearjungle:addParam("jungleEF", "Use " .. Espell.name .. "(E)", SCRIPT_PARAM_ONOFF, true)
			MenuKassadin.clearjungle:addParam("qqq", "--------------------------------------------------------", SCRIPT_PARAM_INFO,"")
			MenuKassadin.clearjungle:addParam("junglemana", "Min. Mana to LaneClear", SCRIPT_PARAM_SLICE, 30, 0, 100, 0)
			MenuKassadin.clearjungle:addParam("qqq", "--------------------------------------------------------", SCRIPT_PARAM_INFO,"")
			MenuKassadin.clearjungle:addParam("dojungleclear", "Jungle Clear", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("V"))

		MenuKassadin:addSubMenu("[Kassadin]: Draw Settings", "drawcfg")
			MenuKassadin.drawcfg:addParam("qDraw", "Draw Q", SCRIPT_PARAM_ONOFF, true)
			MenuKassadin.drawcfg:addParam("eDraw", "Draw E", SCRIPT_PARAM_ONOFF, true)
			MenuKassadin.drawcfg:addParam("rDraw", "Draw R", SCRIPT_PARAM_ONOFF, true)
			MenuKassadin.drawcfg:addParam("eReady", "E Ready Notification", SCRIPT_PARAM_ONOFF, true)

		MenuKassadin:addSubMenu("[Kassadin]: Items/Summoners", "itemcfg")
			MenuKassadin.itemcfg:addParam("aZhon", "Use Auto Zhonya's", SCRIPT_PARAM_ONOFF, true)
			MenuKassadin.itemcfg:addParam("aZhonlife", "Use Zhonya's under % health", SCRIPT_PARAM_SLICE, 30, 0, 100, 0)
			MenuKassadin.itemcfg:addParam("aSeraph", "Use Auto Seraph's", SCRIPT_PARAM_ONOFF, true)
			MenuKassadin.itemcfg:addParam("aSeraphlife", "Use Seraph's under % health", SCRIPT_PARAM_SLICE, 30, 0, 100,0)

		MenuKassadin:addSubMenu("[Kassadin]: Extras", "extracfg")
            MenuKassadin.extracfg:addParam("towerdive", "Don't Towerdive with " .. Rspell.name .. "(R)", SCRIPT_PARAM_ONOFF, true)
            MenuKassadin.extracfg:addParam("towerdivelife", "Min. health to towerdive in %",  SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
            MenuKassadin.extracfg:addParam("towerdivekillable", "Ignore Towedive if killable", SCRIPT_PARAM_ONOFF, true)
			MenuKassadin.extracfg:addParam("qqq", "WIP", SCRIPT_PARAM_INFO,"")

			-- Find Ignite
			if myHero:GetSpellData(SUMMONER_1).name:find("summonerdot") then
				Ignite = SUMMONER_1
			elseif	myHero:GetSpellData(SUMMONER_2).name:find("summonerdot") then
				Ignite = SUMMONER_2
			end
			if Ignite ~= nil then
				MenuKassadin.itemcfg:addParam("aIgnite", "Use Auto Ignite", SCRIPT_PARAM_ONOFF, true)
				MenuKassadin.itemcfg:addParam("IgniteOverkill", "Avoid Ignite Overkill", SCRIPT_PARAM_ONOFF, true)
			end

		-- Display Active Button
		MenuKassadin.combocfg:permaShow("docombo")
		MenuKassadin.harrascfg:permaShow("doharras")
		MenuKassadin.clearlane:permaShow("dolaneclear")
end

-- Function OnDraw
function OnDraw()
	if myHero.dead then return end
		if MenuKassadin.drawcfg.qDraw and Qspell.Ready() then
			DrawCircle(myHero.x, myHero.y, myHero.z, Qspell.range, ARGB(255,0,0,255))
		end
		if MenuKassadin.drawcfg.eDraw and Espell.Ready() then
			DrawCircle(myHero.x, myHero.y, myHero.z, Espell.range, ARGB(255,0,0,255))
		end
		if MenuKassadin.drawcfg.rDraw and Rspell.Ready() then
			DrawCircle(myHero.x, myHero.y, myHero.z, Rspell.range, ARGB(255,0,0,255))
		end
		-- Annonce when E is ready for cast
		if MenuKassadin.drawcfg.eReady and Espell.Ready() then
			local heroPos = WorldToScreen(D3DXVECTOR3(myHero.x, myHero.y, myHero.z))
			local xPos = heroPos.x-20
			local yPos = heroPos.y-35
			DrawText("Force Pulse available!", 20, xPos, yPos, ARGB(255,255,204,0))
		end
end

--[[ Function OnProcessSpell
function OnProcessSpell(unit, spell)
	-- Count UltStacks
	if unit.isMe and spell.name == myHero:GetSpellData(_R).name then
		UltStacks = UltStacks + 1
		DelayAction(ResetUltStacks,15)
		print("Riftwalk erkannt")
		print(UltStacks)
	end
end--]]

------------------Class Scriptupdate------------------
--[[
			Credits go to Aroc
--]]

class "ScriptUpdate"
function ScriptUpdate:__init(LocalVersion,UseHttps, Host, VersionPath, ScriptPath, SavePath, CallbackUpdate, CallbackNoUpdate, CallbackNewVersion,CallbackError)
    self.LocalVersion = LocalVersion
    self.Host = Host
    self.VersionPath = '/BoL/TCPUpdater/GetScript'..(UseHttps and '5' or '6')..'.php?script='..self:Base64Encode(self.Host..VersionPath)..'&rand='..math.random(99999999)
    self.ScriptPath = '/BoL/TCPUpdater/GetScript'..(UseHttps and '5' or '6')..'.php?script='..self:Base64Encode(self.Host..ScriptPath)..'&rand='..math.random(99999999)
    self.SavePath = SavePath
    self.CallbackUpdate = CallbackUpdate
    self.CallbackNoUpdate = CallbackNoUpdate
    self.CallbackNewVersion = CallbackNewVersion
    self.CallbackError = CallbackError
    AddDrawCallback(function() self:OnDraw() end)
    self:CreateSocket(self.VersionPath)
    self.DownloadStatus = 'Connect to Server for VersionInfo'
    AddTickCallback(function() self:GetOnlineVersion() end)
end

function ScriptUpdate:print(str)
    print('<font color="#FFFFFF">'..os.clock()..': '..str)
end

function ScriptUpdate:OnDraw()
    if self.DownloadStatus ~= 'Downloading Script (100%)' and self.DownloadStatus ~= 'Downloading VersionInfo (100%)'then
        DrawText('Download Status: '..(self.DownloadStatus or 'Unknown'),50,10,50,ARGB(0xFF,0xFF,0xFF,0xFF))
    end
end

function ScriptUpdate:CreateSocket(url)
    if not self.LuaSocket then
        self.LuaSocket = require("socket")
    else
        self.Socket:close()
        self.Socket = nil
        self.Size = nil
        self.RecvStarted = false
    end
    self.Socket = self.LuaSocket.tcp()
    if not self.Socket then
        print('Socket Error')
    else
        self.Socket:settimeout(0, 'b')
        self.Socket:settimeout(99999999, 't')
        self.Socket:connect('sx-bol.eu', 80)
        self.Url = url
        self.Started = false
        self.LastPrint = ""
        self.File = ""
    end
end

function ScriptUpdate:Base64Encode(data)
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

function ScriptUpdate:GetOnlineVersion()
    if self.GotScriptVersion or not self.Socket then return end

    self.Receive, self.Status, self.Snipped = self.Socket:receive(1024)
    if self.Status == 'timeout' and not self.Started then
        self.Started = true
        self.Socket:send("GET "..self.Url.." HTTP/1.1\r\nHost: sx-bol.eu\r\n\r\n")
    end
    if (self.Receive or (#self.Snipped > 0)) and not self.RecvStarted then
        self.RecvStarted = true
        self.DownloadStatus = 'Downloading VersionInfo (0%)'
    end

    self.File = self.File .. (self.Receive or self.Snipped)
    if self.File:find('</s'..'ize>') then
        if not self.Size then
            self.Size = tonumber(self.File:sub(self.File:find('<si'..'ze>')+6,self.File:find('</si'..'ze>')-1))
        end
        if self.File:find('<scr'..'ipt>') then
            local _,ScriptFind = self.File:find('<scr'..'ipt>')
            local ScriptEnd = self.File:find('</scr'..'ipt>')
            if ScriptEnd then ScriptEnd = ScriptEnd - 1 end
            local DownloadedSize = self.File:sub(ScriptFind+1,ScriptEnd or -1):len()
            self.DownloadStatus = 'Downloading VersionInfo ('..math.round(100/self.Size*DownloadedSize,2)..'%)'
        end
    end
    if self.File:find('</scr'..'ipt>') then
        self.DownloadStatus = 'Downloading VersionInfo (100%)'
        local a,b = self.File:find('\r\n\r\n')
        self.File = self.File:sub(a,-1)
        self.NewFile = ''
        for line,content in ipairs(self.File:split('\n')) do
            if content:len() > 5 then
                self.NewFile = self.NewFile .. content
            end
        end
        local HeaderEnd, ContentStart = self.File:find('<scr'..'ipt>')
        local ContentEnd, _ = self.File:find('</sc'..'ript>')
        if not ContentStart or not ContentEnd then
            if self.CallbackError and type(self.CallbackError) == 'function' then
                self.CallbackError()
            end
        else
            self.OnlineVersion = (Base64Decode(self.File:sub(ContentStart + 1,ContentEnd-1)))
            self.OnlineVersion = tonumber(self.OnlineVersion)
            if self.OnlineVersion > self.LocalVersion then
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

function ScriptUpdate:DownloadUpdate()
    if self.GotScriptUpdate or not self.Socket then return end
    self.Receive, self.Status, self.Snipped = self.Socket:receive(1024)
    if self.Status == 'timeout' and not self.Started then
        self.Started = true
        self.Socket:send("GET "..self.Url.." HTTP/1.1\r\nHost: sx-bol.eu\r\n\r\n")
    end
    if (self.Receive or (#self.Snipped > 0)) and not self.RecvStarted then
        self.RecvStarted = true
        self.DownloadStatus = 'Downloading Script (0%)'
    end

    self.File = self.File .. (self.Receive or self.Snipped)
    if self.File:find('</si'..'ze>') then
        if not self.Size then
            self.Size = tonumber(self.File:sub(self.File:find('<si'..'ze>')+6,self.File:find('</si'..'ze>')-1))
        end
        if self.File:find('<scr'..'ipt>') then
            local _,ScriptFind = self.File:find('<scr'..'ipt>')
            local ScriptEnd = self.File:find('</scr'..'ipt>')
            if ScriptEnd then ScriptEnd = ScriptEnd - 1 end
            local DownloadedSize = self.File:sub(ScriptFind+1,ScriptEnd or -1):len()
            self.DownloadStatus = 'Downloading Script ('..math.round(100/self.Size*DownloadedSize,2)..'%)'
        end
    end
    if self.File:find('</scr'..'ipt>') then
        self.DownloadStatus = 'Downloading Script (100%)'
        local a,b = self.File:find('\r\n\r\n')
        self.File = self.File:sub(a,-1)
        self.NewFile = ''
        for line,content in ipairs(self.File:split('\n')) do
            if content:len() > 5 then
                self.NewFile = self.NewFile .. content
            end
        end
        local HeaderEnd, ContentStart = self.NewFile:find('<sc'..'ript>')
        local ContentEnd, _ = self.NewFile:find('</scr'..'ipt>')
        if not ContentStart or not ContentEnd then
            if self.CallbackError and type(self.CallbackError) == 'function' then
                self.CallbackError()
            end
        else
            local newf = self.NewFile:sub(ContentStart+1,ContentEnd-1)
            local newf = newf:gsub('\r','')
            local newf = Base64Decode(newf)
            local f = io.open(self.SavePath,"w+b")
            f:write(newf)
            f:close()
            if self.CallbackUpdate and type(self.CallbackUpdate) == 'function' then
                self.CallbackUpdate(self.OnlineVersion,self.LocalVersion)
            end
        end
        self.GotScriptUpdate = true
    end
end
