local mod	= DBM:NewMod("Nefarian", "DBM-BWL", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 188 $"):sub(12, -3))
mod:SetCreatureID(11583)
mod:RegisterCombat("yell", L.YellPull)
mod:SetWipeTime(25)--guesswork

mod:RegisterEvents(
	"SPELL_CAST_START",
	"SPELL_AURA_APPLIED",
	"SPELL_AURA_REMOVED",
	"UNIT_HEALTH",
	"CHAT_MSG_MONSTER_YELL",
	"SPELL_CAST_SUCCESS"
)

local warnClassCallSoon	= mod:NewAnnounce("WarnClassCallSoon", 2)
local warnClassCall		= mod:NewAnnounce("WarnClassCall", 3)
local warnPhaseSoon		= mod:NewAnnounce("WarnPhaseSoon", 2)
local warnPhase			= mod:NewAnnounce("WarnPhase", 3)
local warnShadowFlame	= mod:NewCastAnnounce(22539, 2)
local warnFear			= mod:NewCastAnnounce(22686, 2)
local warnVeilShadow	= mod:NewTargetAnnounce(22687, 3)
local warnMc			= mod:NewTargetAnnounce(22667, 4)
local warnMcCD			= mod:NewSpecialWarning("WarnMcCallSoon")
local WarnAddsLeft		= mod:NewAnnounce("WarnAddsLeft", 2, "136116")

local timerClassCall	= mod:NewTimer(30, "TimerClassCall")
local timerShadowFlame	= mod:NewCastTimer(2, 22539)
local timerFearNext		= mod:NewNextTimer(30, 22686)
local timerVeilShadow	= mod:NewTargetTimer(6, 22687)
local timerMc			= mod:NewTargetTimer(15, 22667)
local timerMcCD			= mod:NewCDTimer(24, 22667)

mod.vb.addLeft = 42
local addsGuidCheck = {}

local prewarn_P3
function mod:OnCombatStart(delay)
	prewarn_P3 = false
	timerMcCD:Start(30)
	warnMcCD:Schedule(29)
	table.wipe(addsGuidCheck)
	self.vb.addLeft = 42
end

function mod:SPELL_CAST_START(args)
	if args.spellId == 22539 and self:IsInCombat() then
		warnShadowFlame:Show()
		timerShadowFlame:Start()
	elseif args.spellId == 22686 and self:IsInCombat() then
		warnFear:Show()
		timerFearNext:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 22687 then
		warnVeilShadow:Show(args.destName)
		timerVeilShadow:Start(args.destName)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args.spellId == 22667 then
		warnMc:Show(args.destName)
		timerMc:Start(args.destName)
		timerMcCD:Start()
		warnMcCD:Schedule(23)
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 22687 then
		timerVeilShadow:Cancel(args.destName)
	end
end

function mod:UNIT_HEALTH(uId)
	if UnitHealth(uId) / UnitHealthMax(uId) <= 0.25 and self:GetUnitCreatureId(uId) == 11583 and not prewarn_P3 then
		warnPhaseSoon:Show("3")
		prewarn_P3 = true
	end
end

function mod:UNIT_DIED(args)
	local guid = args.destGUID
	local cid = self:GetCIDFromGUID(guid)
	if cid == 14264 or cid == 14263 or cid == 14261 or cid == 14265 or cid == 14262 or cid == 14302 then--Red, Bronze, Blue, Black, Green, Chromatic
		if not addsGuidCheck[guid] then
			addsGuidCheck[guid] = true
			self.vb.addLeft = self.vb.addLeft - 1
			--40, 35, 30, 25, 20, 15, 12, 9, 6, 3
			if self.vb.addLeft >= 15 and (self.vb.addLeft % 5 == 0) or self.vb.addLeft >= 1 and (self.vb.addLeft % 3 == 0) then
				WarnAddsLeft:Show(self.vb.addLeft)
			end
		end
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.YellDK then
		self:SendSync("ClassCall", "DK")
	elseif msg == L.YellDruid then
		self:SendSync("ClassCall", "Druid")
	elseif msg == L.YellHunter then
		self:SendSync("ClassCall", "Hunter")
	elseif msg == L.YellMage then
		self:SendSync("ClassCall", "Mage")
	elseif msg == L.YellPaladin then
		self:SendSync("ClassCall", "Paladin")
	elseif msg == L.YellPriest then
		self:SendSync("ClassCall", "Priest")
	elseif msg == L.YellRogue then
		self:SendSync("ClassCall", "Rogue")
	elseif msg == L.YellShaman then
		self:SendSync("ClassCall", "Shaman")
	elseif msg == L.YellWarlock then
		self:SendSync("ClassCall", "Warlock")
	elseif msg == L.YellWarrior then
		self:SendSync("ClassCall", "Warrior")
	elseif msg == L.YellPhase2 then
		self:SendSync("Phase", 2)
	elseif msg == L.YellPhase3 then
		self:SendSync("Phase", 3)
	end
end

function mod:OnSync(msg, arg)
	if msg == "ClassCall" then
		warnClassCallSoon:Schedule(25)
		warnClassCall:Show(arg)
		timerClassCall:Start(arg)
	elseif msg == "Phase" then
		warnPhase:Show(arg)
	end
end