local mod	= DBM:NewMod("Brutallus", "DBM-Sunwell")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220518110528")
mod:SetCreatureID(24882)
mod:SetUsedIcons(1, 2, 3, 4, 5, 6)

mod:RegisterCombat("yell", L.Pull)
mod.disableHealthCombat = true

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 45150",
	"SPELL_AURA_APPLIED 46394 45185 45150",
	"SPELL_AURA_APPLIED_DOSE 45150",
	"SPELL_AURA_REMOVED 46394",
	"SPELL_MISSED 46394"
)

local warnMeteor		= mod:NewSpellAnnounce(45150, 3)
local warnBurn			= mod:NewTargetAnnounce(46394, 3, nil, false, 2)
local warnStomp			= mod:NewTargetAnnounce(45185, 3, nil, "Tank", 2)

local specwarnStompYou		= mod:NewSpecialWarningYou(45185, "Tank")
local specwarnStomp		= mod:NewSpecialWarningTaunt(45185, "Tank")
local specWarnMeteor		= mod:NewSpecialWarningStack(45150, nil, 4, nil, nil, 1, 6)
local specWarnMeteorTaunt	= mod:NewSpecialWarning("Taunt stacks away!", false, "SpecWarnMeteorTaunt", nil, nil, nil, nil, nil, 45150)
local specWarnBurn		= mod:NewSpecialWarningYou(46394, nil, nil, nil, 1, 2)
local yellBurn			= mod:NewYell(46394)

local timerMeteorNext		= mod:NewNextTimer(12, 45150, nil, nil, nil, 3)
local timerStompNext		= mod:NewNextTimer(30, 45185, nil, nil, nil, 2)
local timerBurn			= mod:NewTargetTimer(60, 46394, nil, "false", 2, 3)
local timerBurnNext		= mod:NewNextTimer(20, 46394, nil, nil, nil, 3)

local berserkTimer		= mod:NewBerserkTimer(360)

mod:AddSetIconOption("BurnIcon", 46394, true, false, {1, 2, 3, 4, 5, 6})
mod:AddRangeFrameOption(4, 46394)
mod:AddMiscLine(DBM_CORE_L.OPTION_CATEGORY_DROPDOWNS)
mod:AddDropdownOption("RangeFrameActivation", {"AlwaysOn", "OnDebuff"}, "OnDebuff", "misc")

mod.vb.burnIcon = 6
local debuffName = DBM:GetSpellInfo(46394)

local DebuffFilter
do
	DebuffFilter = function(uId)
		return DBM:UnitDebuff(uId, debuffName)
	end
end

function mod:OnCombatStart(delay)
	self.vb.burnIcon = 6
	timerBurnNext:Start(20-delay)
	timerStompNext:Start(-delay)
	timerMeteorNext:Start(11-delay)
	berserkTimer:Start(-delay)
	if self.Options.RangeFrame and self.Options.RangeFrameActivation == "AlwaysOn" then
		DBM.RangeCheck:Show(4)
	end
end

function mod:OnCombatEnd()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 46394 then --Burn
		warnBurn:Show(args.destName)
		timerBurn:Start(args.destName)
		if self:AntiSpam(59, 1) then --I won't delete this, but I don't see the reason for antiSpam on a debuff that pops once every minute
			timerBurnNext:Start()
		end
		if self.Options.BurnIcon then
			self:SetIcon(args.destName, self.vb.burnIcon)
		end
		if self.vb.burnIcon == 1 then
			self.vb.burnIcon = 6
		else
			self.vb.burnIcon = self.vb.burnIcon - 1
		end
		if args:IsPlayer() then
			specWarnBurn:Show()
			specWarnBurn:Play("targetyou")
			yellBurn:Yell()
		end
		if self.Options.RangeFrame and self.Options.RangeFrameActivation == "OnDebuff" then
			if DBM:UnitDebuff("player", args.spellName) then--You have debuff, show everyone
				DBM.RangeCheck:Show(4, nil)
			else--You do not have debuff, only show players who do
				DBM.RangeCheck:Show(4, DebuffFilter)
			end
		end
	elseif args.spellId == 45185 then --Stomp
		if args:IsPlayer() then
			specwarnStompYou:Show()
		else
			specwarnStomp:Show(args.destName)
			warnStomp:Show(args.destName)
		end
		timerStompNext:Start()
		
	elseif args.spellId == 45150 then
		if args:IsPlayer() then
			if (args.amount or 1) > 3 then --Meteor Slash
				specWarnMeteor:Show(amount)
				specWarnMeteor:Play("stackhigh")
			end
		elseif DBM:IsTanking(DBM:GetRaidUnitId(args.destName), DBM:GetUnitIdFromCID(24882, false)) then
			if (args.amount or 1) > 2 then
				specWarnMeteorTaunt:Show()
			end
		end
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 46394 then
		if self.Options.BurnIcon then
			self:SetIcon(args.destName, 0)
		end
		timerBurn:Cancel(args.destName)
	end
end

function mod:SPELL_CAST_START(args)
	if args.spellId == 45150 then
		warnMeteor:Show()
		timerMeteorNext:Start()
	end
end

function mod:SPELL_MISSED(_, _, _, _, _, _, spellId)
	if spellId == 46394 then
		warnBurn:Show("MISSED")
		if self:AntiSpam(19, 1) then
			timerBurnCD:Start()
		end
	end
end
