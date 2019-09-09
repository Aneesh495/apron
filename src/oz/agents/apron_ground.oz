% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Agents.ApronGround
% Description: Active Apron Ground Controller agent arbitrating pushback requests,
%              taxilane clearances, and ground movement coordination.
% =============================================================================

functor
import
   System
   PushbackMatrix at '../routing/pushback_matrix.oz'
export
   SpawnApronGroundController: SpawnApronGroundController
define

   fun {SpawnApronGroundController ApronZoneId BlockingMatrix}
      local InStream Port in
         Port = {NewPort InStream}
         thread
            proc {EventLoop Stream ActivePushes ActiveTaxis}
               case Stream
               of nil then skip

               [] msg_request_pushback(flightId: F standId: S tobt: _ ack: Ack) | Rest then
                  % Check if any currently pushing aircraft blocks stand S
                  fun {IsBlocked ActiveList}
                     case ActiveList
                     of nil then false
                     [] pair(_ ActiveStand) | Ar then
                        if {PushbackMatrix.AreStandsMutuallyExclusive S ActiveStand BlockingMatrix} then
                           true
                        else
                           {IsBlocked Ar}
                        end
                     end
                  end
               in
                  if {IsBlocked ActivePushes} then
                     Ack = hold_position(stand: S reason: culdesac_blocked)
                     {EventLoop Rest ActivePushes ActiveTaxis}
                  else
                     Ack = pushback_cleared(stand: S facing: east)
                     NewPushes = pair(F S) | ActivePushes
                  in
                     {EventLoop Rest NewPushes ActiveTaxis}
                  end

               [] msg_report_vacated(flightId: F runwayId: _ exitNode: _) | Rest then
                  fun {RemoveFlight List}
                     case List
                     of nil then nil
                     [] pair(Fl St) | Ar then
                        if Fl == F then Ar else pair(Fl St) | {RemoveFlight Ar} end
                     end
                  end
               in
                  {EventLoop Rest {RemoveFlight ActivePushes} ActiveTaxis}

               [] msg_disconnect_tug(flightId: F tugId: _) | Rest then
                  fun {RemoveFlight List}
                     case List
                     of nil then nil
                     [] pair(Fl St) | Ar then
                        if Fl == F then Ar else pair(Fl St) | {RemoveFlight Ar} end
                     end
                  end
               in
                  {EventLoop Rest {RemoveFlight ActivePushes} ActiveTaxis}
               end
            end
         in
            {EventLoop InStream nil nil}
         end
         apron_agent(port: Port zoneId: ApronZoneId)
      end
   end

end
