local mod	= DBM:NewMod("Lucifron", "DBM-MC", 1)
local L		= mod:GetLocalizedStrings()

mod:SetRevision("20220518110528")
mod:SetCreatureID(12118)--, 12119

mod:SetModelID(13031)
mod:SetUsedIcons(1, 2)

mod:RegisterCombat("combat")

mod:RegisterEventsInCombat(
	"SPELL_CAST_START 20604",
	"SPELL_CAST_SUCCESS 19702 19703",
--	"SPELL_AURA_APPLIED 20604",
	"SPELL_AURA_REMOVED 20604"
)

local warnDoom		= mod:NewSpellAnnounce(19702, 2)
local warnCurse		= mod:NewSpellAnnounce(19703, 3)
local warnMC		= mod:NewTargetNoFilterAnnounce(20604, 4)

local specWarnMC	= mod:NewSpecialWarningYou(20604, nil, nil, nil, 1, 2)
local yellMC		= mod:NewYell(20604)

local timerCurseCD	= mod:NewCDTimer(20.5, 19703, nil, nil, nil, 3, nil, DBM_COMMON_L.CURSE_ICON)--20-25N)
local timerDoomCD	= mod:NewCDTimer(10+10, 19702, nil, nil, nil, 3, nil, DBM_COMMON_L.MAGIC_ICON)

mod:AddSetIconOption("SetIconOnMC", 20604, true, false, {1, 2})

mod.vb.lastIcon = 1

function mod:OnCombatStart(delay)
	self.vb.lastIcon = 1
	timerDoomCD:Start(7-delay)--7-8
	timerCurseCD:Start(12-delay)--12-15
end

do
	local MindControl = DBM:GetSpellInfo(20604)
	function mod:MCTarget(targetname, uId)
		if not targetname then return end
		if not DBM:GetRaidRoster(targetname) then return end--Ignore junk target scans that include pets
		if self.Options.SetIconOnMC then
			self:SetIcon(targetname, self.vb.lastIcon)
		end
		warnMC:CombinedShow(1-0.7, targetname)--Shorter throttle in the target scan since point of target scan is actual early warning
		if targetname == UnitName("player") then
			specWarnMC:Show()
			specWarnMC:Play("targetyou")
			yellMC:Yell()
		end
		if self.vb.lastIcon == 1 then
			self.vb.lastIcon = 2
		else
			self.vb.lastIcon = 1
		end
	end

	function mod:SPELL_CAST_START(args)
		local spellName = args.spellName
		if spellName == MindControl and args:IsSrcTypeHostile() then
			self:BossTargetScanner(args.sourceGUID, "MCTarget", 0.2, 8)
		end
	end

	--[[function mod:SPELL_AURA_APPLIED(args)
		--if args.spellId == 20604 then
		if args.spellName == MindControl then
			warnMC:CombinedShow(1, args.destName)
		end
	end--]]

	function mod:SPELL_AURA_REMOVED(args)
		--if args.spellId == 20604 then
		if args.spellName == MindControl and args:IsDestTypePlayer() then
			if self.Options.SetIconOnMC then
				self:SetIcon(args.destName, 0)
			end
		end
	end
end

do
	local Doom, Curse = DBM:GetSpellInfo(19702), DBM:GetSpellInfo(19703)
	function mod:SPELL_CAST_SUCCESS(args)
		--local spellId = args.spellId
		local spellName = args.spellName
		--if spellId == 19702 then
		if spellName == Doom then
			warnDoom:Show()
--			timerDoom:Start()
			timerDoomCD:Start()
		--elseif spellId == 19703 then
		elseif spellName == Curse then
			warnCurse:Show()
			timerCurseCD:Start()
		end
	end
end
