local mod	= DBM:NewMod("Thorim", "DBM-Ulduar")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20230818114428")
mod:SetCreatureID(32865)
mod:SetUsedIcons(7)

mod:RegisterCombat("combat_yell", L.YellPhase1)
mod:RegisterKill("yell", L.YellKill)

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 62042 62597 62605 64390 62131",
	"SPELL_CAST_SUCCESS 62042 62466 62279 62130 62580 62604",
	"SPELL_AURA_APPLIED 62042 62507 62130 62526 62527 62279",
	"SPELL_AURA_APPLIED_DOSE 62279",
	"SPELL_AURA_REMOVED 62507",
	"SPELL_DAMAGE 62017",
	"CHAT_MSG_MONSTER_YELL"
)

-- General
local enrageTimerStage1				= mod:NewBerserkTimer(300, nil, DBM_CORE_L.GENERIC_TIMER_BERSERK..": "..DBM_CORE_L.SCENARIO_STAGE:format(1)) -- REVIEW! Need log to validate, only used Wowhead as reference
local enrageTimerStage2				= mod:NewBerserkTimer(300, nil, DBM_CORE_L.GENERIC_TIMER_BERSERK..": "..DBM_CORE_L.SCENARIO_STAGE:format(2)) -- REVIEW! Need log to validate, only used Wowhead as reference
mod:AddRangeFrameOption("8")

-- Stage One
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(1))
local warnStormhammer				= mod:NewTargetNoFilterAnnounce(62042, 2)
local warnRuneDetonation			= mod:NewTargetNoFilterAnnounce(62526, 4)

local specWarnRuneDetonation		= mod:NewSpecialWarningClose(62526, nil, nil, nil, 1, 2)
local yellRuneDetonation			= mod:NewYell(62526)
local specWarnLightningShock		= mod:NewSpecialWarningMove(62017, nil, nil, nil, 1, 2)

local timerStormhammerCast			= mod:NewCastTimer(2, 62042, nil, nil, nil, 3)
local timerStormhammerCD			= mod:NewCDTimer(14.2, 62042, nil, nil, nil, 3, nil, nil, true) -- ~5s variance. Added "keep" arg (25 man NM log 2022/07/10 || 25 man HM log 2022/07/17 || 25m Lordaeron 2022/10/09) - 16.2, 15.5, 16.8, 19.4, 17.8, 15.5, 16.8 || 16.9, 17.7, 18.0, 14.8 || 15.1, 16.2, 17.0, 14.2, 16.1, 15.6, 15.8

mod:AddSetIconOption("SetIconOnRuneDetonation", 62527, false, false, {7})

-- Stage Two
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(2))
local warnPhase2					= mod:NewPhaseAnnounce(2, 1, nil, nil, nil, nil, nil, 2)
local warnLightningCharge			= mod:NewSpellAnnounce(62466, 2)

local specWarnUnbalancingStrikeSelf	= mod:NewSpecialWarningDefensive(62130, nil, nil, nil, 1, 2)
local specWarnUnbalancingStrike		= mod:NewSpecialWarningTaunt(62130, nil, nil, nil, 1, 2)

local timerLightningCharge			= mod:NewCDTimer(15.2, 62466, nil, nil, nil, 3) -- ~2s variance. (25 man NM log 2022/07/10 || 25 man HM log 2022/07/17 || 25 man Lordaeron 20222/10/30) - ? || ? || 16.7, 15.3, 16.1, 15.9
local timerUnbalancingStrike		= mod:NewCDTimer(19.6, 62130, nil, "Tank", nil, 5, nil, DBM_COMMON_L.TANK_ICON) -- ~12s variance (25 man NM log 2022/07/10 || 25 man HM log 2022/07/17) - 24.9, 31.4, 31.8, 26.7 || 27.7, 28.5, 19.6, 26.5, 21.5, 28.6, 21.1, 28.5, 26.9
local timerChainLightning			= mod:NewNextTimer(10.2, 64390) -- ~5s variance (25 man NM log 2022/07/10 || 25 man HM log 2022/07/17) - 14.5, 13.3, 13.8, 14.7, 10.3, 14.8, 10.3, 13.3, 12.4 || 12.3, 10.2, 14.4, 14.9, 12.5, 11.0, 14.4, 12.2, 13.4, 12.3, 11.6, 12.8, 10.6, 12.2, 10.3, 14.1

mod:AddBoolOption("AnnounceFails", false, "announce", nil, nil, nil, 62466)

-- Hard Mode
mod:AddTimerLine(DBM_COMMON_L.HEROIC_ICON..DBM_CORE_L.HARD_MODE)
local specWarnHardModeFailed		= mod:NewSpecialWarningEnd(62507, nil, nil, nil, 1, 2)

local timerHardmode					= mod:NewTimer(150, "TimerHardmode", "Interface\\Icons\\achievement_boss_thorim", nil, nil, 0, nil, nil, nil, nil, nil, nil, nil, 62507) -- 25 man NM log review (2022/07/10), 2:30 from 62507 SPELL_AURA_APPLIED to SPELL_AURA_REMOVED
local timerFrostNova				= mod:NewNextTimer(10.4, 62605, nil, nil, nil, 2, nil, DBM_COMMON_L.MAGIC_ICON) -- ~10s variance (25 man HM log 2022/07/17) - 16.0, 13.1, 16.6, 11.8, 14.4, 13.6, 20.3, 10.4, 19.0, 18.3, 19.8, 13.0, 12.4
local timerFrostNovaCast			= mod:NewCastTimer(2.5, 62605, nil, nil, nil, 2, nil, DBM_COMMON_L.MAGIC_ICON)
local timerFBVolley					= mod:NewCDTimer(8.0, 62604) -- ~8s variance (25 man HM log 2022/07/17) - 8.6, 15.1, 9.3, 14.3, 9.6, 8.0, 9.9, 13.4, 8.0, 9.8, 16.0, 12.3, 9.5, 16.2, 9.9, 8.1, 11.4, 8.0, 9.0

--mod:GroupSpells(62042, 62470) -- Stormhammer, Deafening Thunder
mod:GroupSpells(62526, 62527) -- Rune of Detonation

local lastcharge = {}

function mod:OnCombatStart()
	self:SetStage(1)
	enrageTimerStage1:Start()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Show(8)
	end
	table.wipe(lastcharge)
end

local sortedFailsC = {}
local function sortFails1C(e1, e2)
	return (lastcharge[e1] or 0) > (lastcharge[e2] or 0)
end

function mod:OnCombatEnd()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
	if self.Options.AnnounceFails and DBM:GetRaidRank() >= 1 then
		local lcharge = ""
		for k, _ in pairs(lastcharge) do
			table.insert(sortedFailsC, k)
		end
		table.sort(sortedFailsC, sortFails1C)
		for _, v in ipairs(sortedFailsC) do
			lcharge = lcharge.." "..v.."("..(lastcharge[v] or "")..")"
		end
		SendChatMessage(L.Charge:format(lcharge), "RAID")
		table.wipe(sortedFailsC)
	end
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 62042 then
		timerStormhammerCast:Start()
	elseif args:IsSpellID(62597, 62605) then	-- Frost Nova by Sif
		timerFrostNovaCast:Start()
		timerFrostNova:Start()
	elseif args:IsSpellID(64390, 62131) then	-- Chain Lightning by Thorim
		timerChainLightning:Start()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 62042 then		-- Stormhammer. Never fires on Warmane, nor existed on 2010 code
		DBM:AddMsg("Stormhammer unhidden from combat log. Notify Zidras on Discord or GitHub")
		timerStormhammerCD:Schedule(2)
	elseif args:IsSpellID(62466, 62279) then	-- Lightning Charge
		DBM:AddMsg("Lightning Charge unhidden from combat log. Notify Zidras on Discord or GitHub")
		warnLightningCharge:Show()
		timerLightningCharge:Start()
	elseif spellId == 62130 then	-- Unbalancing Strike
		timerUnbalancingStrike:Start()
	elseif args:IsSpellID(62580, 62604) then	-- Frostbolt Volley by Sif
		timerFBVolley:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 62042 and self:CheckBossDistance(args.sourceGUID, true, 34471) then	-- Stormhammer. Within range of Vial of the Sunwell (43) -- CheckBossDistance prone to fail since boss frame is only created on Stage 2 and the fallback would require raidtarget to be Thorim, which there is really no point in. Even if it fails 99% of the time, it returns true regardless so keep it
		warnStormhammer:Show(args.destName)
		timerStormhammerCD:Start()
	elseif spellId == 62507 then				-- Touch of Dominion
		timerHardmode:Start()
	elseif spellId == 62130 then				-- Unbalancing Strike
		if args:IsPlayer() then
			specWarnUnbalancingStrikeSelf:Show()
			specWarnUnbalancingStrikeSelf:Play("defensive")
		else
			specWarnUnbalancingStrike:Show(args.destName)
			specWarnUnbalancingStrike:Play("tauntboss")
		end
	elseif args:IsSpellID(62526, 62527) then	-- Rune Detonation
		if args:IsPlayer() then
			yellRuneDetonation:Yell()
		elseif self:CheckNearby(10, args.destName) then
			specWarnRuneDetonation:Show(args.destName)
			specWarnRuneDetonation:Play("runaway")
		elseif self:CheckBossDistance(args.sourceGUID, true, 1180) then	--Within Scroll of Stamina range (33) -- CheckBossDistance prone to fail since boss frame is only created on Stage 2 and the fallback would require raidtarget to be Thorim, which there is really no point in. Even if it fails 99% of the time, it returns true regardless so keep it
			warnRuneDetonation:Show(args.destName)
		end
		if self.Options.SetIconOnRuneDetonation then
			self:SetIcon(args.destName, 7, 5)
		end
	elseif spellId == 62279 then	-- Lightning Charge
		warnLightningCharge:Show()
		timerLightningCharge:Start()
	end
end

function mod:SPELL_AURA_APPLIED_DOSE(args)
	if args.spellId == 62279 then	-- Lightning Charge
		warnLightningCharge:Show()
		timerLightningCharge:Start()
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 62507 then -- Touch of Dominion removed from Sif, Hard Mode failed
        specWarnHardModeFailed:Show()
    end
end

function mod:SPELL_DAMAGE(_, _, _, _, destName, destFlags, spellId)
	if spellId == 62017 then -- Lightning Shock
		if bit.band(destFlags, COMBATLOG_OBJECT_AFFILIATION_MINE) ~= 0
		and bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) ~= 0
		and self:AntiSpam(5, 1) then
			specWarnLightningShock:Show()
			specWarnLightningShock:Play("runaway")
		end
	elseif spellId == 62466 and self.Options.AnnounceFails and DBM:GetRaidRank() >= 1 and DBM:GetRaidUnitId(destName) ~= "none" and destName then
		lastcharge[destName] = (lastcharge[destName] or 0) + 1
		SendChatMessage(L.ChargeOn:format(destName), "RAID")
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.YellPhase2 or msg:find(L.YellPhase2) then		-- Bossfight (tank and spank)
		self:SendSync("Phase2")
	-- elseif msg == L.YellKill or msg:find(L.YellKill) then
	--	enrageTimer:Stop()
	end
end

function mod:OnSync(event)
	if event == "Phase2" and self.vb.phase < 2 then
		self:SetStage(2)
		warnPhase2:Show()
		warnPhase2:Play("ptwo")
		enrageTimerStage1:Stop()
		timerHardmode:Stop()
		enrageTimerStage2:Start(300)
		timerLightningCharge:Start(35.6) -- (S3 VOD review 2022/07/15, reconfirmed with S3 FM HM log 2022/07/17 || 25m Lordaeron 2022/10/09) - 36 || 35.6
	end
end
