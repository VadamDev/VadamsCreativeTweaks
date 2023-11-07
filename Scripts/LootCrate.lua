LootCrate = class( nil )

function LootCrate:server_onProjectile( position, airTime, velocity, projectileName, shooter, damage, customData, normal, uuid )
	self:server_onHit()
end

function LootCrate:server_onMelee( position, attacker, damage, power, direction, normal )
	self:server_onHit( direction * 5 )
end

function LootCrate:server_onExplosion( center, destructionLevel )
	self:server_onHit()
end

function LootCrate:server_onHit( velocity )
	if self.data.destroyEffect then
		sm.effect.playEffect( self.data.destroyEffect, self.shape.worldPosition, nil, self.shape.worldRotation, nil, { startVelocity = velocity } )
	end
	
	if self.data.staticDestroyEffect then
		sm.effect.playEffect( self.data.staticDestroyEffect, self.shape.worldPosition, nil, self.shape.worldRotation )
	end

	self.shape:destroyShape()
end