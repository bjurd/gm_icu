concommand.Remove("icu_start") -- Substitute with ULX
concommand.Remove("icu_stop")



--- @class ulx_CommandData
--- @field type ULib_Command
--- @field hint string|nil
--- @field min number|nil
--- @field max number|nil
--- @field default number|nil
--- @field invisible boolean|nil

--- @class ulx_Command
--- @field addParam fun(self: ulx_Command, Data: ulx_CommandData)
--- @field defaultAccess fun(self: ulx_Command, Access: string)
--- @field help fun(self: ulx_Command, HelpText: string)
--- @field setOpposite fun(self: ulx_Command, Command: string, Args: table, SayCommand: string|table|nil, HideSay: boolean|nil, NoSpace: boolean|nil)

--- @class ulx
--- @field command fun(Category: string, Command: string, Callback: function, SayCommand: string|nil, HideSay: boolean|nil, NoSpace: boolean|nil, Unsafe: boolean|nil): ulx_Command
--- @field fancyLogAdmin fun(Target: Player, Message: string, ...: any)
--- @field logString fun(Message: string, LogToMain: boolean|nil)
_G.ulx = ulx --[[@as ulx]]

--- @class ULib_Command

--- @class ULib_Commands
--- @field PlayerArg ULib_Command
--- @field BoolArg ULib_Command
--- @field round ULib_Command

--- @class ULib
--- @field cmds ULib_Commands
--- @field ACCESS_ADMIN string
--- @field tsayError fun(Target: Player, Message: string)



--- @param Caller Player
--- @param Target Player
--- @param Stop boolean|nil
function ulx.icu_start(Caller, Target, Stop)
	if Stop then
		if Caller:IsICUControlling() then
			icu.Stop(Caller) -- Do this first so the log is right
			ulx.fancyLogAdmin(Caller, "#A stopped controlling")
		else
			ULib.tsayError(Caller, "You're not controlling anyone!")
		end

		return
	end

	if not Caller:IsValid() then
		ULib.tsayError(Caller, "Do not use iControlU from server console!")
		return
	end

	if not Target:IsValid() then
		ULib.tsayError(Caller, "Can't find that person...")
		return
	end

	if Target == Caller then
		ULib.tsayError(Caller, "You can't control yourself!")
		return
	end

	if Target:IsICUTargeted() then
		ULib.tsayError(Caller, string.format("%s is already being controlled by %s!", Target:Nick(), Target:GetICUController():_ofnNick()))
		return
	end

	ulx.fancyLogAdmin(Caller, "#A began controlling #T", Target)
	icu.Start(Caller, Target)
end

local icu = ulx.command("Fun", "ulx icu", ulx.icu_start)
icu:addParam({ type = ULib.cmds.PlayerArg })
icu:addParam({ type = ULib.cmds.BoolArg, invisible = true })
icu:defaultAccess(ULib.ACCESS_ADMIN)
icu:help("Take control over a player")
icu:setOpposite("ulx icu_stop", { nil, true, true }) -- I would like this to be "ulx icu stop" or something but no can do



timer.Create("iControlU:ULXLogControls", 10, 0, function()
	local Message = "[iControlU]\n%d %s %s under control!\n"
	local Controlling = 0

	for _, Player in player.Iterator() do
		if Player:IsICUControlling() then
			local Target = Player:GetICUTarget()

			Message = Message .. Player:_ofnNick() .. " -> " .. Target:_ofnNick() .. "\n"
			Controlling = Controlling + 1
		end
	end

	if Controlling > 0 then
		Message = string.format(
			Message,
			Controlling,
			Controlling == 1 and "player" or "players", -- Grammar is important!
			Controlling == 1 and "is" or "are"
		)

		Message = Message:Trim()
		ulx.logString(Message)
	end
end)
