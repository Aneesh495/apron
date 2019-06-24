% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: CDM.TOBT
% Description: Target Off-Block Time (TOBT) validation, anti-churn rate limiting,
%              turnaround tolerance checking, and Eurocontrol compliance rules.
% =============================================================================

functor
export
   ValidateTOBT: ValidateTOBT
   ShouldEmitTargetDPI: ShouldEmitTargetDPI
   CheckTOBTWindowCompliance: CheckTOBTWindowCompliance
   IsTOBTExpired: IsTOBTExpired
define

   % --------------------------------------------------------------------------
   % ValidateTOBT: Verifies proposed TOBT against operational constraints
   % Returns pair(IsValid, ReasonAtom)
   % --------------------------------------------------------------------------
   fun {ValidateTOBT ProposedTOBT AIBT CurrentTime MinTurnaroundSeconds}
      if ProposedTOBT < CurrentTime then
         pair(false tobt_in_past)
      elseif AIBT > 0.0 andthen ProposedTOBT < (AIBT + MinTurnaroundSeconds) then
         pair(false tobt_violates_min_turnaround)
      else
         pair(true valid)
      end
   end

   % --------------------------------------------------------------------------
   % ShouldEmitTargetDPI: Eurocontrol rule: emit T-DPI if delta >= 5 min (300 sec)
   % --------------------------------------------------------------------------
   fun {ShouldEmitTargetDPI CurrentTOBT NewTOBT}
      Diff = NewTOBT - CurrentTOBT
      AbsDiff = if Diff < 0.0 then ~Diff else Diff end
   in
      AbsDiff >= 300.0
   end

   % --------------------------------------------------------------------------
   % CheckTOBTWindowCompliance: Flight must request startup within [-5, +5] min of TOBT
   % --------------------------------------------------------------------------
   fun {CheckTOBTWindowCompliance StartupRequestTime TOBT}
      Diff = StartupRequestTime - TOBT
   in
      Diff >= ~300.0 andthen Diff =< 300.0
   end

   % --------------------------------------------------------------------------
   % IsTOBTExpired: If CurrentTime > TOBT + 5 min without startup request,
   % TOBT is invalidated and must be republished by ground handler.
   % --------------------------------------------------------------------------
   fun {IsTOBTExpired CurrentTime TOBT HasRequestedStartup}
      if HasRequestedStartup then
         false
      else
         CurrentTime > (TOBT + 300.0)
      end
   end

end
