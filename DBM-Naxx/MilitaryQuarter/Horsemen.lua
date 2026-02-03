local mod	= DBM:NewMod("Horsemen", "DBM-Naxx", 4)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20221016185606")
mod:SetCreatureID(16063, 16064, 16065, 30549)

mod:RegisterCombat("combat", 16063, 16064, 16065, 30549)

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 28884 57467",
	"SPELL_CAST_SUCCESS 28832 28833 28834 28835 28883 53638 57466 32455 57463 57369",
	"SPELL_AURA_APPLIED_DOSE 28832 28833 28834 28835",
	"UNIT_DIED"
)

local warnShadow			= mod:NewTargetNoFilterAnnounce(28882, 4)
local warnMeteor			= mod:NewSpellAnnounce(57467, 4)
local warnVoidZone			= mod:NewTargetNoFilterAnnounce(28863, 3)
local warnHolyWrath			= mod:NewTargetNoFilterAnnounce(28883, 3, nil, false)

local specWarnMarkOnPlayer		= mod:NewSpecialWarning("SpecialWarningMarkOnPlayer", nil, nil, nil, 1, 6, nil, nil, 28835)
local specWarnVoidZone			= mod:NewSpecialWarningYou(28863, nil, nil, nil, 1, 2)
local yellVoidZone			= mod:NewYell(28863)

local timerLadyMark			= mod:NewNextTimer(16, 28833, nil, nil, nil, 3)
local timerZeliekMark			= mod:NewNextTimer(16, 28835, nil, nil, nil, 3)
local timerBaronMark			= mod:NewNextTimer(12, 28834, nil, nil, nil, 3)
local timerThaneMark			= mod:NewNextTimer(12, 28832, nil, nil, nil, 3)
local timerMeteorCD			= mod:NewCDTimer(15, 57467, nil, nil, nil, 3)
local timerVoidZoneCD			= mod:NewNextTimer(15, 28863, nil, nil, nil, 3)
local timerHolyWrathCD			= mod:NewNextTimer(15, 28883, nil, nil, nil, 3)
local timerShadowCD			= mod:NewCDTimer(15, 28882, nil, nil, nil, 3)

mod:AddRangeFrameOption("12")

mod:SetBossHealthInfo(
	16064, L.Korthazz,	-- Thane
	30549, L.Rivendare,	-- Baron
	16065, L.Blaumeux,	-- Lady
	16063, L.Zeliek		-- Zeliek
)

function mod:OnCombatStart(delay)
	timerLadyMark:Start(31-delay)
	timerZeliekMark:Start(32-delay)
	timerBaronMark:Start(31-delay)
	timerThaneMark:Start(32-delay)
	timerMeteorCD:Start(18-delay)
	timerHolyWrathCD:Start(23-delay)
	timerVoidZoneCD:Start(22-delay)
	timerShadowCD:Start(18-delay)

	if self.Options.RangeFrame then
		DBM.RangeCheck:Show(12)
	end
end

function mod:OnCombatEnd()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(28884, 57467) then
		warnMeteor:Show()
		timerMeteorCD:Start()
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId

	if args:IsSpellID(28832, 28833, 28834, 28835) and self:AntiSpam(5, spellId) then
		if spellId == 28833 then -- Lady Mark
			timerLadyMark:Start()
		elseif spellId == 28835 then -- Zeliek Mark
			timerZeliekMark:Start()
		elseif spellId == 28834 then -- Baron Mark
			timerBaronMark:Start()
		elseif spellId == 28832 then -- Thane Mark
			timerThaneMark:Start()
		end
	elseif args.spellId == 57463 then
		timerVoidZoneCD:Start()
		if args:IsPlayer() then
			specWarnVoidZone:Show()
			specWarnVoidZone:Play("targetyou")
			yellVoidZone:Yell()
		elseif self:CheckNearby(12, args.destName) then
			warnVoidZone:Show(args.destName)
		end
	elseif spellId == 57369 then
		warnShadow:Show(args.destName)
		timerShadowCD:Start()
	elseif args:IsSpellID(28883, 53638, 57466, 32455) then
		warnHolyWrath:Show(args.destName)
		timerHolyWrathCD:Start()
	end
end

function mod:SPELL_AURA_APPLIED_DOSE(args)
	if args:IsSpellID(28832, 28833, 28834, 28835) and args:IsPlayer() then
		local amount = args.amount or 1
		if amount >= 4 then
			specWarnMarkOnPlayer:Show(args.spellName, amount)
			specWarnMarkOnPlayer:Play("stackhigh")
		end
	end
end

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 16064 then
		timerThaneMark:Cancel()
		timerMeteorCD:Cancel()
--		self:Unschedule(MeteorCast)
	elseif cid == 30549 then
		timerBaronMark:Cancel()
	elseif cid == 16065 then
		timerLadyMark:Cancel()
	elseif cid == 16063 then
		timerZeliekMark:Cancel()
	end
end
