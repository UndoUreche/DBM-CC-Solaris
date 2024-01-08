local mod	= DBM:NewMod("LurkerBelow", "DBM-Serpentshrine")
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220813110833")
mod:SetCreatureID(21217)

--mod:SetModelID(20216)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 20568",
	"CHAT_MSG_RAID_BOSS_EMOTE",
	"UNIT_DIED",
	"UNIT_SPELLCAST_SUCCEEDED"
)

local warnSubmerge		= mod:NewAnnounce("WarnSubmerge", 2, "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendBurrow.blp")
local warnEmerge		= mod:NewAnnounce("WarnEmerge", 1, "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendUnBurrow.blp")
local warnWhirl			= mod:NewSpellAnnounce(37363, 2)

local specWarnSpout		= mod:NewSpecialWarningSpell(37433, nil, nil, nil, 2, 2)

local timerSubmerge		= mod:NewTimer(90.75, "TimerSubmerge", "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendBurrow.blp", nil, nil, 6)
local timerEmerge		= mod:NewTimer(60, "TimerEmerge", "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendUnBurrow.blp", nil, nil, 6)
local timerSpoutCD		= mod:NewCDTimer(60, 37433, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON)
local timerSpoutCast	= mod:NewCastTimer(3, 37433, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON)
local timerSpout		= mod:NewBuffActiveTimer(15, 37433, nil, nil, nil, 3, nil, DBM_COMMON_L.DEADLY_ICON)
local timerWhirlCD		= mod:NewCDTimer(34.15, 37363, nil, nil, nil, 2)


mod.vb.firstWhirl = true
mod.vb.submerged = false
mod.vb.guardianKill = 0
mod.vb.ambusherKill = 0

emerged = function(self)
	self.vb.submerged = false
	timerEmerge:Cancel()
	
	warnEmerge:Show()
	timerSpoutCD:Start(10)
	
	timerWhirlCD:Start(26)
	
	timerSubmerge:Start()
	self:Schedule(90.75, submerged, self, self)
end

submerged = function(self)
	self:SetStage(2)
	self.vb.submerged = true
	self.vb.guardianKill = 0
	self.vb.ambusherKill = 0
	timerSubmerge:Cancel()
	timerSpoutCD:Cancel()
	timerWhirlCD:Cancel()
	warnSubmerge:Show()
	
	timerEmerge:Start()
	self:Schedule(60, emerged, self)
end

function mod:OnCombatStart(delay)
	mod.vb.firstWhirl = true
	mod.vb.spoutTimer = 39

	self:SetStage(1)
	self.vb.submerged = false
	timerWhirlCD:Start(18-delay)
	timerSpoutCD:Start(38.8-delay)
	
	timerSubmerge:Start(91-delay)
	
	self:Schedule(91-delay, submerged, self, self)
	--self:Schedule(1-delay, submerged, self, self)
end
--[[
function mod:SPELL_CAST_START(args)
	if args.spellId == 20568 then -- Ragnaros Emerge. Fires when boss emerges
		self:SetStage(1)
		timerEmerge:Cancel()
		warnEmerge:Show()
		timerSubmerge:Start()
		self:Schedule(60, submerged, self, self)
	end
end
]]--
function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, source)
	if (source or "") == L.name then
		specWarnSpout:Show()
		specWarnSpout:Play("watchwave")
		timerSpoutCast:Start()
		timerSpout:Schedule(3) -- takes 3 seconds to start Spout (from EMOTE to UNIT_SPELLCAST_SUCCEEDED)
		timerSpoutCD:Start()
	end
end

function mod:UNIT_DIED(args)
	local cId = self:GetCIDFromGUID(args.destGUID)
	if cId == 21865 then
		self.vb.ambusherKill = self.vb.ambusherKill + 1
		if self.vb.ambusherKill == 6 and self.vb.guardianKill == 3 and self.vb.submerged then
			self:Unschedule(emerged)
			self:Schedule(2, emerged, self, self)
		end
	elseif cId == 21873 then
		self.vb.guardianKill = self.vb.guardianKill + 1
		if self.vb.ambusherKill == 6 and self.vb.guardianKill == 3 and self.vb.submerged then
			self:Unschedule(emerged)
			self:Schedule(2, emerged, self, self)
		end
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(_, spellName)

	--[[This does not work. CC doesn't pass event

	if spellName == GetSpellInfo(28819) and self:AntiSpam(2, 1) then--Submerge Visual
		DBM:AddMsg("Submerge Visual unhidden from event log. Notify Zidras on Discord or GitHub")
		self:SendSync("Submerge")
	else
	]]--
	if spellName == GetSpellInfo(37660) then
		warnWhirl:Show()
		timerWhirlCD:Start()
		
		if mod.vb.firstWhirl == true then
			mod.vb.firstWhirl = false
			
			timerSpoutCD:Cancel()
			timerSpoutCD:Start(38 - 18.15)
			
			timerSubmerge:Cancel()
			timerSubmerge:Start(72.85)
			
			self:Unschedule(submerged)
			self:Schedule(72.85, submerged, self, self)
		end
	end
end

function mod:OnSync(msg)
	if not self:IsInCombat() then return end
	if msg == "Submerge" then
		DBM:AddMsg("Submerge is being synced by something. Notify Zidras on Discord or GitHub with a Transcriptor log")
--[[	self.vb.submerged = true
		self.vb.guardianKill = 0
		self.vb.ambusherKill = 0
		timerSubmerge:Cancel()
		timerSpoutCD:Cancel()
		timerWhirlCD:Cancel()
		warnSubmerge:Show()
		timerEmerge:Start()
		self:Schedule(60, emerged, self)
]]	end
end
