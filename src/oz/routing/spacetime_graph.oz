% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Routing.SpaceTimeGraph
% Description: 4D time-expanded airfield reservation network, interval locking,
%              and dynamic occupancy table for conflict-free surface trajectory planning.
% =============================================================================

functor
export
   NewReservationTable: NewReservationTable
   IsIntervalFree: IsIntervalFree
   ReserveInterval: ReserveInterval
   ReleaseFlightReservations: ReleaseFlightReservations
   GetEdgeReservations: GetEdgeReservations
define

   % --------------------------------------------------------------------------
   % Reservation Record:
   % res(edgeId: Id flightId: String startTime: Float endTime: Float)
   % --------------------------------------------------------------------------

   fun {NewReservationTable}
      nil
   end

   % --------------------------------------------------------------------------
   % Overlap Check: Returns true if intervals [T1, T2] and [S1, S2] intersect
   % --------------------------------------------------------------------------
   fun {IntervalsOverlap T1 T2 S1 S2}
      (T1 < S2) andthen (T2 > S1)
   end

   % --------------------------------------------------------------------------
   % IsIntervalFree: Returns true if EdgeId has no conflicting reservations
   % in window [StartTime, EndTime]
   % --------------------------------------------------------------------------
   fun {IsIntervalFree Table EdgeId StartTime EndTime BufferSec}
      SafeStart = StartTime - BufferSec
      SafeEnd   = EndTime + BufferSec
      fun {CheckReservations List}
         case List
         of nil then true
         [] R | Rest then
            if R.edgeId == EdgeId andthen {IntervalsOverlap SafeStart SafeEnd R.startTime R.endTime} then
               false
            else
               {CheckReservations Rest}
            end
         end
      end
   in
      {CheckReservations Table}
   end

   % --------------------------------------------------------------------------
   % ReserveInterval: Adds a new space-time reservation to the table
   % --------------------------------------------------------------------------
   fun {ReserveInterval Table EdgeId FlightId StartTime EndTime}
      NewRes = res(edgeId: EdgeId
                   flightId: FlightId
                   startTime: StartTime
                   endTime: EndTime)
   in
      NewRes | Table
   end

   % --------------------------------------------------------------------------
   % ReleaseFlightReservations: Purges all reservations for a given flight
   % (e.g. upon departure or cancellation)
   % --------------------------------------------------------------------------
   fun {ReleaseFlightReservations Table FlightId}
      case Table
      of nil then nil
      [] R | Rest then
         if R.flightId == FlightId then
            {ReleaseFlightReservations Rest FlightId}
         else
            R | {ReleaseFlightReservations Rest FlightId}
         end
      end
   end

   % --------------------------------------------------------------------------
   % GetEdgeReservations: Returns all time reservations on a specific edge
   % --------------------------------------------------------------------------
   fun {GetEdgeReservations Table EdgeId}
      fun {Filter List}
         case List
         of nil then nil
         [] R | Rest then
            if R.edgeId == EdgeId then
               R | {Filter Rest}
            else
               {Filter Rest}
            end
         end
      end
   in
      {Filter Table}
   end

end
