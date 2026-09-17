local mod	= DBM:NewMod("Algalon", "DBM-Ulduar")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220821232003")
mod:SetCreatureID(32871)
--mod:RegisterCombat("combat") unreliable on cc
mod:RegisterCombat("yell", L.YellPull)
mod:RegisterKill("yell", L.YellKill) -- fires 24 seconds after fight ends, not accurate enough. Workaround it by using Self Stun UNIT_SPELLCAST_SUCCEEDED, which is fired when he turns friendly and fight is won. But CC doesn't use boss unit frames, so we stick to this
mod:SetWipeTime(20)

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 64584 64443",
	"SPELL_CAST_SUCCESS 65108 64122 64598 62301",
	"SPELL_AURA_APPLIED 64412",
	"SPELL_AURA_APPLIED_DOSE 64412",
	"SPELL_AURA_REMOVED 64412",
	"SPELL_DAMAGE 65108 64122",
	"SPELL_MISSED 65108 64122",
	"CHAT_MSG_RAID_BOSS_EMOTE",
	"CHAT_MSG_MONSTER_YELL",
--	"UNIT_SPELLCAST_SUCCEEDED boss1",
	"UNIT_HEALTH"
)

local warnPhase2				= mod:NewPhaseAnnounce(2, 2, nil, nil, nil, nil, nil, 2)
local warnPhase2Soon			= mod:NewPrePhaseAnnounce(2, 2)
local announcePreBigBang		= mod:NewPreWarnAnnounce(64584, 5, 3)
local announceBlackHole			= mod:NewSpellAnnounce(65108, 2)
local announcePhasePunch		= mod:NewStackAnnounce(64412, 4, nil, "Tank|Healer")

local specwarnStarLow			= mod:NewSpecialWarning("warnStarLow", "Tank|Healer", nil, nil, 1, 2)
local specWarnPhasePunch		= mod:NewSpecialWarningStack(64412, nil, 4, nil, nil, 1, 6)
local specWarnBigBang			= mod:NewSpecialWarningSpell(64584, nil, nil, nil, 3, 2)
local specWarnCosmicSmash		= mod:NewSpecialWarningDodge(64596, nil, nil, nil, 2, 2)

local timerNextBigBang			= mod:NewNextTimer(90.5, 64584, nil, nil, nil, 2) -- REVIEW! no data for 2nd cast onwards (2022/07/05 || 25 man Lord log 2022/08/02 || 25 man FM log 2022/08/07 || 10 man FM log 2022/08/09) - 91.0 || 91.0 || 91.0; 91.1; 91.0 || 91.0; 91.0
local timerBigBangCast			= mod:NewCastTimer(8, 64584, nil, nil, nil, 2, nil, DBM_COMMON_L.DEADLY_ICON)
local timerNextCollapsingStar	= mod:NewTimer(60, "NextCollapsingStar", "Interface\\Icons\\INV_Enchant_EssenceCosmicGreater", nil, nil, 2, DBM_COMMON_L.HEALER_ICON) -- Instead of 15s (retail), this event fired with 97s after the first emote and then 91s difference (S2 || 25 man Lord log 2022/08/02 || 25 man FM log 2022/08/07 || 10 man FM log 2022/08/09) - 91 || 97.5 || 97.5; 97.6, 91.0; 97.5; 97.5; 97.6; 97.6; 97.5; 97.5; 97.5 || 97.5, 91.0; 97.5; 97.5; 97.5; 97.5; 97.5
local timerCDCosmicSmash		= mod:NewNextTimer(25.5, 64596, nil, nil, nil, 3) -- Log reviewed (2022/07/05 || 25 man FM log 2022/08/07) - 25.5, 25.5, 25.5, 25.5, 25.5, 25.5, 25.6, 25.5 || 25.5, 25.5, 25.6, 25.5, 25.5, 25.5
local timerCastCosmicSmash		= mod:NewCastTimer(4.5, 64596)
local timerPhasePunch			= mod:NewTargetTimer(45, 64412, nil, "Tank", 2, 5, nil, DBM_COMMON_L.TANK_ICON)
local timerNextPhasePunch		= mod:NewNextTimer(15.5, 64412, nil, "Tank", 2, 5, nil, DBM_COMMON_L.TANK_ICON)
local enrageTimer				= mod:NewBerserkTimer(360)

local warned_star = {}
local stars = {}
local stars_hp = {}
local star_num = 1
mod.vb.warned_preP2 = false

function mod:OnCombatStart(delay)
	self:SetStage(1)
	stars = {}
	warned_star = {}
	stars_hp = {}
	star_num = 1
	self.vb.warned_preP2 = false
end

function mod:OnCombatEnd()
	DBM.BossHealth:Clear()
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellID(64584, 64443) then	-- Big Bang
		timerBigBangCast:Start()
		timerNextBigBang:Schedule(8, 82.5)
		
		announcePreBigBang:Schedule(85)
		specWarnBigBang:Show()
		
		if self:IsTank() then
			specWarnBigBang:Play("defensive")
		else
			specWarnBigBang:Play("findshelter")
		end
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(65108, 64122) then	-- Black Hole Explosion
		announceBlackHole:Show()
	elseif args:IsSpellID(64598, 62301) then	-- Cosmic Smash
		timerCastCosmicSmash:Start()
		timerCDCosmicSmash:Start()
		specWarnCosmicSmash:Show()
		specWarnCosmicSmash:Play("watchstep")
	end
end

function mod:SPELL_AURA_APPLIED(args)
	if args.spellId == 64412 then
		timerNextPhasePunch:Start()
		local amount = args.amount or 1
		if args:IsPlayer() and amount >= 4 then
			specWarnPhasePunch:Show(args.amount)
			specWarnPhasePunch:Play("stackhigh")
		end
		timerPhasePunch:Start(args.destName)
		announcePhasePunch:Show(args.destName, amount)
	end
end
mod.SPELL_AURA_APPLIED_DOSE = mod.SPELL_AURA_APPLIED

function mod:SPELL_AURA_REMOVED(args)
	if args.spellId == 64412 then
		timerPhasePunch:Cancel(args.destName)
	end
end

function mod:SPELL_DAMAGE(sourceGUID, _, _, _, _, _, spellId)
	if (spellId == 65108 or spellId == 64122) and self:AntiSpam(2, spellId .. sourceGUID) then	-- Black Hole Explosion
		if stars[sourceGUID] then
			local id = stars[sourceGUID]
			DBM.BossHealth:RemoveBoss(id)
		else
			DBM.BossHealth:RemoveLowest()
		end
	end
end
mod.SPELL_MISSED = mod.SPELL_DAMAGE

function mod:CHAT_MSG_RAID_BOSS_EMOTE(msg)
	if (msg == L.Emote_CollapsingStar or msg:find(L.Emote_CollapsingStar)) then
		
		timerNextCollapsingStar:Start()
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == L.YellPull or msg:find(L.YellPull) then
		
		local _,_, state = GetWorldStateUIInfo(1)
		local delay = 8
		
		if state == L.StateFirstPull then
			delay = 25.7
		end
		
		timerNextCollapsingStar:Schedule(delay, 16.5)
		timerCDCosmicSmash:Schedule(delay,26)
		announcePreBigBang:Schedule(delay + 85)
		timerNextBigBang:Schedule(delay,90)
		timerNextPhasePunch:Schedule(delay)
		enrageTimer:Schedule(delay)
		
	elseif msg == L.Phase2 or msg:find(L.Phase2) then
		self:SetStage(2)
		self.vb.warned_preP2 = true
		timerNextCollapsingStar:Stop()
		warnPhase2:Show()
		warnPhase2:Play("ptwo")
		DBM.BossHealth:Clear()
		DBM.BossHealth:AddBoss(32871)
	end
end

function mod:UNIT_HEALTH(uId)
	local cid = self:GetUnitCreatureId(uId)
	local guid = UnitGUID(uId)
	
	if cid == 32871 and UnitHealth(uId) / UnitHealthMax(uId) <= 0.23 and not self.vb.warned_preP2 then
		self:SendSync("Phase2")
		
	elseif cid == 32955 then
		local starHpPct = UnitHealth(uId) / UnitHealthMax(uId)
				
		self:SendSync("Star", guid, starHpPct)
	end
end

--[[
mod:RegisterOnUpdateHandler(

function(self)
	if not self:IsInCombat() then 
		return 
	end
		
	for uId in DBM:GetGroupMembers() do
		local target = uId .."target"

		if self:GetUnitCreatureId(target) == 32955 then
			
			local targetGUID = UnitGUID(target)

			if not stars[targetGUID] then
				stars[targetGUID] = L.CollapsingStar .. " " .. star_num
				
				do
					local last = 100
					
					local function getStarPercent()
						local trackingGUID = targetGUID

						for uId in DBM:GetGroupMembers() do
							local unitId = uId .. "target"
							
							if trackingGUID == UnitGUID(unitId) and mod:GetCIDFromGUID(trackingGUID) == 32955 then
								
								last = math.floor(UnitHealth(unitId)/UnitHealthMax(unitId) * 100)
								stars_hp[trackingGUID] = last
								
								return last
							end
						end
						
						return stars_hp[trackingGUID]
					end
					
					DBM.BossHealth:AddBoss(getStarPercent, stars[targetGUID])
				end
				
				star_num = star_num + 1
			end
		end
	end
end

, 0.1)
--]]

function mod:OnSync(event, guid, starHpPct)

	if event == "Phase2" and not self.vb.warned_preP2 then
		self.vb.warned_preP2 = true
		warnPhase2Soon:Show()
		
	elseif event == "Star" then
		starHpPct = tonumber(starHpPct)
		
		if not warned_star[guid] and starHpPct <= 0.25 then
			warned_star[guid] = true
			specwarnStarLow:Show()
		end
		
		if not stars[guid] then
			
			local function getStarPercent()				
				return stars_hp[guid]
			end
			
			stars_hp[guid] = 100
			star_num = star_num + 1
			
			stars[guid] = L.CollapsingStar .. " " .. star_num
			DBM.BossHealth:AddBoss(getStarPercent, stars[guid])
		else
			stars_hp[guid] = starHpPct * 100
		end
	end
end