HideoutVacuum = class( nil )

HideoutVacuum.connectionInput = sm.interactable.connectionType.logic
HideoutVacuum.maxParentCount = 1

function HideoutVacuum:client_onCreate()
	self.active = false
	self.vacuumTime = self.interactable:getAnimDuration( "dropoff_activate" )
	self.vacuumElapsed = 0.0
	self.interactable:setAnimEnabled( "dropoff_activate", true )
	self.vacuumEffect = sm.effect.createEffect( "Hideout - PumpSuction", self.shape.interactable, "suction3_jnt" )
end

-- Server

function HideoutVacuum:server_onFixedUpdate( dt )
	local logicInteractable = self.interactable:getSingleParent()

	if logicInteractable and logicInteractable:isActive() then
		self.network:sendToClients( "client_toggle" )
	end
end

-- Client

function HideoutVacuum:client_toggle()
	if not self.active then
		self.active = true
		self.vacuumEffect:start()
	end
end

function HideoutVacuum:client_onUpdate( dt )
	if self.vacuumElapsed >= self.vacuumTime then
		self.active = false
		self.vacuumElapsed = 0.0
		return
	end

	if self.active then
		self.vacuumElapsed = math.min( self.vacuumElapsed + dt, self.vacuumTime )
	else
		self.vacuumElapsed = 0.0
	end

	self.interactable:setAnimProgress( "dropoff_activate", self.vacuumElapsed / self.vacuumTime )
end
