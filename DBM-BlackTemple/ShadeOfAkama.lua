local mod	= DBM:NewMod("Akama", "DBM-BlackTemple")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220518110528")
mod:SetCreatureID(22841)

mod:SetModelID(21357)

mod:RegisterCombat("combat")
mod:SetWipeTime(50)--Adds come about every 50 seconds, so require at least this long to wipe combat if they die instantly

mod:RegisterEventsInCombat(
	"CHAT_MSG_MONSTER_YELL"
)

mod:RegisterEvents(
	"SPELL_AURA_REMOVED 34189"
)

local warnPhase2		= mod:NewPhaseAnnounce(2)
local warnDefender		= mod:NewAnnounce("warnAshtongueDefender", 2, 41180)
local warnSorc			= mod:NewAnnounce("warnAshtongueSorcerer", 2, 40520)
local warnAdds			= mod:NewAnnounce("warnAdds", 2, 42035)

local timerCombatStart		= mod:NewCombatTimer(10)

local timerAddsCD 		= mod:NewTimer(50, "timerAddsSoon", 42035, nil, nil, 1)
local timerDefenderCD		= mod:NewTimer(30, "timerAshtongueDefender", 41180, nil, nil, 1)
local timerSorcCD		= mod:NewTimer(30, "timerAshtongueSorcerer", 40520, nil, nil, 1)

mod:AddBoolOption("ShowRespawn", true)

local function addsWestLoop(self)
	warnAdds:Show(DBM_COMMON_L.WEST)

	self:Schedule(50, addsWestLoop, self)
	timerAddsCD:Schedule(10, 40, DBM_COMMON_L.WEST)
end

local function addsEastLoop(self)
	warnAdds:Show(DBM_COMMON_L.EAST)

	self:Schedule(50, addsEastLoop, self)
	timerAddsCD:Schedule(10, 40, DBM_COMMON_L.EAST)
end

local function sorcLoop(self)
	warnSorc:Show()
	self:Schedule(30, sorcLoop, self)
	timerSorcCD:Schedule(5, 25)
end

local function defenderLoop(self)
	warnDefender:Show()
	self:Schedule(30, defenderLoop, self)
	timerDefenderCD:Schedule(10, 20)
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 34189 and args:GetDestCreatureID() == 23191 then
		DBM:StartCombat(self)

		self:SetStage(1)
		self.vb.AddsWestCount = 0

		self:RegisterShortTermEvents(
                	"SWING_DAMAGE",
                	"SWING_MISSED",
                	"UNIT_SPELLCAST_SUCCEEDED")

		timerCombatStart:Start()
		timerAddsCD:Start(11, DBM_COMMON_L.EAST or "East")
		timerAddsCD:Start(18, DBM_COMMON_L.WEST or "West")

		timerDefenderCD:Schedule(6,4)
		timerSorcCD:Schedule(6,4)

		self:Schedule(10, defenderLoop, self)
        	self:Schedule(10, sorcLoop, self)
        	self:Schedule(18, addsWestLoop, self)
        	self:Schedule(11, addsEastLoop, self)
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)

        if msg == L.Death then
                DBM:EndCombat(self, true) --wipe
		
		if self.Options.ShowRespawn then
			DBT:CreateBar(293, DBM_CORE_L.TIMER_RESPAWN:format(L.name), "Interface\\Icons\\Spell_Holy_BorrowedTime")
		end

                self:UnregisterShortTermEvents()

                timerAddsCD:Stop()
                timerDefenderCD:Stop()
                timerSorcCD:Stop()
                self:Unschedule(addsWestLoop)
                self:Unschedule(addsEastLoop)
                self:Unschedule(sorcLoop)
                self:Unschedule(defenderLoop)
        end
end

function mod:SWING_DAMAGE(_, sourceName)
	if sourceName == L.name and self.vb.phase == 1 then
		self:UnregisterShortTermEvents()
		self:SetStage(2)
		warnPhase2:Show()
		timerAddsCD:Stop()
		timerDefenderCD:Stop()
		timerSorcCD:Stop()
		self:Unschedule(addsWestLoop)
		self:Unschedule(addsEastLoop)
		self:Unschedule(sorcLoop)
		self:Unschedule(defenderLoop)
	end
end
mod.SWING_MISSED = mod.SWING_DAMAGE

function mod:UNIT_SPELLCAST_SUCCEEDED(_, spellName)
	if (spellName == GetSpellInfo(40607) or spellName == GetSpellInfo(40955)) and self.vb.phase == 1 and self:AntiSpam(3, 1) then
		self:UnregisterShortTermEvents()
		self:SetStage(2)
		warnPhase2:Show()
		timerAddsCD:Stop()
		timerDefenderCD:Stop()
		timerSorcCD:Stop()
		self:Unschedule(addsWestLoop)
		self:Unschedule(addsEastLoop)
		self:Unschedule(sorcLoop)
		self:Unschedule(defenderLoop)
	end
end
