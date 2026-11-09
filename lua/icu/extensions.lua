AddCSLuaFile()

--- @class Player
--- @field m_bICUAvoidPlayers boolean|nil
--- @field m_iICUFlags number|nil
--- @field m_iICUEFlags number|nil
--- @field m_iICUDebugOverlays number|nil
local _PLAYER = FindMetaTable("Player")

--- @param Type number
--- @param Message string
--- @param ... any
function _PLAYER:PrintMessageFmt(Type, Message, ...)
	local Formatted = string.format(Message, ...)
	Formatted = string.Trim(Formatted)

	self:PrintMessage(Type, Formatted)
end

--- @return Player
function _PLAYER:GetICUController()
	return self:GetNWEntity("ICU:Controller", NULL)
end

--- @return Player
function _PLAYER:GetICUTarget()
	return self:GetNWEntity("ICU:Target", NULL)
end

--- @param Controller Player
function _PLAYER:SetICUController(Controller)
	self:SetNWEntity("ICU:Controller", Controller)
end

--- @param Target Player
function _PLAYER:SetICUTarget(Target)
	self:SetNWEntity("ICU:Target", Target)
end

--- @return boolean
function _PLAYER:IsICUControlling()
	return self:GetICUTarget() ~= NULL
end

--- @return boolean
function _PLAYER:IsICUTargeted()
	return self:GetICUController() ~= NULL
end

--- @return number
function _PLAYER:GetDebugOverlays()
	return self:GetInternalVariable("m_debugoverlays")
end

--- @param Overlays number
function _PLAYER:SetDebugOverlays(Overlays)
	self:SetSaveValue("m_debugoverlays", Overlays)
end
