local mod	= DBM:NewMod("Ouro", "DBM-AQ40", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220518110528")
mod:SetCreatureID(15517)

mod:SetModelID(15517)
mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 26615",
	"SPELL_CAST_START 26102 26103",
	"SPELL_SUMMON 26058",
	"SWING_DAMAGE",
	"SWING_MISSED",
	"UNIT_HEALTH mouseover focus target"
)

local warnSubmerge			= mod:NewAnnounce("WarnSubmerge", 3, "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendBurrow.blp")
local warnEmerge			= mod:NewAnnounce("WarnEmerge", 3, "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendUnBurrow.blp")
local warnSweep				= mod:NewSpellAnnounce(26103, 2, nil, "Tank", 3)
local warnBerserk			= mod:NewSpellAnnounce(26615, 3)
local warnBerserkSoon		= mod:NewSoonAnnounce(26615, 2)

local specWarnBlast			= mod:NewSpecialWarningSpell(26102, nil, nil, nil, 2, 2)

local timerSubmerge			= mod:NewTimer(90, "TimerSubmerge", "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendBurrow.blp", nil, nil, 6)
local timerForcedSubmerge	= mod:NewTimer(8, "TimerForcedSubmerge", "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendBurrow.blp", nil, nil, 6)
local timerEmerge			= mod:NewTimer(30, "TimerEmerge", "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendUnBurrow.blp", nil, nil, 6)
local timerMounds			= mod:NewNextTimer(20, 26058, nil, nil, nil, 2)
local timerSweepCD			= mod:NewNextTimer(22, 26103, nil, nil, nil, 5, nil, DBM_COMMON_L.TANK_ICON)
local timerBlastCD			= mod:NewNextTimer(20, 26102, nil, nil, nil, 2)

mod.vb.prewarn_Berserk = false
mod.vb.Berserked = false

local function StartSubmergeTimer()
	timerForcedSubmerge:Start()
end

function mod:OnCombatStart(delay)
	self.vb.prewarn_Berserk = false
	self.vb.Berserked = false
	timerSweepCD:Start(22-delay)
	timerBlastCD:Start(-delay)
	timerSubmerge:Start(90-delay)
	self:Schedule(4, StartSubmergeTimer)
end

local function Emerge()
	warnEmerge:Show()
	timerSweepCD:Start(22)
	timerBlastCD:Start(24)
	timerSubmerge:Start(90)
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 26615 and args:IsDestTypeHostile() then
		self.vb.Berserked = true
		warnBerserk:Show()
		timerMounds:Start()
		timerSubmerge:Stop()
	end
end

function mod:SPELL_CAST_START(args)
	if args.spellId == 26102 then
		specWarnBlast:Show()
		specWarnBlast:Play("stunsoon")
		timerBlastCD:Start()
	elseif args.spellId == 26103 and args:IsSrcTypeHostile() then
		warnSweep:Show()
		timerSweepCD:Start()
	end
end

function mod:SWING_DAMAGE(_, source)
	if source == "Ouro" and not self.vb.Berserked  then 
		timerForcedSubmerge:Cancel()
		self:Unschedule(StartSubmergeTimer)
		self:Schedule(4, StartSubmergeTimer)
	end
end

function mod:SWING_MISSED(_, source)
	if source == "Ouro" and not self.vb.Berserked then 
		timerForcedSubmerge:Cancel()
		self:Unschedule(StartSubmergeTimer)
		self:Schedule(4, StartSubmergeTimer)
	end
end

function mod:SPELL_SUMMON(args)
	if args.spellId == 26058 and self:AntiSpam(3) then
		if not self.vb.Berserked then
			timerBlastCD:Stop()
			timerSweepCD:Stop()
			timerSubmerge:Stop()
			warnSubmerge:Show()
			timerEmerge:Start()
			self:Schedule(30, Emerge)
			
		elseif self.vb.Berserked then
			timerMounds:Start()
			
		end
	end
end

function mod:UNIT_HEALTH(uId)
	if self:GetUnitCreatureId(uId) == 15517 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.23 and not self.vb.prewarn_Berserk then
		self.vb.prewarn_Berserk = true
		warnBerserkSoon:Show()
		timerSubmerge:Cancel()
		timerForcedSubmerge:Cancel()
	end
end