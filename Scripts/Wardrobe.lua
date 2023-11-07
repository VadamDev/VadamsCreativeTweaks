-- Wardrobe.lua --
dofile( "$SURVIVAL_DATA/Scripts/util.lua" )
dofile "$SURVIVAL_DATA/Scripts/game/survival_constants.lua"

Wardrobe = class( nil )

local OpenShutterDistance = 4.0
local CloseShutterDistance = 6.0

-- Client

function Wardrobe.client_onCreate( self )
	self:cl_init()
end

function Wardrobe.client_onRefresh( self )
	if self.cl then
		if self.cl.user then
			local player = sm.localPlayer.getPlayer()
			player.clientPublicData.interactableCameraData = nil
			self.cl.user:setLockingInteractable( nil )
		end
	end
	
	self.cl.guiCustomizationInterface:close()
	self:cl_init()
end

function Wardrobe.cl_init( self ) 
	self.cl = {}
	self.cl.pullback = 1
	self.cl.pullbackSeated = 1
	self.cl.cameraDirection = sm.vec3.new( 0, 1, 0 )
	self.cl.cameraHeading = 0
	self.cl.cameraDesiredHeading = self.cl.cameraHeading
	self.cl.cameraPitch = 0
	self.cl.cameraDesiredPitch = self.cl.cameraPitch
	self.cl.cameraPosition = self.shape.worldPosition - self.cl.cameraDirection
	self.cl.input = sm.vec3.new( 0, 0, 0 )
	self.cl.cameraPullback = 4
	self.cl.desiredCameraPullback = self.cl.cameraPullback
	
	self.cl.guiCustomizationInterface = sm.gui.createCharacterCustomizationGui()
	self.cl.guiCustomizationInterface:setOnCloseCallback( "cl_onClose" )

	-- Setup animations
	local animations = {}
	animations["Unfold"] = self:cl_createAnimation( "Unfold", true )
	animations["Idle"] = self:cl_createAnimation( "Idle", true )

	self.cl.animations = animations
	self:cl_setAnimation( self.cl.animations["Unfold"], 0.0 )

	self.cl.doorAnimation = self:cl_createAnimation( "Control_doors", true )
	self.cl.doorAnimation.isActive = true

	-- Setup effects
	self.cl.idleEffect = sm.effect.createEffect( "Dressbot - Idle", self.interactable )
	self.cl.doorEffect = sm.effect.createEffect( "Dressbot - Opendoors", self.interactable)
end

function Wardrobe.client_canInteract( self )
	local interactRange = 7.5
	local success, result = sm.localPlayer.getRaycast(interactRange)
	
	local outputPosition = sm.shape.getWorldPosition(self.shape) + self.shape.right * -1.85  + self.shape.up * 0.5 + self.shape.at * -0.5
	local outputDistance = (result.pointWorld - outputPosition):length()
	local outputSphereRadius = 2.0
	local outputWeightedValue = outputDistance / outputSphereRadius
	
	local keyBindingText =  sm.gui.getKeyBinding( "Use", true )
	
	if outputWeightedValue > 1.0 then
		sm.gui.setInteractionText( "", keyBindingText, "#{INTERACTION_USE_WARDROBE}" )
		return true
	end
	
	return false
end

function Wardrobe.client_onInteract( self, character, state ) 
	if state == true then
		local interactRange = 7.5
		local success, result = sm.localPlayer.getRaycast(interactRange)
		
		local outputPosition = sm.shape.getWorldPosition(self.shape) + self.shape.right * -1.85  + self.shape.up * 0.5 + self.shape.at * -0.5
		local outputDistance = (result.pointWorld - outputPosition):length()
		local outputSphereRadius = 2.0
		local outputWeightedValue = outputDistance / outputSphereRadius
		
		if outputWeightedValue > 1.0 then
			self:cl_openCustomization( character )
		end
	end
end

function Wardrobe.cl_onClose( self )
	if self.cl.user then
		local player = self.cl.user:getPlayer()
		player.clientPublicData.interactableCameraData = nil
		self.cl.user:setLockingInteractable( nil )
		self.cl.user = nil
		self.cl.input = sm.vec3.new( 0, 0, 0 )
		self.cl.cameraDirection = sm.vec3.new( 0, 1, 0 )
		self.cl.cameraPosition = self.shape.worldPosition - self.cl.cameraDirection
		self.cl.cameraHeading = 0
		self.cl.cameraDesiredHeading = self.cl.cameraHeading
		self.cl.cameraPitch = 0
		self.cl.cameraDesiredPitch = self.cl.cameraPitch
	end
end

function Wardrobe.client_onAction( self, controllerAction, state )
	if state == true then
		if controllerAction == sm.interactable.actions.zoomIn then
			self.cl.desiredCameraPullback = math.max( self.cl.desiredCameraPullback - 1, 1 )
		elseif controllerAction == sm.interactable.actions.zoomOut then
			self.cl.desiredCameraPullback = math.min( self.cl.desiredCameraPullback + 1, 10 )
		elseif controllerAction == sm.interactable.actions.left then
			self.cl.input.x = -1
		elseif controllerAction == sm.interactable.actions.right then
			self.cl.input.x = 1
		elseif controllerAction == sm.interactable.actions.forward then
			self.cl.input.y = 1
		elseif controllerAction == sm.interactable.actions.backward then
			self.cl.input.y = -1
		else
			return false
		end
	else		
		if controllerAction == sm.interactable.actions.left then
			self.cl.input.x = 0
		elseif controllerAction == sm.interactable.actions.right then
			self.cl.input.x = 0
		elseif controllerAction == sm.interactable.actions.forward then
			self.cl.input.y = 0
		elseif controllerAction == sm.interactable.actions.backward then
			self.cl.input.y = 0
		else
			return false
		end
	end
	return true
end

function Wardrobe.client_onUpdate( self, dt )

	self:cl_selectAnimation()
	self:cl_updateAnimations( dt )

	local character = sm.localPlayer.getPlayer().character
	if self.cl.user and self.cl.user == character then
	
		local epsilon = 0.000244140625
		--local mouseSpeed = 1.0
		local mouseSpeed = 12.0
		local relX = self.cl.input.x * mouseSpeed * math.pi * 0.001
		local relY = self.cl.input.y * mouseSpeed * math.pi * 0.001
		self.cl.cameraDesiredPitch = self.cl.cameraDesiredPitch - relY
		self.cl.cameraDesiredHeading = self.cl.cameraDesiredHeading + relX
		
		-- Avoid pitching beyond straight up and straight down
		if self.cl.cameraDesiredPitch > math.pi * 0.5 - epsilon then
			self.cl.cameraDesiredPitch = math.pi * 0.5 - epsilon
		end
		if self.cl.cameraDesiredPitch < -math.pi * 0.5 + epsilon then
			self.cl.cameraDesiredPitch = -math.pi * 0.5 + epsilon
		end
		
		-- Keep heading within 0 and 2*pi
		while self.cl.cameraDesiredHeading > math.pi * 2 do
			self.cl.cameraDesiredHeading = self.cl.cameraDesiredHeading - math.pi * 2
			self.cl.cameraHeading = self.cl.cameraHeading - math.pi * 2
		end
		while self.cl.cameraDesiredHeading < 0 do
			self.cl.cameraDesiredHeading = self.cl.cameraDesiredHeading + math.pi * 2
			self.cl.cameraHeading = self.cl.cameraHeading + math.pi * 2
		end
		
		-- Smooth heading and pitch movement
		local cameraLerpSpeed = 1.0 / 6.0
		local blend = 1 - math.pow( 1 - cameraLerpSpeed, dt * 60 )
		self.cl.cameraHeading = sm.util.lerp( self.cl.cameraHeading, self.cl.cameraDesiredHeading, blend )
		self.cl.cameraPitch = sm.util.lerp( self.cl.cameraPitch, self.cl.cameraDesiredPitch, blend )
		self.cl.cameraDirection = sm.vec3.new( 0, 1, 0 )
		self.cl.cameraDirection = self.cl.cameraDirection:rotateX( self.cl.cameraPitch )
		self.cl.cameraDirection = self.cl.cameraDirection:rotateZ( self.cl.cameraHeading )
		
		-- Smooth pullback
		local pullbackSteps = 0.5
		self.cl.cameraPullback = sm.util.lerp( self.cl.cameraPullback, self.cl.desiredCameraPullback, blend )
		
		-- Adjust sideways camera offset based on FOV settings
		local fovScale = ( sm.camera.getFov() - 45 ) / 45
		local cameraOffset45 = 0.5
		local cameraOffset90 = 1.0
		local left = sm.vec3.new( 0, 0, 1 ):cross( self.cl.cameraDirection )
		left.z = 0.0
		if left:length() >= FLT_EPSILON then
			left = left:normalize()
		end
		local cameraOffset = left * lerp( cameraOffset45, cameraOffset90, fovScale )
		
		-- Adjust camera position if the view is blocked
		local fraction = sm.camera.cameraSphereCast( 0.2, character.worldPosition + cameraOffset, -self.cl.cameraDirection * self.cl.cameraPullback * pullbackSteps )
		self.cl.cameraPosition = character.worldPosition + cameraOffset - self.cl.cameraDirection * self.cl.cameraPullback * pullbackSteps * fraction
		
		-- Finalize
		local interactableCameraData = {}
		interactableCameraData.hideGui = false
		interactableCameraData.cameraState = sm.camera.state.cutsceneTP
		interactableCameraData.cameraPosition = self.cl.cameraPosition
		interactableCameraData.cameraDirection = self.cl.cameraDirection
		interactableCameraData.cameraFov = sm.camera.getDefaultFov()
		interactableCameraData.lockedControls = false
		self.cl.user:getPlayer().clientPublicData.interactableCameraData = interactableCameraData
	end
end

function Wardrobe.cl_openCustomization( self, character )
	if self.cl.user == nil then
		character:setLockingInteractable( self.interactable )
		self.cl.user = character
		--audio event
		
		self.cl.guiCustomizationInterface:open()
		
		self.cl.cameraDirection = -character:getDirection()
		local direction = sm.vec3.new( self.cl.cameraDirection.x, self.cl.cameraDirection.y, 0 )
		if direction:length() >= FLT_EPSILON then
			self.cl.cameraDirection = direction:normalize()
		end
		self.cl.cameraPosition = character.worldPosition - self.cl.cameraDirection * self.cl.cameraPullback
		self.cl.cameraDesiredHeading = math.atan2( -self.cl.cameraDirection.x, self.cl.cameraDirection.y )
		self.cl.cameraHeading = self.cl.cameraDesiredHeading
		self.cl.cameraDesiredPitch = math.asin( self.cl.cameraDirection.z )
		self.cl.cameraPitch = self.cl.cameraDesiredPitch
	end
end

-- Animations
function Wardrobe.cl_createAnimation( self, name, playForward )
	local animation =
	{
		-- Required
		name = name,
		playProgress = 0.0,
		playTime = self.interactable:getAnimDuration( name ),
		isActive = false,
		-- Optional
		playForward = ( playForward or playForward == nil )
	}
	return animation
end

function Wardrobe.cl_setAnimation( self, animation, playProgress )
	self:cl_unsetAnimation()
	animation.isActive = true
	animation.playProgress = playProgress
	self.interactable:setAnimEnabled(animation.name, true)
end

function Wardrobe.cl_unsetAnimation( self )
	for name, animation in pairs( self.cl.animations ) do
		animation.isActive = false
		animation.playProgress = 0.0
		self.interactable:setAnimEnabled( animation.name, false )
		self.interactable:setAnimProgress( animation.name, animation.playProgress )
	end
end

function Wardrobe.cl_selectAnimation( self )

	-- Open/Close shutter
	if self.cl.doorAnimation.isActive then
		if math.abs( self.cl.doorAnimation.playProgress ) >= 1.0 then
			if GetClosestPlayer( self.shape.worldPosition, OpenShutterDistance, self.shape.body:getWorld() ) ~= nil then
				if self.cl.doorAnimation.playForward == false then
					self.cl.doorEffect:start()
				end
				self.cl.doorAnimation.playForward = true
			elseif GetClosestPlayer( self.shape.worldPosition, CloseShutterDistance, self.shape.body:getWorld() ) == nil then
				if self.cl.doorAnimation.playForward == true then
					self.cl.doorEffect:start()
				end
				self.cl.doorAnimation.playForward = false
			end
		end
	end

	-- Idle
	if self.cl.animations["Unfold"].isActive and self.cl.animations["Unfold"].playProgress >= 1.0 then
		self:cl_setAnimation( self.cl.animations["Idle"], 0.0 )
		self.cl.idleEffect:start()
	elseif self.cl.animations["Idle"].isActive and self.cl.animations["Idle"].playProgress >= 1.0 then
		self:cl_setAnimation( self.cl.animations["Idle"], ( self.cl.animations["Idle"].playProgress - 1.0 ) * self.cl.animations["Idle"].playTime )
		self.cl.idleEffect:start()
	end
end

function Wardrobe.cl_updateAnimations( self, dt )
	for name, animation in pairs( self.cl.animations ) do
		self:cl_updateAnimation( animation, dt )
	end
	self:cl_updateAnimation( self.cl.doorAnimation, dt )
end

function Wardrobe.cl_updateAnimation( self, animation, dt )
	if animation.isActive then
		self.interactable:setAnimEnabled( animation.name, true )
		if animation.playForward then
			animation.playProgress = animation.playProgress + dt / animation.playTime
			if animation.playProgress > 1.0 then
				animation.playProgress = 1.0
			end
			self.interactable:setAnimProgress( animation.name, animation.playProgress )
		else
			animation.playProgress = animation.playProgress - dt / animation.playTime
			if animation.playProgress < -1.0 then
				animation.playProgress = -1.0
			end
			self.interactable:setAnimProgress(animation.name, 1.0 + animation.playProgress )
		end
	end
end