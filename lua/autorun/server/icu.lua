--- @class StoredCommand
--- @field ForwardMove number
--- @field SideMove number
--- @field UpMove number
--- @field ViewAngles Angle
--- @field Buttons number
--- @field Impulse number

--- @type table<Player, StoredCommand[]>
local StoredMovement = {}



--- @param Search string
--- @return Player|boolean
local function FindPlayer(Search)
	local Found = player.GetBySteamID(Search) or player.GetBySteamID64(Search)
	if Found then return Found end

	Search = Search:lower()

	for _, Player in player.Iterator() do
		if Player:Nick():lower():find(Search) then
			return Player
		end
	end

	return false
end

--- @param Player Player
local function ICU_Stop(Player)
	local Target = Player:GetNWEntity("ICU:Target", NULL)

	if isentity(Target) and Target:IsValid() then
		Target:SetNWEntity("ICU:Controller", NULL)
	end

	Player:SetNWEntity("ICU:Target", NULL)

	Player:UnSpectate()
	Player:Spawn()

	StoredMovement[Player] = nil
	StoredMovement[Target] = nil
end

--- @param Player Player
--- @param Target Player
local function ICU_Start(Player, Target)
	ICU_Stop(Player)

	Player:SetNWEntity("ICU:Target", Target)
	Target:SetNWEntity("ICU:Controller", Player)

	Player:StripWeapons()
	Player:Spectate(OBS_MODE_IN_EYE)
	Player:SpectateEntity(Target)

	StoredMovement[Player] = {}
end

concommand.Add("icu_start", function(Player, _, Args, ArgStr)
	if not Player:IsValid() or not Player:IsAdmin() then
		return
	end

	if #Args < 1 then
		Player:PrintMessage(HUD_PRINTCONSOLE, "No target data provided!")
		return
	end

	local Target = FindPlayer(ArgStr)
	if not Target then
		Player:PrintMessage(HUD_PRINTCONSOLE, "Target not found!")
		return
	end
	--- @cast Target Player

	ICU_Start(Player, Target)
end)

concommand.Add("icu_stop", function(Player)
	if not Player:IsValid() or not Player:IsAdmin() then
		return
	end

	ICU_Stop(Player)
end)

hook.Add("StartCommand", "icu", function(Player, Command)
	local Target = Player:GetNWEntity("ICU:Target")
	local Controller = Player:GetNWEntity("ICU:Controller")

	if Target:IsValid() then -- Is a controller
		local StoredCommands = StoredMovement[Player]

		if not StoredCommands then
			StoredCommands = {}
			StoredMovement[Player] = StoredCommands
		end

		table.insert(StoredCommands, {
			ForwardMove = Command:GetForwardMove(),
			SideMove = Command:GetSideMove(),
			UpMove = Command:GetUpMove(),
			ViewAngles = Command:GetViewAngles(),
			Buttons = Command:GetButtons(),
			Impulse = Command:GetImpulse()
		} --[[@as StoredCommand]] )

		print("Stored view ", Command:GetViewAngles())

		return
	end

	if Controller:IsValid() then -- Is a target
		Command:ClearButtons()
		Command:ClearMovement()

		local StoredCommands = StoredMovement[Controller]

		if StoredCommands and #StoredCommands > 0 then
			local StoredCommand = table.remove(StoredCommands, 1) --[[@as StoredCommand]]

			Command:SetForwardMove(StoredCommand.ForwardMove)
			Command:SetSideMove(StoredCommand.SideMove)
			Command:SetUpMove(StoredCommand.UpMove)
			Command:SetViewAngles(StoredCommand.ViewAngles)
			Command:SetButtons(StoredCommand.Buttons)
			Command:SetImpulse(StoredCommand.Impulse)

			Player:SetEyeAngles(StoredCommand.ViewAngles)

			print("Loaded view ", StoredCommand.ViewAngles)
		end

		return
	end
end)

hook.Add("PlayerDisconnected", "icu", function(Player)
	local Target = Player:GetNWEntity("ICU:Target")
	local Controller = Player:GetNWEntity("ICU:Controller")

	if Target:IsValid() then
		ICU_Stop(Player)
	end

	if Controller:IsValid() then
		ICU_Stop(Controller)
	end
end)
