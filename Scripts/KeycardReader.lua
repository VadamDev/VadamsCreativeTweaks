-- KeycardReader.lua --
dofile("$SURVIVAL_DATA/Scripts/game/survival_shapes.lua")

KeycardReader = class( nil )
KeycardReader.connectionInput = sm.interactable.connectionType.logic
KeycardReader.connectionOutput = sm.interactable.connectionType.logic
KeycardReader.maxParentCount = 1
KeycardReader.maxChildCount = 255

local KEYREADER_LOCKED = 1
local KEYREADER_ERROR = 2
local KEYREADER_OPEN = 3

--onCreate

function KeycardReader:server_onCreate()
	self.saved = self.storage:load()
	if self.saved == nil then
		self.saved = {
			unlocked = false
		}
	end
	
	self.storage:save( self.saved )
	self.interactable.active = self.saved.unlocked

	self.network:setClientData( self.saved )
end

function KeycardReader:client_onCreate()
	if self.cl == nil then
		self.cl = {}
	end
	self:client_onRefresh()
	if self.cl.unlocked == true then
		self:client_setReaderState( KEYREADER_OPEN )
	else
		self:client_setReaderState( KEYREADER_LOCKED )
	end
end

-- Server

function KeycardReader:server_onFixedUpdate( dt )
	local logicInteractable = self.interactable:getSingleParent()

	if self.saved.unlocked and logicInteractable and logicInteractable:isActive() then
		self.saved.unlocked = false
		self.storage:save( self.saved )
		self.network:setClientData( self.saved )
		self.network:sendToClients( "client_setReaderState", KEYREADER_LOCKED )
		self.interactable.active = false
	end
end

function KeycardReader:server_unlock()
	if not self.saved.unlocked then
		self.saved.unlocked = true
		self.storage:save( self.saved )
		self.network:setClientData( self.saved )
		self.network:sendToClients( "client_setReaderState", KEYREADER_OPEN )
		sm.effect.playEffect( "Elevator - Keycarduse", self.shape.worldPosition, nil, self.shape.worldRotation )
		self.interactable.active = true
	end
end

-- Client

function KeycardReader:client_onInteract( character, state )
	self.network:sendToServer( 'server_unlock' )
end

function KeycardReader:client_canInteract()
	if not self.cl.unlocked then
		local canUnlock
		local inventory = sm.localPlayer.getInventory()
		if sm.container.canSpend( inventory, obj_survivalobject_keycard, 1 ) then
			canUnlock = ( sm.localPlayer.getActiveItem() == obj_survivalobject_keycard )
		end

		local itemName = sm.shape.getShapeTitle( obj_survivalobject_keycard )
		if canUnlock then
			local keyBindingText =  sm.gui.getKeyBinding( "Use", true )
			sm.gui.setInteractionText( "", keyBindingText, "#{INTERACTION_PLACE} [" .. itemName .. "]" )
			return true
		else
			sm.gui.setInteractionText( "#{INFO_REQUIRES} [" .. itemName .. "]" )
			return false
		end
	end

	return false
end

function KeycardReader:client_onRefresh()
	self.client_updateElapsed = 0
	self.client_updateTime = 0.125
	self.client_stateCountdown = 0
	self.client_animationTime = 1.7
	self.client_animationElapsedTime = 0
	self.interactable:setAnimEnabled( "keycardreader_activate", true )

	if self.cl.unlocked == true then
		self:client_setReaderState( KEYREADER_OPEN )
	else
		self:client_setReaderState( KEYREADER_LOCKED )
	end
end

function KeycardReader:client_onUpdate( dt )
	if self.client_stateCountdown > 0 then
		self.client_stateCountdown = self.client_stateCountdown - dt
		if self.client_stateCountdown <= 0 then
			self.client_stateCountdown = 0
			if self.client_state == KEYREADER_ERROR then
				self:client_setReaderState( KEYREADER_LOCKED )
			end
		end
	end

	self.client_updateElapsed = self.client_updateElapsed + dt
	if self.client_updateElapsed >= self.client_updateTime then
		self.client_updateElapsed = self.client_updateElapsed - self.client_updateTime
		self.client_frame = self.client_frame + 1
		if self.client_frame > self.client_frameEnd then
			if self.client_looping then
				self.client_frame = self.client_frameStart
			else
				self.client_frame = self.client_frameEnd
			end
		end
		self.interactable:setUvFrameIndex( self.client_frame )
	end

	if self.cl.unlocked then
		self.client_animationElapsedTime = math.min( self.client_animationElapsedTime + dt, self.client_animationTime )
		self.interactable:setAnimProgress( "keycardreader_activate", self.client_animationElapsedTime / self.client_animationTime )
	else
		self.interactable:setAnimProgress( "keycardreader_activate", 1.0 )
	end

end

function KeycardReader:client_onClientDataUpdate( clientData )
	if self.cl == nil then
		self.cl = {}
	end

	self.cl.unlocked = clientData.unlocked

	if self.cl.unlocked == true then
		self:client_setReaderState( KEYREADER_OPEN )
	else
		self:client_setReaderState( KEYREADER_LOCKED )
	end
end

function KeycardReader:client_setReaderState( index )
	self.client_animationElapsedTime = 0

	if index == KEYREADER_LOCKED then
		self.client_frameStart = 0
		self.client_frameEnd = 3
		self.client_looping = true
		self.client_frame = self.client_frameStart
		self.client_state = index
	elseif index == KEYREADER_ERROR then
		self.client_frameStart = 12
		self.client_frameEnd = 15
		self.client_looping = false
		self.client_frame = self.client_frameStart
		self.client_state = index
		self.client_stateCountdown = 1.0
	elseif index == KEYREADER_OPEN then
		self.client_frameStart = 4 --9 checkmark
		self.client_frameEnd = 11
		self.client_looping = false
		self.client_frame = self.client_frameStart
		self.client_state = index
	end
end