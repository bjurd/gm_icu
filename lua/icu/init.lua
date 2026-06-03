AddCSLuaFile()

--- @class StoredCommand
--- @field ForwardMove number
--- @field SideMove number
--- @field UpMove number
--- @field ViewAngles Angle
--- @field Buttons number
--- @field Impulse number
--- Definitely real CUserCmd fields trust
--- @field Weapon string
--- @field Clip1 number
--- @field Clip2 number
--- @field Ammo1 number
--- @field Ammo2 number

--- @class ICU
icu = {}

--- @type table<Player, StoredCommand[]>
icu.StoredCommands = {}



include("extensions.lua")
include("detours.lua")

if SERVER then
	AddCSLuaFile("cl_move.lua")

	include("sv_control.lua")
	include("sv_move.lua")
	include("pvs.lua")
elseif CLIENT then
	include("cl_move.lua")
end



--- @param Search string
--- @return Player
function icu.FindPlayer(Search)
	Search = string.Trim(Search)

	local Upper = string.upper(Search)
	local Lower = string.lower(Search)

	for _, Player in player.Iterator() do
		if Player:SteamID() == Upper then
			return Player
		end

		if Player:SteamID64() == Upper then
			return Player
		end

		local Nick = string.lower(Player:Nick())

		if string.find(Nick, Lower) then
			return Player
		end
	end

	return NULL
end

--- @param Target Player
function icu.RemoveTarget(Target)
	-- Make the Target stop existing

	if not Target:Alive() then
		Target:Spawn() -- So things make a bit of sense when you begin controlling someone who's dead
	end

	Target:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	Target:SetMoveType(MOVETYPE_NOCLIP)
	Target:GodEnable()
	Target:SetNoDraw(true)
end

--- @param Target Player
function icu.RestoreTarget(Target)
	Target:SetCollisionGroup(COLLISION_GROUP_NONE)
	Target:SetMoveType(MOVETYPE_WALK)
	Target:GodDisable()
	Target:SetNoDraw(false)

	Target:StripWeapons()
	Target:UnSpectate() -- Unused but doesn't hurt
	Target:Spawn()
end

--- @param Controller Player
--- @param Target Player
function icu.Start(Controller, Target)
	icu.Stop(Controller)

	if Target:IsICUTargeted() then
		Controller:PrintMessageFmt(HUD_PRINTTALK, "%s is already being controlled by %s", Target:Nick(), Target:GetICUController():Nick())
		return
	end

	if Target:IsICUControlling() then
		Controller:PrintMessageFmt(HUD_PRINTTALK, "%s is currently controlling %s", Target:Nick(), Target:GetICUTarget():Nick())
		return -- No controller-ception! (It'd probably work fine)
	end

	Target:SetICUController(Controller)
	icu.RemoveTarget(Target)

	Controller:SetICUTarget(Target)
	Controller:SetPos(Target:GetPos()) -- Go to
	Controller:SetEyeAngles(Target:EyeAngles())

	-- Make them look the same
	-- Except bodygroups, fuck that
	Controller:SetModel(Target:GetModel() --[[@as string]])
	Controller:SetSkin(Target:GetSkin())
	Controller:SetWeaponColor(Target:GetWeaponColor())
	Controller:SetPlayerColor(Target:GetPlayerColor())

	Controller:PrintMessageFmt(HUD_PRINTTALK, "Now controlling %s", Target:Nick())
end

--- @param Controller Player
function icu.Stop(Controller)
	local Target = Controller:GetICUTarget()

	if Target:IsValid() then
		Target:SetICUController(NULL)
		icu.RestoreTarget(Target)

		Target:SetPos(Controller:GetPos()) -- Keep them where they were after respawn
		Target:SetEyeAngles(Controller:EyeAngles())

		Controller:PrintMessageFmt(HUD_PRINTTALK, "No longer controlling %s", Target:Nick())
	end

	Controller:SetICUTarget(NULL)
	Controller:Spawn() -- The controller should probably go back to where they were when they started controlling

	-- In the Base and Sandbox gamemodes this will setup their
	-- model, skin, bodygroups and colors. If you're using this
	-- in a different gamemode, beware!
	player_manager.RunClass(Controller, "SetModel")
	player_manager.RunClass(Controller, "Spawn")
end

--- @param Controller Player
--- @param Command CUserCmd
function icu.StoreCommand(Controller, Command)
	local Store = icu.StoredCommands[Controller]

	if not istable(Store) then
		Store = {}
		icu.StoredCommands[Controller] = Store
	end

	-- I would really like to have an actual command replay system like the
	-- engine does....

	local Weapon = Controller:GetActiveWeapon()
	local HasWeapon = Weapon:IsValid()

	-- table.insert(Store, {
	-- 	ForwardMove = Command:GetForwardMove(),
	-- 	SideMove = Command:GetSideMove(),
	-- 	UpMove = Command:GetUpMove(),
	-- 	ViewAngles = Command:GetViewAngles(),
	-- 	Buttons = Command:GetButtons(),
	-- 	Impulse = Command:GetImpulse()
	-- } --[[@as StoredCommand]] )

	Store[1] = {
		ForwardMove = Command:GetForwardMove(),
		SideMove = Command:GetSideMove(),
		UpMove = Command:GetUpMove(),
		ViewAngles = Command:GetViewAngles(),
		Buttons = Command:GetButtons(),
		Impulse = Command:GetImpulse(),

		Weapon = HasWeapon and Weapon:GetClass() or "",
		Clip1 = HasWeapon and Weapon:Clip1() or 0,
		Clip2 = HasWeapon and Weapon:Clip2() or 0,
		Ammo1 = HasWeapon and Controller:GetAmmoCount(Weapon:GetPrimaryAmmoType()) or 0,
		Ammo2 = HasWeapon and Controller:GetAmmoCount(Weapon:GetSecondaryAmmoType()) or 0
	}
end

--- @param Target Player
--- @param Command CUserCmd
function icu.ApplyTargetCommand(Target, Command)
	local Controller = Target:GetICUController()

	if not Target:Alive() then
		icu.RemoveTarget(Target)
	end

	local Store = icu.StoredCommands[Controller]

	if not istable(Store) then
		return
	end

	local StoredCommand = table.remove(Store, 1) --[[@as StoredCommand]]

	if not StoredCommand then
		return
	end

	-- Command:SetForwardMove(StoredCommand.ForwardMove)
	-- Command:SetSideMove(StoredCommand.SideMove)
	-- Command:SetUpMove(StoredCommand.UpMove)
	-- Command:SetViewAngles(StoredCommand.ViewAngles)
	-- Command:SetButtons(StoredCommand.Buttons)
	-- Command:SetImpulse(StoredCommand.Impulse)

	Target:SetEyeAngles(StoredCommand.ViewAngles)
	Target:SetHealth(Controller:Health()) -- Death
	Target:SetArmor(Controller:Armor())

	local Weapon = Target:GetActiveWeapon()

	if not Weapon:IsValid() or StoredCommand.Weapon ~= Weapon:GetClass() then
		Target:StripWeapons()

		Weapon = Target:Give(StoredCommand.Weapon)
		Target:SelectWeapon(StoredCommand.Weapon)
	end

	if Weapon:IsValid() then
		Weapon:SetNoDraw(true)

		Weapon:SetClip1(StoredCommand.Clip1)
		Weapon:SetClip2(StoredCommand.Clip2)
		Target:SetAmmo(StoredCommand.Ammo1, Weapon:GetPrimaryAmmoType())
		Target:SetAmmo(StoredCommand.Ammo2, Weapon:GetSecondaryAmmoType())
	end
end
