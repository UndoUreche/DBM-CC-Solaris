local mod				= DBM:NewMod("Muru", "DBM-Sunwell")
local L					= mod:GetLocalizedStrings()

mod:SetRevision("20220518110528")
mod:SetCreatureID(25741)--25741 Muru, 25840 Entropius

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 45996",
	"SPELL_CAST_SUCCESS 46177",
	"SPELL_SUMMON 46268 46282",
	"UNIT_DIED",
	"UNIT_HEALTH"
)

local warnHuman				= mod:NewAnnounce("WarnHuman", 4, 27778)
local warnVoid				= mod:NewAnnounce("WarnVoid", 4, 46087)
local warnPhase2			= mod:NewPhaseAnnounce(2)
local warnFiend				= mod:NewAnnounce("WarnFiend", 2, 46268)
local preWarnDarknessSoon		= mod:NewPreWarnAnnounce(45996, "5")

local specWarnDarkness			= mod:NewSpecialWarningSpell(45996, "specWarnVoid")
local specWarnBH			= mod:NewSpecialWarningSpell(46282, "specWarnBH")
local specWarnVW			= mod:NewSpecialWarning("specWarnVW", "Tank")

local timerHuman			= mod:NewTimer(60, "TimerHuman", 27778, nil, nil, 6)
local timerVoid				= mod:NewTimer(30, "TimerVoid", 46087, nil, nil, 6)
local timerNextDarkness			= mod:NewNextTimer(45, 45996, nil, nil, nil, 2)
local timerDarknessDura			= mod:NewBuffActiveTimer(20, 45996)
local timerBlackHoleCD			= mod:NewNextTimer(15, 46282)
local timerPhase			= mod:NewTimer(10, "TimerPhase", 46087, nil, nil, 6)

local berserkTimer			= mod:NewBerserkTimer(600)

mod.vb.humanCount = 1
mod.vb.voidCount = 1

local function HumanSpawn(self)
	warnHuman:Show(self.vb.humanCount)
	self.vb.humanCount = self.vb.humanCount + 1
	timerHuman:Start(nil, self.vb.humanCount)
	self:Schedule(60, HumanSpawn, self)
end

local function VoidSpawn(self)
	warnVoid:Show(self.vb.voidCount)
	self.vb.voidCount = self.vb.voidCount + 1
	timerVoid:Start(nil, self.vb.voidCount)
	specWarnVW:Schedule(25)
	self:Schedule(30, VoidSpawn, self)
end

function mod:OnCombatStart(delay)
	self:SetStage(1)
	self.vb.humanCount = 1
	self.vb.voidCount = 1
	timerHuman:Start(10-delay, 1)
	timerVoid:Start(30-delay, 1)
	specWarnVW:Schedule(25)
	timerNextDarkness:Start(-delay)
	preWarnDarknessSoon:Schedule(40)
	self:Schedule(10, HumanSpawn, self)
	self:Schedule(30, VoidSpawn, self)
	berserkTimer:Start(-delay)
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 45996 and args:GetDestCreatureID() == 25741 then
		specWarnDarkness:Show()
		timerNextDarkness:Start()
		timerDarknessDura:Start()
		preWarnDarknessSoon:Schedule(40)
	end
end

function mod:SPELL_SUMMON(args)
	if args.spellId == 46268 then
		warnFiend:Show()
	elseif args.spellId == 46282 then
		specWarnBH:Show()
		timerBlackHoleCD:Start()
	end
end

function mod:UNIT_DIED(args)
	if self:GetCIDFromGUID(args.destGUID) == 25840 then
		DBM:EndCombat(self)
	end
end

local function phase2(self)
	self:SetStage(2)
	warnPhase2:Show()
	self:Unschedule(HumanSpawn)
	self:Unschedule(VoidSpawn)
	timerHuman:Cancel()
	timerVoid:Cancel()
	timerBlackHoleCD:Start(15)
	
	if self.Options.HealthFrame then
		DBM.BossHealth:Clear()
		DBM.BossHealth:AddBoss(25840, L.Entropius)
	end
end

function mod:UNIT_HEALTH(unitId)
	if DBM:GetUnitCreatureId(unitId) == 25741 and self:GetStage() == 1 and UnitHealth(unitId) == 1 then
		self:SendSync("phase2")
	end
end

function mod:OnSync(msg)
	if msg == "phase2" and self:AntiSpam(5) then
		timerNextDarkness:Cancel()
		timerHuman:Cancel()
		timerVoid:Cancel()
		specWarnVW:Cancel()
		timerPhase:Start()
		preWarnDarknessSoon:Cancel()
		self:Schedule(10, phase2, self)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args.spellId == 46177 then
	--[[
		timerNextDarkness:Cancel()
		timerHuman:Cancel()
		timerVoid:Cancel()
		specWarnVW:Cancel()
		timerPhase:Start()
		preWarnDarknessSoon:Cancel()
		self:Schedule(10, phase2, self)
		--]]
		DBM:AddMsg("Portals can be used to track phase transition, ping me so I can remove the workaround.")
	end
end
