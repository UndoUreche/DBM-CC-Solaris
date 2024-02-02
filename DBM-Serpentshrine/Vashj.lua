local mod	= DBM:NewMod("Vashj", "DBM-Serpentshrine")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220813164045")
mod:SetCreatureID(21212)
mod:SetUsedIcons(1)
mod:SetHotfixNoticeRev(20210919000000)
mod:SetMinSyncRevision(20210919000000)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_AURA_APPLIED 38280 38575",
	"SPELL_AURA_REMOVED 38280 38132 38112",
	"SPELL_CAST_START 38253 38145",
	"SPELL_CAST_SUCCESS 38316 38509",
	"UNIT_DIED",
	"CHAT_MSG_MONSTER_YELL",
	"CHAT_MSG_LOOT",
	"UNIT_AURA"
)

local warnCharge		= mod:NewTargetNoFilterAnnounce(38280, 4)
local warnEntangle		= mod:NewSpellAnnounce(38316, 3)
local warnPhase2		= mod:NewPhaseAnnounce(2)
local warnElemental		= mod:NewAnnounce("WarnElemental", 4, 31687)
local warnStrider		= mod:NewAnnounce("WarnStrider", 3, 475)
local warnNaga			= mod:NewAnnounce("WarnNaga", 3, 2120)
local warnShield		= mod:NewAnnounce("WarnShield", 3, 38112)
local warnLoot			= mod:NewAnnounce("WarnLoot", 4, 38132)
local warnPhase3		= mod:NewPhaseAnnounce(3)

--local specWarnCore		= mod:NewSpecialWarning("SpecWarnCore", nil, nil, nil, 1, 8)
local specWarnCharge	= mod:NewSpecialWarningMoveAway(38280, nil, nil, nil, 1, 2)
local yellCharge		= mod:NewYell(38280)
local specWarnElemental	= mod:NewSpecialWarning("SpecWarnElemental")
local specWarnToxic		= mod:NewSpecialWarningMove(38575, nil, nil, nil, 1, 2)

--newTimer(self, timerType, timer, spellId, timerText, optionDefault, optionName, colorType, texture, inlineIcon, keep, countdown, countdownMax, r, g, b)
local timerEntangleCD	= mod:NewCDTimer(18.2, 38316, nil, nil, nil, 3)
local timerCharge		= mod:NewTargetTimer(20, 38280, nil, nil, nil, 3)
local timerChargeCD		= mod:NewCDTimer(7.25, 38280, nil, false, nil, 3)
local timerShockBlastCD	= mod:NewCDTimer(10.85, 38509, nil, nil, nil, 3)

local timerElementalCD	= mod:NewTimer(50, "TimerElemental", 39088, nil, nil, 1)
local timerElemental	= mod:NewTimer(15, "TimerElementalActive", 39088, nil, nil, 1)
local timerStrider		= mod:NewTimer(60, "TimerStrider", 475, nil, nil, 1)
local timerNaga			= mod:NewTimer(45, "TimerNaga", 2120, nil, nil, 1)

mod:AddRangeFrameOption(10, 38280)
mod:AddSetIconOption("ChargeIcon", 38280, false, false, {1})
--mod:AddBoolOption("AutoChangeLootToFFA", true)

mod.vb.shieldLeft = 4
mod.vb.nagaCount = 1
mod.vb.striderCount = 1
mod.vb.elementalCount = 1
--local lootmethod, masterlooterRaidID
--local elementals = {}

function mod:OnCombatStart(delay)
--	table.wipe(elementals)
	self:SetStage(1)

	timerEntangleCD:Start(25.45-delay)
	timerChargeCD:Start(18.15-delay)
	timerShockBlastCD:Start(14.55-delay)
end

function mod:OnCombatEnd()
	if self.Options.RangeFrame then
		DBM.RangeCheck:Hide()
	end
	self:UnregisterShortTermEvents()
--	if DBM:IsInGroup() and self.Options.AutoChangeLootToFFA and DBM:GetRaidRank() == 2 then
--		if masterlooterRaidID then
--			SetLootMethod(lootmethod, "raid"..masterlooterRaidID)
--		else
--			SetLootMethod(lootmethod)
--		end
--	end
end

function mod:SPELL_AURA_APPLIED(args)
	local spellId = args.spellId
	
	if spellId == 38280 then
		timerCharge:Start(args.destName)
		timerChargeCD:Start()
		
		if args:IsPlayer() then
			specWarnCharge:Show()
			specWarnCharge:Play("runout")
			yellCharge:Yell()
			if self.Options.RangeFrame then
				DBM.RangeCheck:Show(10)
			end
		else
			warnCharge:Show(args.destName)
		end
		if self.Options.ChargeIcon then
			self:SetIcon(args.destName, 1, 20)
		end
	elseif spellId == 38575 and args:IsPlayer() and self:AntiSpam() then
		specWarnToxic:Show()
		specWarnToxic:Play("runaway")
	end
end

function mod:SPELL_AURA_REMOVED(args)
	local spellId = args.spellId
	if spellId == 38280 then
		timerCharge:Stop(args.destName)
		if self.Options.ChargeIcon then
			self:SetIcon(args.destName, 0)
		end
		if args:IsPlayer() then
			if self.Options.RangeFrame then
				DBM.RangeCheck:Hide()
			end
		end
	elseif spellId == 38132 then
		if self.Options.LootIcon then
			self:SetIcon(args.destName, 0)
		end
	elseif spellId == 38112 then--and not self:IsTrivial()
		DBM:AddMsg("Magic Barrier unhidden from combat log. Notify Zidras on Discord or GitHub")
		self.vb.shieldLeft = self.vb.shieldLeft - 1
		warnShield:Show(self.vb.shieldLeft)
	end
end

local function NagaSpawn(self)
	self.vb.nagaCount = self.vb.nagaCount + 1
	warnNaga:Schedule(40, tostring(self.vb.nagaCount))
	timerNaga:Start(45, tostring(self.vb.nagaCount))
	self:Schedule(45, NagaSpawn, self)
end

local function StriderSpawn(self)
	self.vb.striderCount = self.vb.striderCount + 1
	warnStrider:Schedule(55, tostring(self.vb.striderCount))
	timerStrider:Start(60, tostring(self.vb.striderCount))
	self:Schedule(60, StriderSpawn, self)
end

local function TaintedSpawn(self)
	self.vb.elementalCount = self.vb.elementalCount + 1
	specWarnElemental:Show()
	timerElemental:Start()
	warnElemental:Schedule(45, tostring(self.vb.elementalCount))
	timerElementalCD:Start(50, tostring(self.vb.elementalCount))
	self:Schedule(50, TaintedSpawn, self)
end

local function transitionToPhaseTwo(self, delta) 
	delta = delta == nil and 0 or delta
	
	self:SetStage(2)
	
	self.vb.nagaCount = 1
	self.vb.striderCount = 1
	self.vb.elementalCount = 1
	self.vb.shieldLeft = 4
	
	timerNaga:Start(45-delta, tostring(self.vb.nagaCount))
	warnNaga:Schedule(40-delta, tostring(self.vb.elementalCount))
	self:Schedule(45-delta, NagaSpawn, self)
	
	timerElementalCD:Start(50-delta, tostring(self.vb.elementalCount))
	warnElemental:Schedule(45-delta, tostring(self.vb.elementalCount))
	self:Schedule(50-delta, TaintedSpawn, self)
	
	timerStrider:Start(60-delta, tostring(self.vb.striderCount))
	warnStrider:Schedule(55-delta, tostring(self.vb.striderCount))
	self:Schedule(60-delta, StriderSpawn, self)
	
	self:RegisterShortTermEvents(
		"UNIT_SPELLCAST_FAILED_QUIET_UNFILTERED"
	)
end

function mod:SPELL_CAST_START(args)

--	if args.spellId == 38253 then and not elementals[args.sourceGUID] then
--		specWarnElemental:Show()
--		timerElemental:Start()
--		timerElementalCD:Start(50, tostring(self.vb.elementalCount))
--		warnElemental:Schedule(45, tostring(self.vb.elementalCount))
--		elementals[args.sourceGUID] = true
--	else
	if args.spellId == 38145 and mod:GetStage() == 1 then
		transitionToPhaseTwo(self, 2.4)
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	local spellId = args.spellId
	if spellId == 38316 then
		timerEntangleCD:Start()
		warnEntangle:Show()
	elseif spellId == 38509 then
		timerShockBlastCD:Start()
	end
end

function mod:UNIT_DIED(args)
	local cid = self:GetCIDFromGUID(args.destGUID)
	if cid == 22009 then
		self.vb.elementalCount = self.vb.elementalCount + 1
	end
end

function mod:UNIT_SPELLCAST_FAILED_QUIET_UNFILTERED(uId, spellName)

	if spellName == GetSpellInfo(24390) and self:AntiSpam(2, 2) then -- Opening. This is an experimental feature to try and detect when an Invis KV Shield Generator dies
		DBM:Debug("UNIT_SPELLCAST_FAILED_QUIET_UNFILTERED fired for player:" .. (uId and UnitName(uId) or "Unknown") .. " with the spell: " .. spellName)
		self.vb.shieldLeft = self.vb.shieldLeft - 1
		warnShield:Show(self.vb.shieldLeft)
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)

	if msg == L.DBM_VASHJ_YELL_PHASE2 or msg:find(L.DBM_VASHJ_YELL_PHASE2) then
		warnPhase2:Show()
		
		timerEntangleCD:Cancel()
		timerChargeCD:Cancel()
		timerShockBlastCD:Cancel()
	
	elseif msg == L.DBM_VASHJ_YELL_PHASE3 or msg:find(L.DBM_VASHJ_YELL_PHASE3) then
		self:SetStage(3)
		warnPhase3:Show()
		
		timerEntangleCD:Start(25.45)
		timerChargeCD:Start(18.15)
		timerShockBlastCD:Start(14.55)
		
		timerNaga:Cancel()
		warnNaga:Cancel()
		timerElementalCD:Cancel()
		warnElemental:Cancel()
		timerStrider:Cancel()
		warnStrider:Cancel()
		
		self:Unschedule(NagaSpawn)
		self:Unschedule(StriderSpawn)
		self:UnregisterShortTermEvents()
	end
end

function mod:CHAT_MSG_LOOT(msg)
	-- DBM:AddMsg(msg) --> Meridium receives loot: [Magnetic Core]
	local player, itemID = msg:match(L.LootMsg)
	if player and itemID and tonumber(itemID) == 31088 and self:IsInCombat() then
		-- attempt to correct player name when the player is the one looting
		if DBM:GetGroupId(player) == 0 then -- workaround to determine that player doesn't exist in our group
			if player == DBM_COMMON_L.YOU then -- LOOT_ITEM_SELF = "You receive loot: %s." Not useable in all locales since there is no pronoun or not translateable "YOU" (ES: Recibes botín: %s.")
				player = UnitName("player") -- convert localized "You" to player name
			else -- logically is more prone to be innacurate, but do it anyway to account for the locales without a useable YOU and prevent UNKNOWN player name on sync handler
				player = UnitName("player")
			end
		end
		self:SendSync("LootMsg", player)
	end
end

function mod:UNIT_AURA(unit)

	if UnitName(unit) == "Lady Vashj" and UnitBuff(unit, "Magic Barrier") ~= nil and mod:GetStage() == 1 then 
	
		mod:SendSync("Phase2")
	end
end

function mod:OnSync(event, playerName)

	if not self:IsInCombat() then 
		return 
	end
	
	if event == "LootMsg" and playerName then
		playerName = DBM:GetUnitFullName(playerName)
		if self:AntiSpam(2, playerName) then
--			if playerName == UnitName("player") then
--				specWarnCore:Show()
--				specWarnCore:Play("useitem")
--			else
				warnLoot:Show(playerName)
--			end
		end
	elseif event == "Phase2" and mod:GetStage() == 1 then
		transitionToPhaseTwo(self)
	end
end