local mod	= DBM:NewMod("FlameLeviathan", "DBM-Ulduar")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20221031101217")

mod:SetCreatureID(33113)

mod:RegisterCombat("yell", L.YellPull)

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 62396 62475 62374 62297",
	"SPELL_AURA_REMOVED 62396 62374",
	"SPELL_SUMMON 62907"
)

local warnHodirsFury			= mod:NewTargetAnnounce(62297, 3)
local warnNextPursueSoon		= mod:NewAnnounce("warnNextPursueSoon", 3, 62374, nil, nil, nil, 62374)

local specWarnSystemOverload	= mod:NewSpecialWarningSpell(62475, nil, nil, nil, 1, 12)
local specWarnPursue			= mod:NewSpecialWarning("SpecialPursueWarnYou", nil, nil, 2, 4, 2, nil, 62374, 62374)

local timerSystemOverload		= mod:NewBuffActiveTimer(20, 62475, nil, nil, nil, 6)
local timerFlameVents			= mod:NewCastTimer(10, 62396, nil, nil, nil, 2, nil, DBM_COMMON_L.INTERRUPT_ICON)
local timertNextFlameVents		= mod:NewNextTimer(20, 62396, nil, nil, nil, 2)
local timerPursued				= mod:NewTargetTimer(30, 62374, nil, nil, nil, 3)

-- Hard Mode
mod:AddTimerLine(DBM_COMMON_L.HEROIC_ICON..DBM_CORE_L.HARD_MODE)
local specWarnWardOfLife		= mod:NewSpecialWarning("warnWardofLife", nil, nil, nil, 1, 2, nil, 62907, 62907)

local timerNextWardOfLife		= mod:NewNextTimer(29, 62907, nil, nil, nil, 1)

local names = {}
local function buildNameTable(self)
	
	table.wipe(names)
	
	for uId in DBM:GetGroupMembers() do
		
		local name, server = GetUnitName(uId, true)
		names[UnitGUID(uId.."pet") or "none"] = name
	end
end

local function getPlayerName(guid) 
	
	local name = names[guid]
	
	if name == nil or name == "" then
		return "Unknown"
	end
	
	return name
end

local function CheckTowers(self, delay)
	
	if DBM:UnitBuff("target", 64482) then -- Tower of Life
		self:SendSync("freya", delay)
	elseif DBM:UnitBuff("focus", 64482) then
		self:SendSync("freya", delay)
	elseif DBM:UnitBuff("mouseover", 64482) then
		self:SendSync("freya", delay)
	end
end

function mod:OnCombatStart(delay)

	buildNameTable(self)
	
	timertNextFlameVents:Start(20-delay)
	self:Schedule(1, CheckTowers, self, delay)
end

function mod:OnTimerRecovery()
	buildNameTable(self)
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	if spellId == 62396 then		-- Flame Vents
		timerFlameVents:Start()
		timertNextFlameVents:Start()
	elseif spellId == 62475 then	-- Systems Shutdown / Overload
	
		timertNextFlameVents:AddTime(20)
	
		timerSystemOverload:Start()
		specWarnSystemOverload:Show()
		specWarnSystemOverload:Play("attacktank")
	
	elseif spellId == 62374 then	-- Pursued
		local target = getPlayerName(args.destGUID)
		
		warnNextPursueSoon:Schedule(25)
		timerPursued:Start(target)
		
		if target == UnitName("player") then
			specWarnPursue:Show()
			specWarnPursue:Play("justrun")
		end
	elseif spellId == 62297 then	-- Hodir's Fury (Person is frozen)
		
		local target = getPlayerName(args.destGUID)
		warnHodirsFury:CombinedShow(0.3, target)
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 62396 then
		timerFlameVents:Stop()
	elseif spellId == 62374 then	-- Pursued
		local target = getPlayerName(args.destGUID)
		timerPursued:Stop(target)
	end
end

function mod:SPELL_SUMMON(args)
	if args.spellId == 62907 and self:AntiSpam(3, 1) then		-- Ward of Life spawned (Creature id: 34275)
		specWarnWardOfLife:Show()
		timerNextWardOfLife:Start()
	end
end

function mod:OnSync(msg, delay)

	if msg == "freya" then
		timerNextWardOfLife:Unschedule()
		timerNextWardOfLife:Schedule(0.3, 34 -delay)
	end
end
