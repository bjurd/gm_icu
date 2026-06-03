--- @class StoredCommand
--- @field ForwardMove number
--- @field SideMove number
--- @field UpMove number
--- @field ViewAngles Angle
--- @field Buttons number
--- @field Impulse number

--- @type table<Player, StoredCommand>
local StoredMovement = {}

--- @param Angle Angle
--- @return Angle
local function NormalizeViewAngles(Angle)
	Angle.p = math.Clamp(math.NormalizeAngle(Angle.p), -89, 89)
	Angle.y = math.NormalizeAngle(Angle.y)
	Angle.r = 0

	return Angle
end

--- @param Controller Player
--- @param Target Player
--- @param Command CUserCmd
--- @return Angle
local function ApplyControllerLook(Controller, Target, Command)
	local ViewAngles = NormalizeViewAngles(Angle(Target:EyeAngles()))
	local MouseX, MouseY = Command:GetMouseX(), Command:GetMouseY()

	if MouseX ~= 0 or MouseY ~= 0 then
		-- None of these cvars are userinfo so it always falls back to the default.
		-- Drats!
		local Sensitivity = tonumber(Controller:GetInfo("sensitivity")) or 3
		local Yaw = tonumber(Controller:GetInfo("m_yaw")) or 0.022
		local Pitch = tonumber(Controller:GetInfo("m_pitch")) or 0.022

		ViewAngles.y = ViewAngles.y - MouseX * Yaw * Sensitivity
		ViewAngles.p = math.Clamp(ViewAngles.p + MouseY * Pitch * Sensitivity, -89, 89)
	end

	Target:SetEyeAngles(ViewAngles)
	Target:SetNWAngle("ICU:ViewAngles", ViewAngles)

	return ViewAngles
end

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
		Target:SetNWAngle("ICU:ViewAngles", angle_zero)
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

	StoredMovement[Player] = nil
	Target:SetNWAngle("ICU:ViewAngles", Target:EyeAngles())
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
		local ViewAngles = ApplyControllerLook(Player, Target, Command)

		StoredMovement[Player] = {
			ForwardMove = Command:GetForwardMove(),
			SideMove = Command:GetSideMove(),
			UpMove = Command:GetUpMove(),
			ViewAngles = ViewAngles,
			Buttons = Command:GetButtons(),
			Impulse = Command:GetImpulse()
		} --[[@as StoredCommand]]

		Command:ClearButtons()
		Command:ClearMovement()

		return
	end

	if Controller:IsValid() then -- Is a target
		Command:ClearButtons()
		Command:ClearMovement()

		local StoredCommand = StoredMovement[Controller]

		if StoredCommand then
			local ViewAngles = StoredCommand.ViewAngles

			Command:SetForwardMove(StoredCommand.ForwardMove)
			Command:SetSideMove(StoredCommand.SideMove)
			Command:SetUpMove(StoredCommand.UpMove)
			Command:SetViewAngles(ViewAngles)
			Command:SetButtons(StoredCommand.Buttons)
			Command:SetImpulse(StoredCommand.Impulse)

			Player:SetEyeAngles(ViewAngles)
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

hook.Add("PlayerSay", "icu", function(Player, Message, IsTeam)
	local Target = Player:GetNWEntity("ICU:Target")

	if Target:IsValid() then
		Target:Say(Message, IsTeam)
		return ""
	end
end)
