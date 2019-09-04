% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Agents.MessageTypes
% Description: Protocol definitions for asynchronous port communication between
%              active agents (Tower, Apron Control, Stand Manager, Flight Crew, Tug).
% =============================================================================

functor
export
   % Message Constructors
   MsgRequestPushback: MsgRequestPushback
   MsgApprovePushback: MsgApprovePushback
   MsgRequestTaxi: MsgRequestTaxi
   MsgIssueTaxiRoute: MsgIssueTaxiRoute
   MsgRequestLineUp: MsgRequestLineUp
   MsgClearTakeOff: MsgClearTakeOff
   MsgReportTouchdown: MsgReportTouchdown
   MsgReportVacated: MsgReportVacated
   MsgIncursionAlert: MsgIncursionAlert
   MsgAssignTug: MsgAssignTug
   MsgDisconnectTug: MsgDisconnectTug
define

   fun {MsgRequestPushback FlightId StandId Tobt AckVar}
      msg_request_pushback(flightId: FlightId
                           standId: StandId
                           tobt: Tobt
                           ack: AckVar)
   end

   fun {MsgApprovePushback FlightId Tsat FacingDir ReleasePoint}
      msg_approve_pushback(flightId: FlightId
                           tsat: Tsat
                           facing: FacingDir
                           releaseNode: ReleasePoint)
   end

   fun {MsgRequestTaxi FlightId FromNode ToNode AckVar}
      msg_request_taxi(flightId: FlightId
                       fromNode: FromNode
                       toNode: ToNode
                       ack: AckVar)
   end

   fun {MsgIssueTaxiRoute FlightId PathEdges}
      msg_issue_taxi_route(flightId: FlightId
                           path: PathEdges)
   end

   fun {MsgRequestLineUp FlightId RunwayId AckVar}
      msg_request_lineup(flightId: FlightId
                         runwayId: RunwayId
                         ack: AckVar)
   end

   fun {MsgClearTakeOff FlightId RunwayId Heading WindKts}
      msg_clear_takeoff(flightId: FlightId
                        runwayId: RunwayId
                        assignedHeadingDeg: Heading
                        surfaceWindKts: WindKts)
   end

   fun {MsgReportTouchdown FlightId RunwayId Aldt}
      msg_report_touchdown(flightId: FlightId
                           runwayId: RunwayId
                           aldt: Aldt)
   end

   fun {MsgReportVacated FlightId RunwayId ExitTaxiwayNode}
      msg_report_vacated(flightId: FlightId
                         runwayId: RunwayId
                         exitNode: ExitTaxiwayNode)
   end

   fun {MsgIncursionAlert AlertLevel Target1 Target2 TextMsg}
      msg_incursion_alert(level: AlertLevel
                          target1: Target1
                          target2: Target2
                          message: TextMsg)
   end

   fun {MsgAssignTug FlightId StandId TugId}
      msg_assign_tug(flightId: FlightId
                     standId: StandId
                     tugId: TugId)
   end

   fun {MsgDisconnectTug FlightId TugId}
      msg_disconnect_tug(flightId: FlightId
                         tugId: TugId)
   end

end
