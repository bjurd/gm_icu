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

hook.Add("PlayerSay", "iControlU", function(Player, Message, IsTeamChat)
	if Player:IsICUControlling() then
		icu.ForwardPlayerMessage(Player, Message, IsTeamChat)
		return ""
	end
end)

hook.Add("InitPostEntity", "iControlU", function()
	-- Block privilege escalation during control (admin->superadmin). Not perfect, but better than nothing

	if istable(ULib) then
		--- @class ucl
		--- @field query fun(Player: Player, Access: string, Hide: boolean): boolean|nil

		--- @class ULib
		--- @field ucl ucl
		--- @field isValidSteamID fun(SteamID: string)
		--- @field getPlyByID fun(SteamID: string): Player|nil
		_G.ULib = ULib --[[@as ULib]]

		--- @diagnostic disable-next-line: inject-field
		ULib.ucl._ofnQuery = ULib.ucl._ofnQuery or ULib.ucl.query

		ULib.ucl.query = function(Player, Access, Hide)
			if Player:IsValid() and Player:IsICUTargeted() then -- Server console will be NULL
				-- This uses a PlayerSay hook internally, not player_say, so it will run as the controller rather than the target depending on hook execution order.
				-- There isn't really a good easy solution here. Checking the access can cause the command to run twice (depending on execution order), but not
				-- checking the access will remove feedback messages for the executor.

				-- There's also the issue that while being controlled the target will lose their access since there's no way to differentiate between
				-- who ran what here.

				-- icu.IsForwardingMessage being `true` tells us that this is being called from PlayerSay, but that doesn't help much :(

				local Controller = Player:GetICUController()
				return ULib.ucl._ofnQuery(Controller, Access, Hide)
			else
				return ULib.ucl._ofnQuery(Player, Access, Hide)
			end
		end
	end
end)
