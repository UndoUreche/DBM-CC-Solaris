local mod	= DBM:NewMod("Alar", "DBM-TheEye")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220518110528")
mod:SetCreatureID(19514)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 34229 35383 35410",
	"SPELL_AURA_REMOVED 35410",
	"SPELL_CAST_START 34342"
)

local QUILL_DURATION = 10
local NEXT_PLATFORM_TIMER = 30
local PLATFORM_QUILL_DELAY = 2

local METEOR_CD = 50
local MELT_ARMOR_DURATION = 60
local BERSERK_TIMER = 600

local warnPhase2		= mod:NewPhaseAnnounce(2, 2)
local warnArmor			= mod:NewTargetAnnounce(35410, 2)
local warnMeteor		= mod:NewSpellAnnounce(35181, 3)

local specWarnQuill		= mod:NewSpecialWarningDodge(34229, nil, nil, nil, 2, 2)
local specWarnFire		= mod:NewSpecialWarningMove(35383, nil, nil, nil, 1, 2)
local specWarnArmor		= mod:NewSpecialWarningTaunt(35410, nil, nil, nil, 1, 2)

local timerQuill		= mod:NewCastTimer(QUILL_DURATION, 34229, nil, nil, nil, 3)
local timerMeteor		= mod:NewNextTimer(METEOR_CD, 35181, nil, nil, nil, 2)
local timerArmor		= mod:NewTargetTimer(MELT_ARMOR_DURATION, 35410, nil, "Tank", 2, 5, nil, DBM_COMMON_L.TANK_ICON)
local timerNextPlatform	= mod:NewTimer(NEXT_PLATFORM_TIMER, "NextPlatform", 40192, nil, nil, 6)
local berserkTimer		= mod:NewBerserkTimer(BERSERK_TIMER)

local function TrackPlatform(self)
	
	timerNextPlatform:Start()
	
	self:Schedule(NEXT_PLATFORM_TIMER, TrackPlatform, self)
end

local function CancelPlatformTracking(self)

	self:Unschedule(TrackPlatform)
	timerNextPlatform:Cancel()
end

local function shouldAddExtraDelay(self)

	if self.vb.quillCount == nil then
		self.vb.quillCount = 0
	else
		self.vb.quillCount = self.vb.quillCount + 1
	end
	
	return self.vb.quillCount % 3 == 0
end

local function getPlatformDelay(self) 

	local extraDelay = 0
	
	if shouldAddExtraDelay(self) then 
		extraDelay = PLATFORM_QUILL_DELAY
	end
	
	return QUILL_DURATION + extraDelay
end

local function TrackQuills(self)

	specWarnQuill:Show()
	specWarnQuill:Play("findshelter")
	timerQuill:Start()
	
	self:Schedule(getPlatformDelay(self), TrackPlatform, self)
end

local function Reset(self) 

	self.vb.quillCount = nil
end

function mod:OnCombatStart(delay)

	Reset(self)
	TrackPlatform(self)
end

local function warnFirePatch(self)

	specWarnFire:Show()
	specWarnFire:Play("runaway")
end

local function warnMeltArmor(self, args)

	warnArmor:Show(args.destName)
	
	if args:IsPlayer() == false then
		specWarnArmor:Show(args.destName)
		specWarnArmor:Play("tauntboss")
	end
end

function mod:SPELL_AURA_APPLIED(args)

	if args.spellId == 34229 then
		CancelPlatformTracking(self)
		TrackQuills(self)
		
	elseif args.spellId == 35383 and args:IsPlayer() and self:AntiSpam(3, 1) then
		warnFirePatch(self)
		
	elseif args.spellId == 35410 then
		warnMeltArmor(self, args)
		timerArmor:Start(args.destName)
	end
end

function mod:SPELL_AURA_REMOVED(args)

	if args.spellId == 35410 then
		timerArmor:Cancel(args.destName)
	end
end

local function TransitionPhase2(self)

	self:SetStage(2)
	warnPhase2:Show()
	berserkTimer:Start()
end

local function TrackMeteor(self)
	
	timerMeteor:Start()
	warnMeteor:Schedule(METEOR_CD)
	
	self:Schedule(METEOR_CD, TrackMeteor, self)
end

function mod:SPELL_CAST_START(args)

	if args.spellId == 34342 then
		CancelPlatformTracking(self)
		TransitionPhase2(self)
		self:Schedule(4, TrackMeteor, self)
	end
end
