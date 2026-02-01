local mod	= DBM:NewMod("Noth", "DBM-Naxx", 3)
local L		= mod:GetLocalizedStrings()

local GetSpellInfo = GetSpellInfo

mod:SetRevision("20221027184343")
mod:SetCreatureID(15954)

mod:RegisterCombat("combat_yell", L.Pull)

mod:RegisterEvents(
	"SPELL_CAST_SUCCESS 29213 54835 29212 29208",
	"SPELL_AURA_APPLIED 29208 29209 29210 29211",
	"CHAT_MSG_RAID_BOSS_EMOTE",
	"UNIT_SPELLCAST_SUCCEEDED boss1"
)

local warnTeleportNow	= mod:NewAnnounce("WarningTeleportNow", 3, 46573)
local warnTeleportSoon	= mod:NewAnnounce("WarningTeleportSoon", 1, 46573)
local warnCurse			= mod:NewSpellAnnounce(29213, 2)
local warnBlinkSoon		= mod:NewSoonAnnounce(29208, 1)
local warnBlink			= mod:NewSpellAnnounce(29208, 3)

local specWarnAdds		= mod:NewSpecialWarningAdds(29212, "-Healer", nil, nil, 1, 2)

local timerTeleport		= mod:NewTimer(110, "TimerTeleport", 46573, nil, nil, 6)
local timerTeleportBack	= mod:NewTimer(70, "TimerTeleportBack", 46573, nil, nil, 6)
local timerCurseCD		= mod:NewNextTimer(25, 29213, nil, nil, nil, 5, nil, DBM_COMMON_L.CURSE_ICON) -- REVIEW! variance? (25man Frostmourne 2022/05/25 || 25man Lordaeron 2022/10/16) -  56.7, 99.1! || 57.4
local timerAddsCD		= mod:NewAddsTimer(30, 29212, nil, "-Healer")
local timerBlink		= mod:NewNextTimer(30, 29208) -- (25N Lordaeron 2022/10/16) - 30.1, 30.0

function mod:OnCombatStart(delay)

	timerAddsCD:Start(10-delay)
	timerCurseCD:Start(15-delay)
	timerBlink:Start(26-delay)
	timerTeleport:Start(110-delay)
	warnTeleportSoon:Schedule(100-delay)
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(29213, 54835) then	-- Curse of the Plaguebringer
		warnCurse:Show()
		timerCurseCD:Start()
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(29208, 29209, 29210, 29211) then -- Blink
		warnBlink:Show()
		timerBlink:Start()
		warnBlinkSoon:Schedule(26)
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg)
	if msg == L.Adds or msg:find(L.Adds) then
		specWarnAdds:Show()
		specWarnAdds:Play("killmob")
		timerAddsCD:Start(30)
	elseif msg == L.AddsTwo or msg:find(L.AddsTwo) then
		specWarnAdds:Show()
		specWarnAdds:Play("killmob")
		timerAddsCD:Start(30)
	elseif msg == L.TeleportBalcony or msg:find(L.TeleportBalcony) then
		self:SetStage(1)
		timerCurseCD:Stop()
		timerAddsCD:Stop()
		timerBlink:Stop()
		warnBlinkSoon:Cancel()
		

		timerAddsCD:Start(4)
		timerTeleportBack:Start(70)
		warnTeleportSoon:Schedule(60)
		warnTeleportNow:Schedule(70)
	elseif msg == L.TeleportGround or msg:find(L.TeleportGround) then	
		self:SetStage(0)
		timerAddsCD:Stop()

		timerAddsCD:Start(10)
		timerCurseCD:Start(15)
		timerBlink:Start(26)
		timerTeleport:Show(110)
		warnTeleportSoon:Schedule(100)
		warnTeleportNow:Schedule(110)
	end
end
