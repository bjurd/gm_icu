concommand.Add("icu_start", function(Player, _, Args, ArgStr)
	if not Player:IsValid() then
		MsgN("Do not use iControlU from server console!")
		return
	end

	if not Player:IsAdmin() then
		return
	end

	local Target = icu.FindPlayer(ArgStr)
	if not Target:IsValid() then
		Player:PrintMessageFmt(HUD_PRINTTALK, "Can't find target %s", ArgStr)
		return
	end

	icu.Start(Player, Target)
end)

concommand.Add("icu_stop", function(Player)
	if not Player:IsValid() then
		MsgN("Do not use iControlU from server console!")
		return
	end

	if not Player:IsAdmin() then
		return
	end

	icu.Stop(Player)
end)

hook.Add("PlayerDisconnected", "iControlU", function(Player)
	if Player:IsICUControlling() then
		icu.Stop(Player)
	end

	if Player:IsICUTargeted() then
		icu.Stop(Player:GetICUController())
	end
end)

hook.Add("PlayerSay", "iControlU", function(Player, Message, TeamChat)
	if Player:IsICUControlling() then
		local Target = Player:GetICUTarget()
		Target:Say(Message, TeamChat)

		return ""
	end
end)
