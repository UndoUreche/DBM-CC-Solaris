local mod	= DBM:NewMod("Anetheron", "DBM-Hyjal")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220518110528")
mod:SetCreatureID(17808)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 31306 31298",
	"SPELL_AURA_REFRESH 31306 31298",
	"SPELL_AURA_REMOVED 31306 31298",
	"SPELL_CAST_START 31299",
	"SPELL_CAST_SUCCESS 31306 31298"
)

local warnSwarm			= mod:NewSpellAnnounce(31306, 3)
local warnSleep			= mod:NewTargetNoFilterAnnounce(31298, 2)
local warnInferno		= mod:NewTargetNoFilterAnnounce(31299, 4)

local specWarnInferno	= mod:NewSpecialWarningYou(31299, nil, nil, nil, 1, 2)
local yellInferno		= mod:NewYell(31299)

local timerSwarm		= mod:NewBuffFadesTimer(20, 31306, nil, nil, nil, 3)
local timerSwarmCD		= mod:NewCDTimer(10, 31306, nil, nil, nil, 3)
local timerSleep		= mod:NewBuffFadesTimer(10, 31298, nil, nil, nil, 3)
local timerSleepCD		= mod:NewCDTimer(35, 31298, nil, nil, nil, 3)
local timerInfernoCD		= mod:NewCDTimer(50, 31299, nil, nil, nil, 3)

local warnSleepTargets = {}

function mod:OnCombatStart(delay)
	timerSleepCD:Start(25-delay)
	timerInfernoCD:Start(30-delay)
	timerSwarmCD:Start(20-delay)
	
	table.wipe(warnSleepTargets)
end

local function showSleep(self)
	warnSleep:Show(table.concat(warnSleepTargets, "<, >"))
	timerSleepCD:Start()
	
	table.wipe(warnSleepTargets)
end

function mod:InfernoTarget(targetname)
	if not targetname then return end
		if targetname == UnitName("player") then
			specWarnInferno:Show()
			specWarnInferno:Play("targetyou")
			yellInferno:Yell()
		else
		warnInferno:Show(targetname)
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 31306 and args:IsPlayer() then
		timerSwarm:Start()
		timerSwarmCD:Start(10)
	elseif args.spellId == 31298 and args:IsPlayer() then
		warnSleepTargets[#warnSleepTargets + 1] = args.destName
	
		self:Unschedule(showSleep)
		self:Schedule(0.3, showSleep, self)
		timerSleep:Start()
	end
end
mod.SPELL_AURA_REFRESH = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 31306 and args:IsPlayer() then
		timerSwarm:Cancel()
	elseif args.spellId == 31298 and args:IsPlayer() then
		timerSleep:Cancel()
	end
end

function mod:SPELL_CAST_START(args)
	if args.spellId == 31299 then
		timerInfernoCD:Start()
		self:BossTargetScanner(17808, "InfernoTarget", 0.05, 10)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args.spellId == 31306 then
		warnSwarm:Show()
	end
end
