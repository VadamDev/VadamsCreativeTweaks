-- Author VadamDev --

function getNearestUnit(shape, unitUUID, minRange, maxRange)
	local position = shape:getWorldPosition()

	local units = {}

	for k, unit in pairs(sm.unit.getAllUnits()) do
		local distance = (position - unit.character.worldPosition):length()

		if distance >= minRange and distance < maxRange and unit.character:getCharacterType() == unitUUID then
			table.insert(units, unit)
		end
	end

	local sortedUnits = units
	for i = 1, #units do
		for j = 1, #units do
			local unit1 = sortedUnits[i]
			local unit2 = sortedUnits[j]

			if (position - unit1.character.worldPosition):length() > (position - unit2.character.worldPosition):length() then
				sortedUnits[i] = unit1
				sortedUnits[j] = unit2
			end
		end
	end

	if #sortedUnits == 0 then
		return nil
	end

	return sortedUnits[1].id
end

function getUnitById(id)
	for k, unit in pairs(sm.unit.getAllUnits()) do
		if unit.id == id then
			return unit
		end
	end

	return nil
end

function getNearestPlayer(shape, minRange, maxRange)
	local position = shape:getWorldPosition()

	local players = {}

	for k, player in pairs(sm.player.getAllPlayers()) do
		local distance = (position - player.character.worldPosition):length()

		if distance >= minRange and distance < maxRange then
			table.insert(players, player)
		end
	end

	local sortedPlayers = players
	for i = 1, #players do
		for j = 1, #players do
			local player1 = sortedPlayers[i]
			local player2 = sortedPlayers[j]

			if (position - player1.character.worldPosition):length() > (position - player2.character.worldPosition):length() then
				sortedPlayers[i] = player1
				sortedPlayers[j] = player2
			end
		end
	end

	if #sortedPlayers == 0 then
		return nil
	end

	return sortedPlayers[1].id
end

function getPlayerById(id)
	for k, player in pairs(sm.player.getAllPlayers()) do
		if player.id == id then
			return player
		end
	end

	return nil
end