local mod	= DBM:NewMod("Souls", "DBM-BlackTemple")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220518110528")
mod:SetCreatureID(23420)

mod:SetModelID(21483)
mod:SetUsedIcons(4, 5, 6, 7, 8)

mod:RegisterCombat("combat")

mod:RegisterEvents(
	"SPELL_AURA_APPLIED 41305 41431 41376 41303 41294 41410",
	"SPELL_CAST_START 41410 41426 41303",
	"SPELL_CAST_SUCCESS 41350 41337",
	"SPELL_DAMAGE 41545",
	"SPELL_MISSED 41545",
	"CHAT_MSG_MONSTER_YELL",
	"UNIT_SPELLCAST_SUCCEEDED"
)

local warnFixate		= mod:NewTargetNoFilterAnnounce(41294, 3, nil, "Tank|Healer", 2)
local warnDrain			= mod:NewSpellAnnounce(41303, 3, nil, "Healer", 2)
local warnFrenzy		= mod:NewSpellAnnounce(41305, 3, nil, "Tank|Healer", 2)
local warnFrenzySoon	= mod:NewPreWarnAnnounce(41305, 5, 2)

local warnPhase2		= mod:NewPhaseAnnounce(2, 2)
local warnMana			= mod:NewAnnounce("WarnMana", 4, 41350)
local warnDeaden		= mod:NewTargetNoFilterAnnounce(41410, 1)
local specWarnShock		= mod:NewSpecialWarningInterrupt(41426, "HasInterrupt", nil, 2)

local warnPhase3		= mod:NewPhaseAnnounce(3, 2)
local warnSoul			= mod:NewSpellAnnounce(41545, 2, nil, "Tank", 2)
local warnSpite			= mod:NewTargetAnnounce(41376, 3)

local specWarnShield	= mod:NewSpecialWarningDispel(41431, "MagicDispeller", nil, 2, 1, 2)
local specWarnSpite		= mod:NewSpecialWarningYou(41376, nil, nil, nil, 1, 2)

local timerPhaseChange		= mod:NewPhaseTimer(41)
local timerFrenzy		= mod:NewBuffActiveTimer(15, 41305, nil, "Tank|Healer", 2, 5, nil, DBM_COMMON_L.TANK_ICON)
local timerNextFrenzy		= mod:NewNextTimer(45, 41305, nil, "Tank|Healer", 2, 5, nil, DBM_COMMON_L.TANK_ICON)
local timerDeaden		= mod:NewTargetTimer(10, 41410, nil, nil, nil, 5, nil, DBM_COMMON_L.DAMAGE_ICON, nil, mod:IsTank() and select(2, UnitClass("player")) == "WARRIOR" and 2, 4)
local timerNextDeaden		= mod:NewNextTimer(31, 41410, nil, nil, nil, 5) 
local timerMana			= mod:NewTimer(160, "TimerMana", 41350)
local timerNextShield		= mod:NewNextTimer(15, 41431, nil, "MagicDispeller", 2, 5, nil, DBM_COMMON_L.MAGIC_ICON)
local timerNextSoul		= mod:NewNextTimer(10, 41545, nil, "Tank", 2, 5, nil, DBM_COMMON_L.TANK_ICON)

mod:AddSetIconOption("SpiteIcon", 41376, false)

mod.vb.lastFixate = "None"

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 41305 then
		warnFrenzy:Show()
		timerFrenzy:Start()
		warnFrenzySoon:Schedule(37)
		timerNextFrenzy:Schedule(12, 30)
	elseif args.spellId == 41431 and not args:IsDestTypePlayer() then
		specWarnShield:Show(args.destName)
		specWarnShield:Play("dispelboss")
	elseif args.spellId == 41376 then
		warnSpite:CombinedShow(0.3, args.destName)
		if args:IsPlayer() then
			specWarnSpite:Show()
			specWarnSpite:Play("defensive")
		end
		if self.Options.SpiteIcon then
			self:SetSortedIcon("roster",0.5, args.destName, 1, 3, false)
		end
	elseif args.spellId == 41294 then
		if self.vb.lastFixate ~= args.destName then
			warnFixate:Show(args.destName)
			self.vb.lastFixate = args.destName
		end
	elseif args.spellId == 41410 then
		warnDeaden:Show(args.destName)
	end
end

function mod:SPELL_CAST_START(args)
	if args.spellId == 41410 then
		timerNextDeaden:Start()
	elseif args.spellId == 41426 then
		specWarnShock:Show(args.sourceName)
        elseif args.spellId == 41303 then
                warnDrain:Show()
	end
end

function mod:SPELL_DAMAGE(_, _, _, _, _, _, spellId)
	if spellId == 41545 and self:AntiSpam(3, 1) then
		warnSoul:Show()
		timerNextSoul:Start()
	end
end
mod.SPELL_MISSED = mod.SPELL_DAMAGE

function mod:UNIT_SPELLCAST_SUCCEEDED(_, spellName)
	if spellName == GetSpellInfo(28819) and self:AntiSpam(2, 2) then--Submerge Visual
		self:SendSync("PhaseEnd")
	end
end

local function deadenLoop(self) 
	
	timerNextDeaden:Start()
	self:Schedule(31, deadenLoop, self)
end

local function shieldLoop(self)

	timerNextShield:Start()
	self:Schedule(15, shieldLoop, self)
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.Phase1Start then 
		DBM:StartCombat(self)
        	self.vb.lastFixate = "None"
        	timerNextFrenzy:Start()
        	warnFrenzySoon:Schedule(40)
	elseif msg == L.Phase2Start then 
		warnPhase2:Show()
                warnMana:Schedule(130)
                
		timerMana:Start()

                timerNextShield:Start(13)
		self:Schedule(13, shieldLoop, self)

		timerNextDeaden:Start(28)
		self:Schedule(28, deadenLoop, self)
	elseif msg == L.Phase3Start or msg == L.Phase3StartV2 then
		warnPhase3:Show()
                timerNextSoul:Start()
	elseif msg == L.Phase1End 
		or msg:find(L.Phase1End) 
		or msg == L.Phase2End 
		or msg:find(L.Phase2End) then
		self:SendSync("PhaseEnd")
	end
end

function mod:OnSync(msg)

	if not self:IsInCombat() then return end
	if msg == "PhaseEnd" then
		warnFrenzySoon:Cancel()
		warnMana:Cancel()
		timerNextFrenzy:Stop()
		timerNextFrenzy:Unschedule()
		timerFrenzy:Stop()
		timerMana:Stop()
		timerNextShield:Stop()
		timerNextDeaden:Stop()
		timerPhaseChange:Start()

		self:Unschedule(deadenLoop)
		self:Unschedule(shieldLoop)
	end
end
