--[[------------------------------------------------------------------------------------------------------------------------------------

                                                          iSwearSheWasNami
                                                                   by
                                                             iSwearSheWas18

--------------------------------------------------------------------------------------------------------------------------------------]]
--[[------------------------------------------------------------------------------------------------------------------------------------

    Features:
        o Harras / Autoharras
        o Combo
        o AutoHeal Ally if HP <= XX Percent; prioritize Ally; 
        o AutoE on Ally or on Nami
        o AutoUltimate when X Enemies are hitable
        o WIP

--------------------------------------------------------------------------------------------------------------------------------------]]
--[[------------------------------------------------------------------------------------------------------------------------------------

                                                          BEGIN SCRIPT

--------------------------------------------------------------------------------------------------------------------------------------]]
if myHero.charName ~= "Nami" then
    print("<font color=\"#006666\"><b>iSwearSheWasKalista:</b></font> <font color=\"#FFFFFF\">You Are not playin Kalista.</font>")
    return
end

----------------------------------------------------------REQUIRED LIBS--------------------------------------------------------------------
--[Orbwalker]]--
if not _G.Reborn_Loaded then
    if FileExist(LIB_PATH .. "/SxOrbWalk.lua") then
	    require("SxOrbWalk")
    end
end

--[Prediction]]--
if FileExist(LIB_PATH .. "/VPrediction.lua") then
	require("VPrediction")
	VP = VPrediction()
end
if FileExist(LIB_PATH .. "/HPrediction.lua") then
    require("HPrediction")
    HP = HPrediction()
end
-------------------------------------------------------------GLOBALS-----------------------------------------------------------------------

local autoupdate = true -- u can turn it off, if u don't want autoupdates
local version = 0.1

local Qspell = {name = "Aqua Prison", range = 875, delay = 0.875, radius = 162, speed = 1000, Ready = function() return myHero:CanUseSpell(_Q) == READY end, mana = 0}
local Wspell = {name = "Ebb and Flow", range = 725, Ready = function() return myHero:CanUseSpell(_W) == READY end, mana = 0}
local Espell = {name = "Tidecaller's Blessing", range = 800, Ready = function() return myHero:CanUseSpell(_E) == READY end, mana = 0}
local Rspell = {name = "Tidal Wave", range = 2750, speed = 859, delay = 0.25, width=562, Ready = function() return myHero:CanUseSpell(_R) == READY end, mana = 0}
local isRecalling, AArange = false, 550
local enemyMinions = minionManager(MINION_ENEMY, myHero.range, myHero, MINION_SORT_MAXHEALTH_DEC)
local jungleMinions = minionManager(MINION_JUNGLE, 1000, myHero, MINION_SORT_MAXHEALTH_DEC)
local TargetTable = {
	AP = {
		"Annie", "Ahri", "Akali", "Anivia", "Annie", "Brand", "Cassiopeia", "Diana", "Evelynn", "FiddleSticks", "Fizz", "Gragas", "Heimerdinger", "Karthus",
		"Kassadin", "Katarina", "Kayle", "Kennen", "Leblanc", "Lissandra", "Lux", "Malzahar", "Mordekaiser", "Morgana", "Nidalee", "Orianna",
		"Ryze", "Sion", "Swain", "Syndra", "Teemo", "TwistedFate", "Veigar", "Viktor", "Vladimir", "Xerath", "Ziggs", "Zyra", "Velkoz"
	},	
	Support = {
		"Alistar", "Bard", "Blitzcrank", "Janna", "Karma", "Leona", "Lulu", "Nami", "Nunu", "Sona", "Soraka", "Taric", "Thresh", "Zilean", "Braum"
	},	
	Tank = {
		"Amumu", "Chogath", "DrMundo", "Galio", "Hecarim", "Malphite", "Maokai", "Nasus", "Rammus", "Sejuani", "Nautilus", "Shen", "Singed", "Skarner", "Volibear",
		"Warwick", "Yorick", "Zac"
	},
	AD_Carry = {
		"Ashe", "Caitlyn", "Corki", "Draven", "Ezreal", "Graves", "Jayce", "Jinx", "Kalista", "KogMaw", "Lucian", "MasterYi", "MissFortune", "Pantheon", "Quinn", "Rek'Sai", "Shaco", "Sivir",
		"Talon","Tryndamere", "Tristana", "Twitch", "Urgot", "Varus", "Vayne", "Yasuo", "Zed"
	},
	Bruiser = {
		"Aatrox", "Darius", "Elise", "Fiora", "Gangplank", "Garen", "Irelia", "JarvanIV", "Jax", "Khazix", "LeeSin", "Nocturne", "Olaf", "Poppy",
		"Renekton", "Rengar", "Riven", "Rumble", "Shyvana", "Trundle", "Udyr", "Vi", "MonkeyKing", "XinZhao"
	}
}
local AD_Carries = {
        "Ashe", "Caitlyn", "Corki", "Draven", "Ezreal", "Graves", "Jayce", "Jinx", "Kalista", "KogMaw", "Lucian", "MissFortune", "Quinn", "Sivir", "Tristana", "Twitch", "Urgot", "Varus", "Vayne"
                }

---------------------------------------------------------------MENU------------------------------------------------------------------------
function Menu()
    Menu = scriptConfig("iSwearSheWasName " ..version, "iSwearSheWasNami " ..version)
        -- Load SxOrbwalk Later
        if not _G.Reborn_Loaded then
		Menu:addSubMenu("Nami: Orbwalking", "orbwalking")
			SxOrb:LoadToMenu(Menu.orbwalking)
		end
        -- TargetSelector
        TargetSelector = TargetSelector(TARGET_LESS_CAST_PRIORITY, Espell.range, DAMAGE_PHYSICAL)
        TargetSelector.name = "Nami"
        Menu:addTS(TargetSelector)
        -- Arrange Priority, GetSummoner, ... and couple other stuff
        CustomLoad()

        -- BEGIN OF MENU NAMI --
        Menu:addSubMenu(">> Nami: Config", "cfg")
            Menu.cfg:addParam("none", "--- (WIP) ---", SCRIPT_PARAM_INFO, "")
            Menu.cfg:addSubMenu("Customize " ..Qspell.name.. " (Q)", "qset")
            
            Menu.cfg:addSubMenu("Customize " ..Wspell.name.. " (W)", "wset")
                Menu.cfg.wset:addParam("use", "Use AutoHeal function?", SCRIPT_PARAM_ONOFF, true)
                Menu.cfg.wset:addParam("min", "Health in Percent to AutoHeal", SCRIPT_PARAM_SLICE, 50, 0, 100, 0)
                Menu.cfg.wset:addParam("mana", "Min. Mana to use AutoHeal", SCRIPT_PARAM_SLICE, 30, 0, 100, 0)
                for _, ally in pairs (GetAllyHeroes()) do
                    if not ally.isMe then
                    Menu.cfg.wset:addParam(tostring(ally.charName), "AutoHeal " ..tostring(ally.charName)..".", SCRIPT_PARAM_ONOFF, true)
                    end
                end
                Menu.cfg.wset:addParam("none", "----------------------------", SCRIPT_PARAM_INFO, "")
                Menu.cfg.wset:addParam("prio", "Ally > Nami", SCRIPT_PARAM_ONOFF, true)
                Menu.cfg.wset:addParam("none", "----------------------------", SCRIPT_PARAM_INFO, "")
                Menu.cfg.wset:addParam("attack", "Attack target > Autoheal", SCRIPT_PARAM_ONOFF, false)


            Menu.cfg:addSubMenu("Customize " ..Espell.name.. " (E)", "eset")
                Menu.cfg.eset:addParam("", "--- (WIP) ---", SCRIPT_PARAM_INFO, "")
                Menu.cfg.eset:addParam("none", "Make priority for ally champs", SCRIPT_PARAM_INFO, "")
                Menu.cfg.eset:addParam("none", "1 = low, 5 = high", SCRIPT_PARAM_INFO, "")
                for _, ally in pairs(GetAllyHeroes()) do
                    if not ally.isMe then
                        Menu.cfg.eset:addParam(tostring(ally.charName), "Prio " .. tostring(ally.charName)..":", SCRIPT_PARAM_SLICE, 1, 1, 5)
                    end
                end
                Menu.cfg.eset:addParam("", "-----------------", SCRIPT_PARAM_INFO, "")
                Menu.cfg.eset:addParam("ally", "If ally is next to target, use on ally", SCRIPT_PARAM_ONOFF, true)
                Menu.cfg.eset:addParam("nami", "Use on Nami, when in Range", SCRIPT_PARAM_ONOFF, true)
                Menu.cfg.eset:addParam("prio", "Prioritize ally Marksman?", SCRIPT_PARAM_ONOFF, true)
                
            
            
            Menu.cfg:addSubMenu("Customize " ..Rspell.name.. " (R)", "rset")
                Menu.cfg.rset:addParam("auto", "Use auto ultimate when", SCRIPT_PARAM_ONOFF, true)
                Menu.cfg.rset:addParam("count", ">= targets are hitable.", SCRIPT_PARAM_SLICE, 1, 1, 5)
                Menu.cfg.rset:addParam("gapcloser", "Use as gapcloser?", SCRIPT_PARAM_ONOFF, false)
                Menu.cfg.rset:addParam("gaprange", "Customize range for gapcloser:", SCRIPT_PARAM_SLICE, 100, 100, 500)
                Menu.cfg.rset:addSubMenu("Interrupt Spells", "interruptset")
                    Menu.cfg.rset.interruptset:addParam("none", "-----WIP-----", SCRIPT_PARAM_INFO, "")
                Menu.cfg.rset:addParam("none", "-----WIP-----", SCRIPT_PARAM_INFO, "")

            Menu.cfg:addSubMenu("Customize Combo", "combo")
                Menu.cfg.combo:addParam("useQ", "Use " ..Qspell.name.. " (Q)", SCRIPT_PARAM_ONOFF, true)
                Menu.cfg.combo:addParam("useW", "Use " ..Wspell.name.. " (W)", SCRIPT_PARAM_ONOFF, true)
                Menu.cfg.combo:addParam("useE", "Use " ..Espell.name.. " (E)", SCRIPT_PARAM_ONOFF, true)
                Menu.cfg.combo:addParam("useR", "Use " ..Rspell.name.. " (R)", SCRIPT_PARAM_ONOFF, false)
                Menu.cfg.combo:addParam("none", "Ultimate in Combo not recommended,", SCRIPT_PARAM_INFO, "")
                Menu.cfg.combo:addParam("none", "use ForceUlt or AutoUlt.", SCRIPT_PARAM_INFO, "")

            Menu.cfg:addSubMenu("Customize Harras", "harras")
                Menu.cfg.harras:addParam("mana", "Min. mana in %", SCRIPT_PARAM_SLICE, 40, 0, 100)
                Menu.cfg.harras:addParam("useQ", "Use " ..Qspell.name.. " (Q)", SCRIPT_PARAM_ONOFF, true)
                Menu.cfg.harras:addParam("useW", "Use " ..Wspell.name.. " (W)", SCRIPT_PARAM_ONOFF, false)
                Menu.cfg.harras:addParam("useE", "Use " ..Espell.name.. " (E)", SCRIPT_PARAM_ONOFF, false)
            Menu.cfg:addParam("focus", "Focus selected Target", SCRIPT_PARAM_ONOFF, false) 
            Menu.cfg:addParam("pred", "Choose your Prediction:", SCRIPT_PARAM_LIST, 1, {"HPred", "VPred"})


        Menu:addSubMenu(">> Nami: LaneClear", "fcfg")
            Menu.fcfg:addParam("none", "-----WIP-----", SCRIPT_PARAM_INFO, "")


        Menu:addSubMenu(">> Nami: JungleClear", "jcfg")
            Menu.jcfg:addParam("none", "-----WIP-----", SCRIPT_PARAM_INFO, "")

        Menu:addSubMenu(">> Nami: Item/Summoner", "icfg")
            Menu.icfg:addParam("none", "--- (WIP) ---", SCRIPT_PARAM_INFO, "")
            Menu.icfg:addParam("aZhon", "Use AutoZhonyas?", SCRIPT_PARAM_ONOFF, true)
            Menu.icfg:addParam("aZhonLife", "Health in % to use Zhonyas:", SCRIPT_PARAM_SLICE, 30, 0, 100)


        Menu:addSubMenu(">> Nami: Extras", "ecfg")
            if VIP_USER then
                Menu.ecfg:addParam("packet", "Use Packets (only VIP):", SCRIPT_PARAM_ONOFF, false)
            end


        Menu:addSubMenu(">> Nami: Key", "kcfg")
            Menu.kcfg:addParam("doharras", "Harras", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
            Menu.kcfg:addParam("docombo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
            Menu.kcfg:addParam("doforceult", "Force Ult to Target", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("T"))
            Menu.kcfg:addParam("dolane", "Lane Clear", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("V"))
            --Menu.kcfg:addParam("dojungle", "Jungle Clear", SCRIPT_PARAM_ONKEYDOWN, false,   string.byte("V"))

        


        Menu:addSubMenu(">> Nami: Drawings", "dcfg")
            Menu.dcfg:addSubMenu("Range", "range")
                Menu.dcfg.range:addParam("qdraw", "Draw Range for " ..Qspell.name.. " (Q):", SCRIPT_PARAM_ONOFF, true)
                Menu.dcfg.range:addParam("wdraw", "Draw Range for " ..Wspell.name.. " (W):", SCRIPT_PARAM_ONOFF, false)
                Menu.dcfg.range:addParam("edraw", "Draw Range for " ..Espell.name.. " (E):", SCRIPT_PARAM_ONOFF, true)
                Menu.dcfg.range:addParam("rdraw", "Draw Range for " ..Rspell.name.. " (R):", SCRIPT_PARAM_ONOFF, false)


        --Display Button
            Menu.kcfg:permaShow("docombo")
            Menu.kcfg:permaShow("doforceult")
            Menu.kcfg:permaShow("doharras")
            Menu.kcfg:permaShow("dolane")
end
------------------------------------------------------------FUNCTIONS----------------------------------------------------------------------
-- Checkupdate --
-- CheckUpdate by Aroc, credtis Aroc
function CheckUpdate()
    if autoupdate then
        local scriptName = "iSwearSheWasNami"
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
    print("<font color=\"#6699ff\"><b>" .. "iSwearSheWasNami" .. ":</b></font> <font color=\"#FFFFFF\">" .. message .. "</font>") 
end
-- End Checkupdate --
--[[------------------------------------------------------------------------------------------------------------------------------------
            o Soon
--------------------------------------------------------------------------------------------------------------------------------------]]
function OnLoad()
    Menu()
    DelayAction(function() CheckUpdate() end, 0.1)
    GetSida()
    HPredSkillShots()
    print("<b><font color=\"#6699ff\">iSwearSheWasNami:</font></b> <font color=\"#FFFFFF\">Enjoy guys!</font>")
end

-- Function HpredSkillshots()
function HPredSkillShots()
    HP_Q = HPSkillshot({type = "PromptCircle", delay = Qspell.delay, range = Qspell.range, radius = Qspell.radius, speed = Qspell.speed})
    HP_R = HPSkillshot({type = "DelayLine", delay = Rspell.delay, range = Rspell.range, speed = Rspell.speed, width = Rspell.width, collisionM = false, collisionH = false})
end

-- Function CustomLoad() - load Variables etc
function CustomLoad()
    if heroManager.iCount == 10 then
        arrangePrioritys()
    end
    -- GetSummoner()
end

-- Orbwalker Sac:R 
function GetSida()
	if _G.Reborn_Initialised then
		_G.AutoCarry.Keys:RegisterMenuKey(Menu.kcfg, "docombo", AutoCarry.MODE_AUTOCARRY) -- AutoCarry Key
		_G.AutoCarry.Keys:RegisterMenuKey(Menu.kcfg, "doharras", AutoCarry.MODE_MIXEDMODE) -- Harras Key
		_G.AutoCarry.Keys:RegisterMenuKey(Menu.kcfg, "dolane", AutoCarry.MODE_LANECLEAR) -- LaneClear Key
		-- _G.AutoCarry.Keys:RegisterMenuKey() -- LastHit Key
		_G.AutoCarry.Keys:RegisterKey(string.byte("X"), AutoCarry.MODE_LASTHIT)
	elseif _G.Reborn_Loaded then
		 DelayAction(GetSida, 2)
	end
end

-- Function ArrangePrioritys()
function arrangePrioritys()
	for i, enemy in ipairs(GetEnemyHeroes()) do
		SetPriority(TargetTable.AD_Carry, enemy, 1)
		SetPriority(TargetTable.AP, enemy, 2)
		SetPriority(TargetTable.Support, enemy, 3)
		SetPriority(TargetTable.Bruiser, enemy, 4)
		SetPriority(TargetTable.Tank, enemy, 5)
	end
end

-- Function SetPriority()
function SetPriority(table, hero, priority)
	for i=1, #table, 1 do
		if hero.charName:find(table[i]) ~= nil then
			TS_SetHeroPriority(priority, hero.charName)
		end
	end
end

-- Function Check()
function Check()
    myTarget = TargetSelector.target
    if mySelectedTarget ~= nil and not mySelectedTarget.dead and ValidTarget(mySelectedTarget, 1500) then
        myTarget = mySelectedTarget
    elseif myTarget ~= nil and ValidTarget(myTarget, 1500) then
        local prioTarget = nil
        for _, enemy in ipairs(GetEnemyHeroes()) do
            if GetDistance(enemy, myHero) <= 1500 and ValidTarget(enemy, 1500) then
		        if prioTarget == nil then
                    prioTarget = enemy
                elseif TS_GetPriority(enemy) < TS_GetPriority(prioTarget) then
                    prioTarget = enemy
                end
            end
        end
        myTarget = prioTarget
    else
        myTarget = GetTarget()
    end
end

-- Function GetTarget()
function GetTarget()
	TargetSelector:update()
	if _G.Reborn_Loaded then
		if _G.AutoCarry and _G.AutoCarry.Crosshair and _G.AutoCarry.Attack_Crosshair and _G.AutoCarry.Attack_Crosshair.target then
			return _G.AutoCarry.Attack_Crosshair.target		
		end
	end
	return TargetSelector.target
end

-- Function OnTick()
function OnTick()
    Check()
    if myTarget ~= nil and Menu.kcfg.doharras and not isRecalling then
        Harras()
    end
    if myTarget ~= nil and Menu.kcfg.docombo and not isRecalling then
        Combo()
    end
    --AutoHeal() in Range
    if not isRecalling and Menu.cfg.wset.use and not Menu.kcfg.doharras and not Menu.kcfg.docombo then
        AutoHeal()
    end
    --ForceUlt()
    if myTarget ~= nil and not isRecalling and Menu.kcfg.doforceult then
        myHero:MoveTo(mousePos.x, mousePos.z)
        myHero:Attack(myTarget)
        castR(myTarget, 1)
    end
    --AutoUlt()
    if myTarget ~= nil and not isRecalling and Menu.cfg.rset.auto then
        AutoUlt()
    end
    --AutoZhonyas
    if Menu.icfg.aZhon and not isRecalling then
        UseZhonyas()
    end
end

-- Function CastQ()
function castQ(unit)
    if unit == nil then return end
    if Qspell.Ready() and ValidTarget(unit, Qspell.range) then
        if Menu.cfg.pred == 1 then
            local QPos, QHitChance = HP:GetPredict(HP_Q, unit, myHero)
            if QHitChance >= 1.3 then
                if VIP_USER and Menu.ecfg.packet then
                    Packet("S_CAST", {spellId = _Q, toX = QPos.x, toY = QPos.z, fromX = QPos.x, fromY = QPos.z}):send()
                else
                    CastSpell(_Q, QPos.x, QPos.z)
                end
            end
        elseif Menu.cfg.pred == 2 then
            AOECastPosition, MainTargetHitChance, nTargets = VP:GetCircularAOECastPosition(unit, Qspell.delay, Qspell.radius, Qspell.range, nil, myHero)
            if MainTargetHitChance >= 2 and nTargets >=1 then
                if VIP_USER and Menu.ecfg.packet then
                    Packet("S_CAST", {spellId = _Q, toX = AOECastPosition.x, toY = AOECastPosition.z, fromX = AOECastPosition.x, fromY = AOECastPosition.z}):send()
                else
                    CastSpell(_Q, AOECastPosition.x, AOECastPosition.z)
                end
            end
        end
    end    
end

-- Function CastW()
function castW(unit)
    if unit == nil then return end
    if Wspell.Ready() then
        CastSpell(_W, unit)
    end
end

-- Function CastE()
function castE(unit)
    if unit == nil then return end
    if Espell.Ready() and unit.team == myHero.team and GetDistance(myHero, unit) <= Espell.range then
        CastSpell(_E, unit)
    end
end

-- Function CastR()
function castR(unit, nHit)
    if unit == nil then return end
    if nHit == nil then nHit = 1 end
    if Rspell.Ready() and GetDistance(myHero, unit) <= Rspell.range then
        if Menu.cfg.pred == 1 then
            RPos, RHitChance = HP:GetPredict(HP_R, unit, myHero)
            if RHitChance > 0 then
                if VIP_USER then
                    Packet("S_CAST", {spellId = _R, toX = RPos.x, toY = RPos.z, fromX = RPos.x, fromY = RPos.z}):send()
                else 
                    CastSpell(_R, RPos.x, RPos.z)
                end 
            end
        elseif Menu.cfg.pred == 2 then
            AOECastPosition, MainTargetHitChance, nTargets = VP:GetLineAOECastPosition(unit, 0.25, Rspell.width, Rspell.range, 859, myHero)
            if MainTargetHitChance >= 2 or nTargets >= nHit then
                if VIP_USER and Menu.ecfg.packet then
                    Packet("S_CAST", {spellId = _R, toX = AOECastPosition.x, toY = AOECastPosition.z, fromX = AOECastPosition.x, fromY = AOECastPosition.z}):send()
                else
                    CastSpell(_R, AOECastPosition.x, AOECastPosition.z)
                end
            end
        end
    end
end

-- Function Harras()
function Harras()
    if (myHero.mana/myHero.maxMana)*100 >= Menu.cfg.harras.mana then
        if Menu.cfg.harras.useQ and GetDistance(myHero, myTarget) <= Qspell.range then
            castQ(myTarget)
        end
        if Menu.cfg.harras.useE then
            if CountAlly(1200) == 0 and GetDistance(myHero, myTarget) <= AArange then
                castE(myHero)
            else
                AutoTidecaller()
            end
        end
        if Menu.cfg.harras.useW then
            if Menu.cfg.wset.attack then
                castW(myTarget)
            else
                AutoHeal()
                CastW(myTarget)
            end
        end
    end
end

-- Function Combo()
function Combo()
        if Menu.cfg.combo.useQ and GetDistance(myHero, myTarget) <= Qspell.range then
            castQ(myTarget)
        end
        if Menu.cfg.combo.useE then
            if CountAlly(1200) == 0 and GetDistance(myHero, myTarget) <= AArange then
                castE(myHero)
            else
                AutoTidecaller()
            end
        end
        if Menu.cfg.combo.useW then
            if Menu.cfg.wset.attack then
                castW(myTarget)
            else
                AutoHeal()
                castW(myTarget)
            end
        end
        if Menu.cfg.combo.useR then
           castR(myTarget, 1) 
        end
end
-- Function AutoHeal()
function AutoHeal()
    if GetDistance(myHero, GetSpawnPos()) <= 1200 then return end
    for _, ally in pairs(GetAllyHeroes()) do
        if ally ~= nil and not ally.dead and GetDistance(myHero, ally) <= Wspell.range then
            if Menu.cfg.wset.prio then
                if Menu.cfg.wset[ally.charName] and (ally.health/ally.maxHealth)*100 <= Menu.cfg.wset.min and not ally.isMe then
                    castW(ally)
                elseif (myHero.health/myHero.maxHealth)*100 <= Menu.cfg.wset.min then
                    castW(myHero)
                end
            elseif (myHero.health/myHero.maxHealth)*100 <= Menu.cfg.wset.min then
                castW(myHero)
            end
        end
    end
end

-- Function GetTBChamp(); will return an ally on which Nami casts Tidecaller's Blessing; unit == "none" will check for allies and enemies in range
function GetTBChamp(unit)
    if unit == nil then return end
    if unit == "none" then
        local champ, prio = nil, 0
        for _, enemy in pairs(GetEnemyHeroes()) do
            if enemy ~= nil and not enemy.dead and GetDistance(enemy, myHero) <= 1200 then
                for _, ally in pairs(GetAllyHeroes()) do
                    if ally ~= nil and not ally.dead then
                        if GetAllyMarksman(ally) and Menu.cfg.eset.prio and GetDistance(ally, myHero) <= Espell.range then
                            return ally
                        elseif Menu.cfg.eset.ally then
                            if CountAlly(1200) >=2 then
                                champ, prio = GetAllyTBPrio(ally, Menu.cfg.eset[ally.charName])
                                print(champ.charName)
                                return champ
                            elseif GetDistance(ally, enemy) <= 1200 then
                                return ally
                            end
                        elseif Menu.cfg.eset.nami and GetDistance(enemy, myHero) <= Espell.range then
                            return myHero
                        end
                    end
                end
            end
        end
    elseif not unit.dead and GetDistance(unit, myHero) <= 1200 then
        local champ, prio = nil, 0
        for _, ally in pairs(GetAllyHeroes()) do
            if ally ~= nil and not ally.dead then
                if GetAllyMarksman(ally) and Menu.cfg.eset.prio then
                    champ = GetAllyMarksman(ally)
                    --return GetAllyMarksman(ally)
                elseif Menu.cfg.eset.ally then
                    if CountAlly(1200) >=2 then
                        champ, prio = GetAllyTBPrio(ally, Menu.cfg.eset[ally.charName])
                        --return champ
                    elseif GetDistance(ally, unit) <= 1200 then
                        champ = ally
                        --return ally
                    end
                end
            end
        end
        if champ == nil then champ = myHero end
        --print(champ.charName)
        return champ    
    end    
end
--Function GetAllyMarksman(unit)
function GetAllyMarksman(unit)
    if unit == nil then return end
    for i=1, #AD_Carries, 1 do
        if unit.charName:find(AD_Carries[i]) ~= nil then
            return unit
        end
        for _, ally in pairs(GetAllyHeroes()) do
            if ally ~= nil and not ally.dead and GetDistance(myHero, ally) <= Espell.range then
                if ally.charName:find(AD_Carries[i]) ~= nil then
                    return ally
                end
            end
        end
    end
end
-- Function GetAllyTBPrio(unit, prio)
function GetAllyTBPrio(unit, prio)
    if unit == nil or prio == nil then return end
    local champ, champPrio = nil, 0
    for _, ally in pairs(GetAllyHeroes()) do
        if ally ~= nil and not ally.dead and ally ~= unit and Menu.cfg.eset[ally.charName] > prio and GetDistance(ally, myHero) <= 1500 and GetDistance(unit, ally) <= 800 then
            champ = ally
            champPrio = Menu.cfg.eset[ally.charName]
        elseif ally ~= nil and not ally.dead and ally == unit and GetDistance(myHero, ally) <= 1500 then
            champ = unit
            champPrio = prio
        end
    end
    return champ, champPrio
end

--Function AutoTidecaller()
function AutoTidecaller()
    for _, ally in pairs(GetAllyHeroes()) do
        if ally ~= nil and not ally.dead and GetDistance(myHero, ally) <= Espell.range then
            local champ = GetTBChamp(ally)
            --print(champ.charName)
            --print("test")
            castE(champ)
        end
    end
   --[[ if Menu.cfg.eset.nami and CountAlly(1200) == 0 then
        castE(myHero)
    end --]]
end

-- Function GetBestUltTarget(); returns a Hero and number of hitable targets
function GetBestUltTarget(unit)
    if unit == nil then return end
    local BestUnit, maxHit = nil, 0
    if BestUnit == nil then
        for _, enemy in pairs(GetEnemyHeroes()) do
            if enemy ~= nil and not enemy.dead and ValidTarget(enemy, Rspell.range) then
                if GetUltMaxHit(unit) >= GetUltMaxHit(enemy) then
                    BestUnit = unit
                    maxHit = GetUltMaxHit(unit)
                else
                    BestUnit = enemy
                    maxHit = GetUltMaxHit(enemy)
                end
            end
        end
        return BestUnit, maxHit
    end
end

-- Function GetUltMaxHit()
function GetUltMaxHit(unit)
    if unit == nil then return end
    local Hits = 0
    for _, enemy in pairs(GetEnemyHeroes()) do
        if enemy ~= nil and not enemy.dead and GetDistance(enemy, myHero) <= Rspell.range then
            if GetDistance(enemy, unit) <= (Rspell.width-112) then
                Hits = Hits+1
            end
        end
    end
    if Hits > 0 then
        return Hits
    end
end

-- Function AutoUlt()
function AutoUlt()
    if CountAlly(1200) == 0 then return end
    local champ, Hits = GetBestUltTarget(myTarget)
    if champ ~= nil and Hits ~= nil then
        if Hits >= Menu.cfg.rset.count and GetDistance(myHero, champ) <= Rspell.range then
            castR(champ, Hits)
            --print("AutoUlt Casted")
        end
    end
end

-- Function CountEnemy()
function CountEnemy(range)
    local counter = 0
    for j, enemy in ipairs(GetEnemyHeroes()) do
        if enemy ~= nil and ValidTarget(enemy, range) then
            counter = counter + 1
        end
    end
    return counter
end

-- Function CountAlly(range)
function CountAlly(range)
    local counter = 0
    for _, ally in ipairs(GetAllyHeroes()) do
        if ally ~= nil and GetDistance(ally, myHero) <= range then
            counter = counter + 1
        end
    end
    return counter
end

function UseZhonyas()
	local Slot = GetInventorySlotItem(3157)
	if Slot ~= nil and myHero:CanUseSpell(Slot) == READY then
		if ((myHero.health/myHero.maxHealth)*100) <= Menu.icfg.aZhonLife then
			CastSpell(Slot)
		end
	end
end


--[[------------------------------------------------------------------------------------------------------------------------------------

                                                            FARM

--------------------------------------------------------------------------------------------------------------------------------------]]
function LaneClear()

end

function JungleClear()

end

function GetQPosition(unit)

end

--[[------------------------------------------------------------------------------------------------------------------------------------

                                                           END FARM

--------------------------------------------------------------------------------------------------------------------------------------]]
--[[------------------------------------------------------------------------------------------------------------------------------------

                                                            OTHER CALLBACKS

--------------------------------------------------------------------------------------------------------------------------------------]]
-- Function OnDraw(), draw ranges of spells
function OnDraw()
    if myHero.dead then return end
    if Qspell.Ready() and Menu.dcfg.range.qdraw then
        DrawCircle3D(myHero.x, myHero.y, myHero.z, Qspell.range, 1, ARGB(255,255,0,0), 50)
    end
    if Wspell.Ready() and Menu.dcfg.range.wdraw then
        DrawCircle3D(myHero.x, myHero.y, myHero.z, Wspell.range, 1, ARGB(255,255,0,0), 50)
    end
    if Espell.Ready() and Menu.dcfg.range.edraw then
        DrawCircle3D(myHero.x, myHero.y, myHero.z, Espell.range, 1, ARGB(255,255,0,0), 50)
    end
    if Rspell.Ready() and Menu.dcfg.range.rdraw then
        DrawCircle3D(myHero.x, myHero.y, myHero.z, Rspell.range, 1, ARGB(255,255,0,0), 50)
    end
    if mySelectedTarget ~= nil and not mySelectedTarget.dead then
        local heroPos = WorldToScreen(D3DXVECTOR3(mySelectedTarget.x, mySelectedTarget.y, mySelectedTarget.z))
        local xPos = heroPos.x
        local yPos = heroPos.y
        DrawText("*", 80, xPos, yPos, ARGB(255,255,204,0))
    end
end

-- Function OnWndMsg(msg,wParam)
function OnWndMsg(msg, key)
    if msg == WM_LBUTTONDOWN and Menu.cfg.focus then
        local selectedTarget, distance = nil, 0
        for _, enemy in pairs(GetEnemyHeroes()) do
            if enemy ~= nil and ValidTarget(enemy) then
                if selectedTarget == nil or GetDistance(mousePos, enemy) <= distance then
                    selectedTarget = enemy
                    distance = GetDistance(mousePos, enemy)
                end 
            end
        end
        --- Check Unselect/select a target
        if selectedTarget and distance < 300 then
            if mySelectedTarget and selectedTarget.charName == mySelectedTarget.charName then
                mySelectedTarget = nil
                print("<font color=\"#6699ff\"><b>iSwearSheWasNami:</b></font> <font color=\"#FFFFFF\">Target unselected.</font>")
            else
                mySelectedTarget = selectedTarget
                print("<font color=\"#6699ff\"><b>iSwearSheWasNami:</b></font> <font color=\"#FFFFFF\">Target selected.</font>")
            end

        end
    end
end

-- Function OnCreateObj(object); OnDeleteObj(object)
function OnCreateObj(object)

end

function OnDeleteObj(object)

end

function OnApplyBuff(unit, source, buff)
--[[if source ~= nil and source.isMe and buff and buff.name then
    print("Buff Name: " ..buff.name)
end]]--
    if unit and unit.isMe and buff and buff.name == "recall" then
        isRecalling = true
    end
end

function OnRemoveBuff(unit, buff)
    if unit and unit.isMe and buff and buff.name == "recall" then
        isRecalling = false
    end
end

--[[------------------------------------------------------------------------------------------------------------------------------------

                                                            CLASS SCRIPTUPDATE
                                                            CREDITS GO TO AROC <3

--------------------------------------------------------------------------------------------------------------------------------------]]
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
--[[------------------------------------------------------------------------------------------------------------------------------------

                                                          END SCRIPT

--------------------------------------------------------------------------------------------------------------------------------------]]
