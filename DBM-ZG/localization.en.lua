local L

-------------------
--  Venoxis  --
-------------------
L = DBM:GetModLocalization("Venoxis")

L:SetGeneralLocalization{
	name = "High Priest Venoxis"
}
L:SetWarningLocalization{
	warnPhase2Soon	= "Phase 2 soon"
}
L:SetOptionLocalization{
	warnPhase2Soon	= "Announce when phase 2 is about to start",
	RangeFrame		= "Show range frame"
}

-------------------
--  Jeklik  --
-------------------
L = DBM:GetModLocalization("Jeklik")

L:SetGeneralLocalization{
	name = "High Priestess Jeklik"
}

L:SetMiscLocalization{
	SummonBats	= "I command you to rain fire down upon these invaders!"
}

L:SetTimerLocalization{
	TimerBats	= "Fire Bats CD",
}
L:SetOptionLocalization{
	TimerBats	= "Show timer for fire bats cooldown",
	WarnPhase2Soon		= "Show pre-warning for Phase 2"
}

L:SetWarningLocalization{
	WarnPhase2Soon		= "Phase 2 Soon"
}

-------------------
--  Marli  --
-------------------
L = DBM:GetModLocalization("Marli")

L:SetGeneralLocalization{
	name = "High Priestess Mar'li"
}

L:SetMiscLocalization({
	Transform1	= "Draw me to your web mistress Shadra, unleash your venom!",
	Transform2	= "Shadra, make of me your avatar!",
	TransformBack	= "The brood shall not fall!"
})

-------------------
--  Thekal  --
-------------------
L = DBM:GetModLocalization("Thekal")

L:SetGeneralLocalization{
	name = "High Priest Thekal"
}

L:SetWarningLocalization({
	WarnSimulKill	= "First add down - Resurrection in ~10 seconds"
})

L:SetTimerLocalization({
	TimerSimulKill	= "Resurrection"
})

L:SetOptionLocalization({
	WarnSimulKill	= "Announce first mob down, resurrection soon",
	TimerSimulKill	= "Show timer for priest resurrection"
})

L:SetMiscLocalization({
	PriestDied	= "%s dies.",
	YellPhase2	= "Shirvallah, fill me with your RAGE!",
	YellKill	= "Hakkar binds me no more!  Peace at last!",
	Thekal		= "High Priest Thekal",
	Zath		= "Zealot Zath",
	LorKhan		= "Zealot Lor'Khan"
})

-------------------
--  Arlokk  --
-------------------
L = DBM:GetModLocalization("Arlokk")

L:SetGeneralLocalization{
	name = "High Priestess Arlokk"
}

L:SetMiscLocalization({
	CombatStart	= "Bethekk, your priestess calls upon your might!",
})

-------------------
--  Hakkar  --
-------------------
L = DBM:GetModLocalization("Hakkar")

L:SetGeneralLocalization{
	name = "Hakkar the Soulflayer"
}

-------------------
--  Bloodlord  --
-------------------
L = DBM:GetModLocalization("Bloodlord")

L:SetGeneralLocalization{
	name = "Bloodlord Mandokir"
}
L:SetMiscLocalization{
	Bloodlord 	= "Bloodlord Mandokir",
	Ohgan		= "Ohgan"
}

L:SetTimerLocalization{
	TimerWhirlWind	= "WhirlWind CD",
}
L:SetOptionLocalization{
	TimerWhirlWind	= "Show timer for whirlwind cooldown",
}

-------------------
--  Edge of Madness  --
-------------------
L = DBM:GetModLocalization("EdgeOfMadness")

L:SetGeneralLocalization{
	name = "Edge of Madness"
}
L:SetMiscLocalization{
	Hazzarah = "Hazza'rah",
	Renataki = "Renataki",
	Wushoolay = "Wushoolay",
	Grilek = "Gri'lek"
}

-------------------
--  Gahz'ranka  --
-------------------
L = DBM:GetModLocalization("Gahzranka")

L:SetGeneralLocalization{
	name = "Gahz'ranka"
}

-------------------
--  Jindo  --
-------------------
L = DBM:GetModLocalization("Jindo")

L:SetGeneralLocalization{
	name = "Jin'do the Hexxer"
}