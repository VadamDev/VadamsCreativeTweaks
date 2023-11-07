Gun = class()
Gun.maxParentCount = 1
Gun.connectionInput = sm.interactable.connectionType.logic
Gun.colorNormal = sm.color.new( 0xcb0a00ff )
Gun.colorHighlight = sm.color.new( 0xee0a00ff )
Gun.poseWeightCount = 1

Gun.fireDelay = 8 --ticks
Gun.minForce = 0
Gun.maxForce = 0
Gun.spreadDeg = 1.0


--[[ Server ]]

-- (Event) Called upon creation on server
function Gun.server_onCreate( self )
	self:server_init()
end

-- (Event) Called when script is refreshed (in [-dev])
function Gun.server_onRefresh( self )
	self:server_init()
end

-- Initialize mounted gun
function Gun.server_init( self )
	self.fireDelayProgress = 0
	self.canFire = true
	self.parentActive = false

    self.minForce = self.data["minForce"]
	self.maxForce = self.data["maxForce"]
end

-- (Event) Called upon game tick. (40 times a second)
function Gun.server_onFixedUpdate( self, timeStep )
	if not self.canFire then
		self.fireDelayProgress = self.fireDelayProgress + 1
		if self.fireDelayProgress >= self.fireDelay then
			self.fireDelayProgress = 0
			self.canFire = true
		end
	end
	self:server_tryFire()
	local parent = self.interactable:getSingleParent()
	if parent then
		self.parentActive = parent:isActive()
	end
end

-- Attempt to fire a projectile
function Gun.server_tryFire( self )
	local parent = self.interactable:getSingleParent()
	if parent then
		if parent:isActive() and not self.parentActive and self.canFire then
			self.canFire = false
			local firePos = sm.vec3.new( 0.0, 0.0, 0.375 )
			local fireForce = math.random( self.minForce, self.maxForce )

			-- Add random spread
			local dir = sm.noise.gunSpread( sm.vec3.new( 0.0, 0.0, 1.0 ), self.spreadDeg )

			-- Fire projectile from the shape
			sm.projectile.shapeFire( self.shape, self.data["projectile"], firePos, dir * fireForce )

			self.network:sendToClients( "client_onShoot" )
			local mass = sm.projectile.getProjectileMass( self.data["projectile"] )
			local impulse = dir * -fireForce * mass
			sm.physics.applyImpulse( self.shape, impulse )
		end
	end
end


--[[ Client ]]

-- (Event) Called upon creation on client
function Gun.client_onCreate( self )
	self.boltValue = 0.0
	self.shootEffect = sm.effect.createEffect( self.data["effect"], self.interactable )
end

-- (Event) Called upon every frame. (Same as fps)
function Gun.client_onUpdate( self, dt )
	if self.boltValue > 0.0 then
		self.boltValue = self.boltValue - dt * 10
	end
	if self.boltValue ~= self.prevBoltValue then
		self.interactable:setPoseWeight( 0, self.boltValue ) --Clamping inside
		self.prevBoltValue = self.boltValue
	end
end

-- Called from server upon the gun shooting
function Gun.client_onShoot( self )
	self.boltValue = 1.0
	local rot = sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), self.shape.up )
	self.shootEffect:start()
end
