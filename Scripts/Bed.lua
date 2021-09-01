-- Bed.lua --

Bed = class( nil )

-- Client

function Bed.client_onInteract( self, character, state )
    if state == true then
        if self.shape.body:getWorld().id > 1 then
            sm.gui.displayAlertText( "#{INFO_HOME_NOT_STORED}" )
        else
            self:cl_seat()
        end
    end
end

function Bed.cl_seat( self )
    if sm.localPlayer.getPlayer() and sm.localPlayer.getPlayer():getCharacter() then
        self.interactable:setSeatCharacter( sm.localPlayer.getPlayer():getCharacter() )
    end
end

function Bed.client_onAction( self, controllerAction, state )
    local consumeAction = true
    if state == true then
        if controllerAction == sm.interactable.actions.use or controllerAction == sm.interactable.actions.jump then
            self:cl_seat()
        else
            consumeAction = false
        end
    else
        consumeAction = false
    end
    return consumeAction
end