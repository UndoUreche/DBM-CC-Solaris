local mod	= DBM:NewMod("Sapphiron", "DBM-Naxx", 5)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20221016192235")
mod:SetCreatureID(15989)
mod:SetMinSyncRevision(20220904000000)

mod:RegisterCombat("combat")
mod:SetModelScale(0.1)

mod:RegisterEventsInCombat(
	"SPELL_CAST_SUCCESS 28542 55665 28560 55696",
	"SPELL_AURA_APPLIED 28522 28547 55699",
	"CHAT_MSG_RAID_BOSS_EMOTE",
	"UNIT_HEALTH boss1"
)

-- General
local specWarnLowHP		= mod:NewSpecialWarning("SpecWarnSapphLow")

local berserkTimer		= mod:NewBerserkTimer(900)

-- Stage One (Ground Phase)
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(1))
local warnDrainLifeNow		= mod:NewSpellAnnounce(28542, 2)
local warnLanded		= mod:NewAnnounce("WarningLanded", 4, "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendBurrow.blp")
local warnBlizzard		= mod:NewSpellAnnounce(28560, 4)

local specWarnBlizzard		= mod:NewSpecialWarningGTFO(28547, nil, nil, nil, 1, 8)

local timerDrainLife		= mod:NewNextTimer(24, 28542, nil, nil, nil, 3, nil, DBM_COMMON_L.CURSE_ICON) -- (25man Lordaeron 2022/09/02) - 24.0
local timerAirPhase		= mod:NewTimer(60, "TimerAir", "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendUnBurrow.blp", nil, nil, 6)

-- Stage Two (Air Phase)
mod:AddTimerLine(DBM_CORE_L.SCENARIO_STAGE:format(2))
local warnAirPhaseNow		= mod:NewAnnounce("WarningAirPhaseNow", 4, "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendUnBurrow.blp")
local warnIceBlock		= mod:NewTargetAnnounce(28522, 2)

local specWarnDeepBreath= mod:NewSpecialWarningSpell(28524, nil, nil, nil, 1, 2)
local yellIceBlock		= mod:NewYell(28522)

local timerLanding		= mod:NewTimer(21, "TimerLanding", "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendBurrow.blp", nil, nil, 6)
local timerIceBlast		= mod:NewCastTimer(8, 28524, nil, nil, nil, 2, DBM_COMMON_L.DEADLY_ICON)

mod:AddRangeFrameOption("12")

local warned_lowhp = false
mod.vb.isFlying = false

function mod:OnCombatStart(delay)
	warned_lowhp = false
	self:SetStage(1)
	self.vb.isFlying = false
	timerDrainLife:Start(17-delay)
	timerAirPhase:Start(46-delay)
	berserkTimer:Start(-delay)
	if self.Options.RangeFrame then
		self:Schedule(46-delay, DBM.RangeCheck.Show, DBM.RangeCheck, 12)
	end
end

function mod:OnCombatEnd()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 28522 then
		warnIceBlock:CombinedShow(0.5, args.destName)
		if args:IsPlayer() then
			yellIceBlock:Yell()
		end
	elseif args:IsSpellID(28547, 55699) and args:IsPlayer() and self:AntiSpam(1) then
		specWarnBlizzard:Show(args.spellName)
		specWarnBlizzard:Play("watchfeet")
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if args:IsSpellID(28542, 55665) then -- Life Drain
		warnDrainLifeNow:Show()
		timerDrainLife:Start()
	elseif spellId == 28560 then
		warnBlizzard:Show()
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg)
	if msg == L.EmoteBreath or msg:find(L.EmoteBreath) then
		timerIceBlast:Start()
		--timerLanding:Update(10)
		specWarnDeepBreath:Show()
		specWarnDeepBreath:Play("findshelter")
	elseif msg == L.AirPhase or msg:find(L.AirPhase) then
		self:SetStage(2)
		self.vb.isFlying = true
		timerDrainLife:Cancel()
		timerAirPhase:Cancel()
		warnAirPhaseNow:Show()
		timerLanding:Start()
	elseif msg == L.LandingPhase or msg:find(L.LandingPhase) then
		self.vb.isFlying = false
		self:SetStage(1)
		warnLanded:Show()
		timerDrainLife:Start(33)
		timerAirPhase:Start()
		if self.Options.RangeFrame then
			DBM.RangeCheck:Hide()
			self:Schedule(59, DBM.RangeCheck.Show, DBM.RangeCheck, 12)
		end
	end
end

function mod:UNIT_HEALTH(uId)
	if not warned_lowhp and self:GetUnitCreatureId(uId) == 15989 and UnitHealth(uId) / UnitHealthMax(uId) < 0.1 then
		warned_lowhp = true
		specWarnLowHP:Show()
		timerAirPhase:Cancel()
	end
end
