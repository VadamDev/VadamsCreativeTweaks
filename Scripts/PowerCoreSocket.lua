-- PowerCoreSocket.lua --
dofile("$SURVIVAL_DATA/Scripts/game/survival_shapes.lua")

PowerCoreSocket = class( nil )
PowerCoreSocket.connectionInput = sm.interactable.connectionType.logic
PowerCoreSocket.connectionOutput = sm.interactable.connectionType.logic
PowerCoreSocket.maxParentCount = 1
PowerCoreSocket.maxChildCount = 255
PowerCoreSocket.colorNormal = sm.color.new( 0xdeadbeef )
PowerCoreSocket.colorHighlight = sm.color.new( 0xdeadbeef )
PowerCoreSocket.poseWeightCount = 1

-- Server

function PowerCoreSocket:server_onCreate()
	self.sv = {}
	self.sv.saved = self.storage:load()
	
	if self.sv.saved == nil then
		self.sv.saved = {
			active = false
		}
		
		self.interactable.active = false
	else
		self.interactable.active = self.sv.saved.active
	end
	
	self.storage:save( self.sv.saved )
end

function PowerCoreSocket:client_onCreate()
	self.interactable:setPoseWeight( 0, self.interactable.active and 1 or 0 )
end

-- Server

function PowerCoreSocket:server_onFixedUpdate( dt )
	local logicInteractable = self.interactable:getSingleParent()

	if self.interactable.active and logicInteractable and logicInteractable:isActive() then
		self.sv.saved.active = false
		self.interactable.active = false
		self.storage:save( self.sv.saved )
	end
end

function PowerCoreSocket:server_unlock()
	if not self.interactable.active then
		self.sv.saved.active = true
		self.interactable.active = true
		self.storage:save( self.sv.saved )
		sm.effect.playEffect( "PowerSocket - Activate", self.shape.worldPosition, nil, self.shape.worldRotation )
	end
end


-- Client

function PowerCoreSocket:client_onInteract( character, state )
	self.network:sendToServer( 'server_unlock' )
end

function PowerCoreSocket:client_canInteract()
	if not self.interactable.active then
		local canUnlock
		local inventory = sm.localPlayer.getInventory()
		if sm.container.canSpend( inventory, obj_survivalobject_powercore, 1 ) then
			canUnlock = ( sm.localPlayer.getActiveItem() == obj_survivalobject_powercore )
		end
		
		local itemName = sm.shape.getShapeTitle( obj_survivalobject_powercore )
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

function PowerCoreSocket:client_onUpdate( dt )
	self.interactable:setPoseWeight( 0, self.interactable.active and 1 or 0 )

	if self.interactable.active then
		self.interactable:setGlowMultiplier( 1.0 )
	else
		self.time = self.time and self.time + dt or 0
		self.interactable:setGlowMultiplier( math.sin( self.time * math.pi ) * 0.25 + 0.5 )
	end
end
