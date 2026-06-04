AddCSLuaFile()

--- @class Player
local _PLAYER = FindMetaTable("Player")

--- @diagnostic disable: deprecated, lowercase-global
_PLAYER._ofnName = _PLAYER._ofnName or _PLAYER.Name
_PLAYER._ofnGetName = _PLAYER._ofnGetName or _PLAYER.GetName
_PLAYER._ofnNick = _PLAYER._ofnNick or _PLAYER.Nick

function _PLAYER:Name()
	return self._ofnName(self:IsICUControlling() and self:GetICUTarget() or self)
end

function _PLAYER:GetName()
	return self._ofnGetName(self:IsICUControlling() and self:GetICUTarget() or self)
end

function _PLAYER:Nick()
	return self._ofnNick(self:IsICUControlling() and self:GetICUTarget() or self)
end

if CLIENT then
	_PLAYER._ofnSteamID = _PLAYER._ofnSteamID or _PLAYER.SteamID
	_PLAYER._ofnSteamID64 = _PLAYER._ofnSteamID64 or _PLAYER.SteamID64

	function _PLAYER:SteamID() -- Detouring these serverside would be bad news...
		return self._ofnSteamID(self:IsICUControlling() and self:GetICUTarget() or self)
	end

	function _PLAYER:SteamID64()
		return self._ofnSteamID64(self:IsICUControlling() and self:GetICUTarget() or self)
	end

	player._ofnGetAll = player._ofnGetAll or player.GetAll
	player._ofnIterator = player._ofnIterator or player.Iterator

	--- @return Player[]
	function player.GetAll()
		local Players = player._ofnGetAll()
		local Count = #Players

		for i = Count, 1, -1 do
			if Players[i]:IsICUControlling() then
				table.remove(Players, i)
			end
		end

		return Players
	end

	local _, PlayerCache = debug.getupvalue(player._ofnIterator, 1)
	local inext = ipairs({})

	--- @return function, Player[], number
	function player.Iterator()
		PlayerCache = player.GetAll() -- This owns performance sadly

		local Cache = PlayerCache -- table.Copy(PlayerCache)
		local Count = #Cache

		for i = Count, 1, -1 do
			if Cache[i]:IsICUControlling() then
				table.remove(Cache, i)
			end
		end

		return inext, Cache, 0
	end

	-- Force the scoreboard to always update because I can't be fucked
	--- @class GM
	local GAMEMODE = gmod.GetGamemode()

	g_Scoreboard = g_Scoreboard --[[@as Panel|nil]]

	--- @param self GM
	local function ScoreboardShow(self)
		if IsValid(g_Scoreboard) then
			g_Scoreboard:Remove()
		end

		if isfunction(self._ofnScoreboardShow) then
			self:_ofnScoreboardShow()
		end
	end

	if not GAMEMODE then
		hook.Add("PostGamemodeLoaded", "iControlU", function()
			GAMEMODE = gmod.GetGamemode()

			GAMEMODE._ofnScoreboardShow = GAMEMODE._ofnScoreboardShow or GAMEMODE.ScoreboardShow
			GAMEMODE.ScoreboardShow = ScoreboardShow
		end)
	else
		GAMEMODE._ofnScoreboardShow = GAMEMODE._ofnScoreboardShow or GAMEMODE.ScoreboardShow
		GAMEMODE.ScoreboardShow = ScoreboardShow
	end
end

--- @diagnostic enable: deprecated, lowercase-global
