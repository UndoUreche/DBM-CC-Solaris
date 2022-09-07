local mod	= DBM:NewMod("Moam", "DBM-AQ20", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 132 $"):sub(12, -3))
mod:SetCreatureID(15340)
mod:RegisterCombat("combat")

mod:RegisterEvents(
	"SPELL_AURA_APPLIED",
	"SPELL_CAST_SUCCESS",
	"SPELL_ENERGIZE",
	"CHAT_MSG_MONSTER_EMOTE",
	"UNIT_DIED"
)

local warnStoneformSoon	= mod:NewSoonAnnounce(25685, 2)
local warnStoneform		= mod:NewSpellAnnounce(25685, 3)

local timerStoneform	= mod:NewNextTimer(90, 25685)
local timerStoneformDur	= mod:NewBuffActiveTimer(90, 25685)

local fiendCounter
local charging

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(25685) then
		charging = false
		timerStoneformDur:Start()
		timerStoneform:Cancel()
		warnStoneform:Show()
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpellID(25685) then
		timerStoneform:Start()
		warnStoneformSoon:Schedule(80)
	end
end

function mod:CHAT_MSG_MONSTER_EMOTE(msg)
	if not msg then return end
	
	if msg == L.StartEmote then		
		fiendCounter = 0
		charging = true
		
		timerStoneform:Start(90)
		warnStoneformSoon:Schedule(80)
		timerStoneformDur:Cancel()
	elseif msg == L.ExplodeEmote and charging == false then
		charging = true
		timerStoneform:Start(91)
		warnStoneformSoon:Schedule(80)
		timerStoneformDur:Cancel()
	end
end

function mod:UNIT_DIED(args)
	if(args.sourceName == "Mana Fiend") then
		fiendCounter = fiendCounter + 1
	end
	
	if fiendCounter % 3 == 0 and charging == false then
		charging = true
		timerStoneform:Start(91)
		warnStoneformSoon:Schedule(80)
		timerStoneformDur:Cancel()
	end
end