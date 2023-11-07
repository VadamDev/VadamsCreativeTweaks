dofile("$MOD_DATA/Scripts/utils/UnitFinder.lua")

-- Author VadamDev --

Encryptor = class( nil )
Encryptor.connectionInput = sm.interactable.connectionType.logic
Encryptor.maxParentCount = 1
Encryptor.colorNormal = sm.color.new( 0x777777ff )
Encryptor.colorHighlight = sm.color.new( 0x888888ff )

function Encryptor:server_onCreate()
	self.wasActive = false

	self.saved = self.storage:load()
	if self.saved == nil then
		self.saved = {
			active = false,
			owner = nil
		}
	end

	self.storage:save( self.saved )
	self.network:setClientData( self.saved )

	self:server_applyProtection( self.data["type"], self.saved.active )
end

-- Server

function Encryptor:server_onFixedUpdate( dt )
	if self.saved.owner == nil then
		self.saved.owner = getPlayerById(getNearestPlayer(self.shape, 1, 512)):getName()
		self:server_saveAndSyncData()
	end

	local logicInteractable = self.interactable:getSingleParent()
	local parentActive = logicInteractable and logicInteractable:isActive()

	if parentActive and not self.wasActive then
		self.saved.active = true
		self:server_saveAndSyncData()

		self:server_toggle()

		self.wasActive = true
	elseif not parentActive and self.wasActive then
		self.saved.active = false
		self:server_saveAndSyncData()

		self:server_toggle()

		self.wasActive = false
	end
end

function Encryptor:server_toggle()
	local shapeType = self.data["type"]

	if self.saved.active then
		if shapeType == "Encryptor" then
			sm.effect.playEffect( "Encryptor - Activation", self.shape.worldPosition, nil, self.shape.worldRotation )
		elseif shapeType == "Protector" then
			sm.effect.playEffect( "Barrier - Activation", self.shape.worldPosition, nil, self.shape.worldRotation )
		end
	else
		if shapeType == "Encryptor" then
			sm.effect.playEffect( "Encryptor - Deactivation", self.shape.worldPosition, nil, self.shape.worldRotation )
		elseif shapeType == "Protector" then
			sm.effect.playEffect( "Barrier - Deactivation", self.shape.worldPosition, nil, self.shape.worldRotation )
	    end
	end

	self:server_applyProtection( shapeType, self.saved.active )
end

function Encryptor:server_applyProtection( shapeType, state )
	local body = self.shape:getBody()

	if shapeType == "Encryptor" then
		body.connectable = not state
	elseif shapeType == "Protector" then
		body.buildable = not state
		body.destructable = not state
		body.erasable = not state
		body.paintable = not state
		body.liftable = not state
	end
end

function Encryptor:server_saveAndSyncData()
	self.storage:save( self.saved )
	self.network:setClientData( self.saved )
end

function Encryptor:server_setActive( active )
	self.saved.active = active
	self.wasActive = not active
	self:server_saveAndSyncData()
end

-- Client

function Encryptor:client_onInteract( character, state )
	if state then
		self.network:sendToServer("server_setActive", not self.saved.active)
		self.network:sendToServer("server_toggle")
	end
end

function Encryptor:client_canInteract( char )
	sm.gui.setInteractionText("<p textShadow='false' bg='gui_keybinds_bg_orange' color='#66440C' spacing='9'>".. (self.saved.active and "ONLINE" or "OFFLINE") .."</p>", " | ", "<p textShadow='false' bg='gui_keybinds_bg_orange' color='#66440C' spacing='9'>"..(self.saved.owner == nil and "Unknow" or self.saved.owner).."</p>")
	return self.interactable:getSingleParent() == nil and (self.saved.owner == nil and true or char:getPlayer():getName() == self.saved.owner)
end