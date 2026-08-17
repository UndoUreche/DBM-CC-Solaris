local mod	= DBM:NewMod("GeneralVezax", "DBM-Ulduar")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20230221144717")
mod:SetCreatureID(33271)
mod:SetUsedIcons(7, 8)

mod:RegisterCombat("yell", L.YellStart)

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 62661 62662",
	"SPELL_CAST_SUCCESS 62660 63276 63364",
	"SPELL_AURA_APPLIED 62662",
	"SPELL_AURA_REMOVED 62662",
	"SPELL_INTERRUPT 62661",
	"UNIT_DIED",
	"CHAT_MSG_RAID_BOSS_EMOTE"
--	"UNIT_SPELLCAST_START boss1",
--	"UNIT_SPELLCAST_SUCCEEDED boss1"
)

local warnShadowCrash				= mod:NewTargetAnnounce(62660, 4)
local warnLeechLife					= mod:NewTargetNoFilterAnnounce(63276, 3)
local warnSaroniteVapor				= mod:NewCountAnnounce(63322, 2)

local specWarnShadowCrash			= mod:NewSpecialWarningDodge(62660, nil, nil, nil, 1, 2)
local yellShadowCrash				= mod:NewYell(62660)
local specWarnSurgeDarkness			= mod:NewSpecialWarningDefensive(62662, nil, nil, 2, 1, 2)
local specWarnMarkoftheFacelessYou	= mod:NewSpecialWarningMoveAway(63276, nil, nil, nil, 3, 2)
local yellMarkoftheFaceless			= mod:NewYell(63276)
local specWarnMarkoftheFacelessNear	= mod:NewSpecialWarningClose(63276, nil, nil, 2, 1, 2)
--local specWarnSearingFlames			= mod:NewSpecialWarningInterruptCount(62661, "HasInterrupt", nil, nil, 1, 2) -- replacing this with a regular interrupt because groups can have varying numbers of interrupters
local specWarnSearingFlames			= mod:NewSpecialWarningInterrupt(62661, "HasInterrupt", nil, nil, 1, 2)

local timerEnrage					= mod:NewBerserkTimer(600)
local timerSearingFlamesCast		= mod:NewCastTimer(2, 62661, nil, nil, nil, 5, nil, DBM_COMMON_L.INTERRUPT_ICON)
local timerSurgeofDarkness			= mod:NewBuffActiveTimer(10, 62662, nil, "Tank", nil, 5, nil, DBM_COMMON_L.TANK_ICON)
local timerNextSurgeofDarkness		= mod:NewNextTimer(63, 62662, nil, "Tank", nil, 5, nil, DBM_COMMON_L.TANK_ICON)
local timerSaroniteVapors			= mod:NewNextCountTimer(30, 63322, nil, nil, nil, 5, nil, DBM_COMMON_L.HEALER_ICON)
local timerShadowCrashCD			= mod:NewNextTimer(10, 62660, nil, "Ranged", nil, 3)
local timerMarkoftheFaceless		= mod:NewTargetTimer(10, 63276, nil, false, 2, 3, nil, DBM_COMMON_L.IMPORTANT_ICON)
local timerMarkoftheFacelessCD		= mod:NewNextTimer(40, 63276, nil, nil, nil, 3, nil, DBM_COMMON_L.IMPORTANT_ICON)

mod:AddSetIconOption("SetIconOnShadowCrash", 62660, true, false, {8})
mod:AddSetIconOption("SetIconOnLifeLeach", 63276, true, false, {7})
mod:AddArrowOption("CrashArrow", 62660, true)

-- Hard Mode
mod:AddTimerLine(DBM_COMMON_L.HEROIC_ICON..DBM_CORE_L.HARD_MODE)
local specWarnAnimus			= mod:NewSpecialWarningSwitch(63145, nil, nil, nil, 1, 2)

local timerHardmode				= mod:NewTimer(186, "hardmodeSpawn", nil, nil, nil, 1) -- S3 VOD review 2022/07/15

--mod.vb.interruptCount = 0
mod.vb.vaporsCount = 0

function mod:OnCombatStart(delay)
	--self.vb.interruptCount = 0
	self.vb.vaporsCount = 0
	
	timerShadowCrashCD:Start(13-delay)
	timerMarkoftheFacelessCD:Start(20-delay) 
	timerNextSurgeofDarkness:Start(63.0-delay)
	timerSaroniteVapors:Start(30.0-delay, 1)
	
	timerEnrage:Start(-delay)
	timerHardmode:Start(-delay)
end

function mod:SPELL_CAST_START(args)
	local spellId = args.spellId
	if spellId == 62661 then	-- Searing Flames
		
		--[[self.vb.interruptCount = self.vb.interruptCount + 1
		if self.vb.interruptCount == 4 then
			self.vb.interruptCount = 1
		end
		local kickCount = self.vb.interruptCount
		specWarnSearingFlames:Show(args.sourceName, kickCount)
		specWarnSearingFlames:Play("kick"..kickCount.."r")]]
		
		specWarnSearingFlames:Show(args.sourceName)
		specWarnSearingFlames:Play("kickcast")
		timerSearingFlamesCast:Start()
	elseif spellId == 62662 then
		if self:IsTanking("player", DBM:GetUnitIdFromCID(33271, false), nil, true) then
			specWarnSurgeDarkness:Show()
			specWarnSurgeDarkness:Play("defensive")
		end
		timerNextSurgeofDarkness:Start()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 62660 then		-- Shadow Crash
		timerShadowCrashCD:Start()
		if self.Options.SetIconOnShadowCrash then
			self:SetIcon(args.destName, 8, 5)
		end
		if args:IsPlayer() or self:CheckNearby(11, args.destName) then
			specWarnShadowCrash:Show()
			specWarnShadowCrash:Play("runaway")
			yellShadowCrash:Yell()
		else
			warnShadowCrash:Show(args.destName)
		end
		
		if self.Options.CrashArrow then
			local uId = DBM:GetRaidUnitId(args.destName)
			local x, y = GetPlayerMapPosition(uId)
			if x == 0 and y == 0 then
				SetMapToCurrentZone()
				x, y = GetPlayerMapPosition(uId)
			end
			DBM.Arrow:ShowRunAway(x, y, 13, 5) -- warmane 13 yards, not tested for cc
		end
	elseif spellId == 63276 then	-- Mark of the Faceless
		if self.Options.SetIconOnLifeLeach then
			self:SetIcon(args.destName, 7, 10)
		end
		timerMarkoftheFaceless:Start(args.destName)
		timerMarkoftheFacelessCD:Start()
		if args:IsPlayer() then
			specWarnMarkoftheFacelessYou:Show()
			specWarnMarkoftheFacelessYou:Play("runout")
			yellMarkoftheFaceless:Yell()
		elseif self:CheckNearby(11, args.destName) then
			specWarnMarkoftheFacelessNear:Show(args.destName)
			specWarnMarkoftheFacelessNear:Play("runaway")
		else
			warnLeechLife:Show(args.destName)
		end
	elseif spellId == 63364 then
		specWarnAnimus:Show()
		specWarnAnimus:Play("bigmob")
	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 62662 then	-- Surge of Darkness
		timerSurgeofDarkness:Start()
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 62662 then
		timerSurgeofDarkness:Stop()
	end
end

function mod:SPELL_INTERRUPT(args)
	if args.spellId == 62661 then
		timerSearingFlamesCast:Stop()
	end
end

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 33488 then--Saronite Vapor
		timerHardmode:Stop()
	end
end

-- Range restriced, not reliable enough to sync CHAT_MSG_RAID_BOSS_EMOTE, so a repeating schedule was implemented instead and emote is only used for timer correction.
function mod:CHAT_MSG_RAID_BOSS_EMOTE(emote)
	if emote == L.EmoteSaroniteVapors or emote:find(L.EmoteSaroniteVapors) then
		self:SendSync("SaroniteVaporsSpawned")
	end
end

function mod:OnSync(msg)
	if msg == "SaroniteVaporsSpawned" and self:AntiSpam(3, 1) then
		self.vb.vaporsCount = self.vb.vaporsCount + 1
		warnSaroniteVapor:Show(self.vb.vaporsCount)
		
		if self.vb.vaporsCount == 6 then
			timerShadowCrashCD:AddTime(12)
			timerMarkoftheFacelessCD:AddTime(12) 
			timerNextSurgeofDarkness:AddTime(12)
			
		elseif self.vb.vaporsCount < 6 then
			timerSaroniteVapors:Start(30, self.vb.vaporsCount + 1)
		end
	end
end
