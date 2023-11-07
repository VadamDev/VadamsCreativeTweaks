-- HideoutTrader.lua --
dofile( "$SURVIVAL_DATA/Scripts/util.lua" )

HideoutTrader = class( nil )

local OpenShutterDistance = 7.0
local CloseShutterDistance = 9.0

-- Client

function HideoutTrader:client_onCreate()
	self:cl_init()
end

function HideoutTrader:client_onRefresh()
	self:cl_init()
end

function HideoutTrader:cl_init()
	if self.cl == nil then
		self.cl = {}
	end

	-- Setup animations
	self.cl.animationEffects = {}
	local animations = {}
	if self.data and self.data.animationList then
		for i, animation in ipairs( self.data.animationList ) do
			local duration = self.interactable:getAnimDuration( animation.name )
			animations[animation.name] = self:cl_createAnimation( animation.name, duration, animation.nextAnimation, animation.looping, animation.playForward )
			if animation.effect then
				self.cl.animationEffects[animation.name] = sm.effect.createEffect( animation.effect.name, self.interactable, animation.effect.joint )
			end
		end
	end
	self.cl.animations = animations
	self:cl_setAnimation( self.cl.animations["Close"], 1.0 )
end

function HideoutTrader:client_onDestroy()
	-- Destroy animation effects
	for name, effect in pairs( self.cl.animationEffects ) do
		effect:stop()
	end
end

function HideoutTrader:client_onUpdate( dt )
	self:cl_selectAnimation()
	self:cl_updateAnimation( dt )
end

function HideoutTrader:cl_createAnimation( name, playTime, nextAnimation, looping, playForward )
	local animation =
	{
		-- Required
		name = name,
		playProgress = 0.0,
		playTime = playTime,
		isActive = false,
		-- Optional
		looping = looping,
		playForward = ( playForward or playForward == nil ),
		nextAnimation = nextAnimation
	}
	return animation
end

function HideoutTrader:cl_setAnimation( animation, playProgress )
	self:cl_unsetAnimation()
	animation.isActive = true
	animation.playProgress = playProgress
	self.interactable:setAnimEnabled(animation.name, true)
	local effect = self.cl.animationEffects[animation.name]
	if playProgress == 0.0 and effect then
		effect:start()
	end
end

function HideoutTrader:cl_unsetAnimation()
	for name, animation in pairs( self.cl.animations ) do
		animation.isActive = false
		animation.playProgress = 0.0
		self.interactable:setAnimEnabled( animation.name, false )
		self.interactable:setAnimProgress( animation.name, animation.playProgress )
	end
end

function HideoutTrader:cl_selectAnimation()
	if self.cl.animations["Close"].isActive and self.cl.animations["Close"].playProgress >= 1.0 and GetClosestPlayer( self.shape.worldPosition, OpenShutterDistance, self.shape.body:getWorld() ) ~= nil then
		self:cl_setAnimation( self.cl.animations["Open"], 0.0 )
	end

	if self.cl.animations["Idle"].isActive and GetClosestPlayer( self.shape.worldPosition, CloseShutterDistance, self.shape.body:getWorld() ) == nil then
		self:cl_setAnimation( self.cl.animations["Close"], 0.0 )
	end
end

function HideoutTrader:cl_updateAnimation( dt )
	for name, animation in pairs( self.cl.animations ) do
		if animation.isActive then
			self.interactable:setAnimEnabled(animation.name, true)
			if animation.playForward then
				animation.playProgress = animation.playProgress + dt / animation.playTime
				if animation.playProgress > 1.0 then
					if animation.looping then
						animation.playProgress = animation.playProgress - 1.0
					else
						if animation.nextAnimation then
							self:cl_setAnimation( self.cl.animations[animation.nextAnimation], 0.0)
							return
						else
							animation.playProgress = 1.0
						end
					end
				end
				self.interactable:setAnimProgress(animation.name, animation.playProgress )
			else
				animation.playProgress = animation.playProgress - dt / animation.playTime
				if animation.playProgress < -1.0 then
					if animation.looping then
						animation.playProgress = animation.playProgress + 1.0
					else
						if animation.nextAnimation then
							self:cl_setAnimation( self.cl.animations[animation.nextAnimation], 0.0)
							return
						else
							animation.playProgress = -1.0
						end
					end
				end
				self.interactable:setAnimProgress(animation.name, 1.0 + animation.playProgress )
			end
		end
	end

end
