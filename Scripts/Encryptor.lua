-- Author VadamDev --

Encryptor = class()
Encryptor.maxParentCount = 1
Encryptor.connectionInput = sm.interactable.connectionType.logic
Encryptor.colorNormal = sm.color.new( 0x777777ff )
Encryptor.colorHighlight = sm.color.new( 0x888888ff )

Encryptor.wasActive = false
Encryptor.interaction = true

-- Events --
function Encryptor.server_onFixedUpdate( self, timeStep )
    local parent = self.interactable:getSingleParent()
    self.active = parent and parent.active

	self:activate(self.active)
end

function Encryptor.client_onInteract(self)
	sm.gui.displayAlertText("Not work for the moment.\nYou can use switch for activate the encryption.")
end

function Encryptor.activate(self, active)
	local shapeType = self.data["type"]

	if active then
		if not self.wasActive then
			self:toggleAnimation(shapeType, active)
			self:toggleProtection(shapeType, active)

			self.wasActive = true
		end
	else
		if self.wasActive then
			self:toggleAnimation(shapeType, active)
			self:toggleProtection(shapeType, active)

			self.wasActive = false
		end
	end
end

-- Toggle Functions --

function Encryptor.toggleProtection(self, shapeType, state)
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

function Encryptor.toggleAnimation(self, shapeType, state)
	if state then
		if shapeType == "Encryptor" then
			sm.effect.playEffect("Encryptor - Activation", self.shape.worldPosition, nil, self.shape.worldRotation)
		elseif shapeType == "Protector" then
			sm.effect.playEffect("Barrier - Activation", self.shape.worldPosition, nil, self.shape.worldRotation)
		end
	else
		if shapeType == "Encryptor" then
			sm.effect.playEffect("Encryptor - Deactivation", self.shape.worldPosition, nil, self.shape.worldRotation)
		elseif shapeType == "Protector" then
			sm.effect.playEffect("Barrier - Deactivation", self.shape.worldPosition, nil, self.shape.worldRotation)
	    end
	end
end