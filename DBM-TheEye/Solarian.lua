local mod	= DBM:NewMod("Solarian", "DBM-TheEye")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220518110528")
mod:SetCreatureID(18805)
mod:SetUsedIcons(8)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 42783",
	"SPELL_CAST_START 37135",
	"CHAT_MSG_MONSTER_YELL"
)

local WRATH_ID = 42783 --33045 pre-nerf

local warnWrath			= mod:NewTargetNoFilterAnnounce(WRATH_ID, 2)
local warnSplit			= mod:NewAnnounce("WarnSplit", 4, 39414)
local warnAgent			= mod:NewAnnounce("WarnAgent", 1, 39414)
local warnPriest		= mod:NewAnnounce("WarnPriest", 1, 39414)
local warnPhase2		= mod:NewPhaseAnnounce(2)

local specWarnWrath		= mod:NewSpecialWarningMoveAway(42783, nil, nil, nil, 1, 2)

local timerWrathCD		= mod:NewCDTimer(21.8, WRATH_ID, nil, nil, nil, 2)
local timerSplit		= mod:NewTimer(67.5, "TimerSplit", 39414, nil, nil, 6)
local timerAgent		= mod:NewTimer(6, "TimerAgent", 39414, nil, nil, 1)
local timerPriest		= mod:NewTimer(20, "TimerPriest", 39414, nil, nil, 1)

local berserkTimer		= mod:NewBerserkTimer(600)

mod:AddSetIconOption("WrathIcon", WRATH_ID, true, false, {8})

function mod:OnCombatStart(delay)

	timerSplit:Start(52.1-delay)
	timerWrathCD:Start(-delay)
	berserkTimer:Start(-delay)
end

local function TrackWrathTimers(args) 

	timerWrathCD:Start()
end

local function ShowWrathWarnings(args) 

	if args:IsPlayer() then
		specWarnWrath:Show()
		specWarnWrath:Play("runout")
	else
		warnWrath:Show(args.destName)
	end
end

local function PlaceWrathIcon(self, args) 

	if self.Options.WrathIcon then
		self:SetIcon(args.destName, 8, 6)
	end
end

function mod:SPELL_AURA_APPLIED(args)

	if args.spellId == WRATH_ID then
		
		TrackWrathTimers(args) 
		ShowWrathWarnings(args) 
		PlaceWrathIcon(self, args) 
	end
end

local function RemoveWrathIcon(self, args) 

	if self.Options.WrathIcon then
		self:SetIcon(args.destName, 0)
	end
end

local function IsSplitMessage(L, msg) 
	
	return msg == L.YellSplit1 or msg:find(L.YellSplit1) or msg == L.YellSplit2 or msg:find(L.YellSplit2)
end

local function IsPhaseTwoMessage(L, msg) 

	return msg == L.YellPhase2 or msg:find(L.YellPhase2)
end

function mod:CHAT_MSG_MONSTER_YELL(msg)

	if IsSplitMessage(L, msg) then
		warnSplit:Show()
		
		timerAgent:Start()
		warnAgent:Schedule(6)
		
		timerPriest:Start()
		warnPriest:Schedule(20)
		
		timerSplit:Start()
	elseif IsPhaseTwoMessage(L, msg) then
		warnPhase2:Show()
		
		timerAgent:Cancel()
		warnAgent:Cancel()
		
		timerPriest:Cancel()
		warnPriest:Cancel()
		
		timerSplit:Cancel()
	end
end
