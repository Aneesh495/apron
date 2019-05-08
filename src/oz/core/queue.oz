% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Core.Queue
% Description: Okasaki two-list purely functional FIFO queue with amortized O(1)
%              push/pop operations and thread-safe bounded buffer channels.
% =============================================================================

functor
import
   System
export
   New: New
   Enqueue: Enqueue
   Dequeue: Dequeue
   Peek: Peek
   IsEmpty: IsEmpty
   Size: Size
   ToList: ToList
   FromList: FromList
   NewBoundedBuffer: NewBoundedBuffer
define

   % --------------------------------------------------------------------------
   % Queue Structure:
   % queue(front: FrontList back: BackList size: Count)
   % Invariant: If FrontList is nil, then BackList must also be nil
   % --------------------------------------------------------------------------

   fun {New}
      queue(front: nil back: nil size: 0)
   end

   fun {IsEmpty Q}
      Q.size == 0
   end

   fun {Size Q}
      Q.size
   end

   % --------------------------------------------------------------------------
   % Reverse list helper
   % --------------------------------------------------------------------------
   fun {Rev Xs}
      fun {RevAux List Acc}
         case List
         of nil then Acc
         [] H | T then {RevAux T H | Acc}
         end
      end
   in
      {RevAux Xs nil}
   end

   % --------------------------------------------------------------------------
   % Enqueue: Pushes item to the back list
   % --------------------------------------------------------------------------
   fun {Enqueue Q Item}
      case Q
      of queue(front: nil back: _ size: _) then
         queue(front: Item | nil back: nil size: 1)
      [] queue(front: F back: B size: S) then
         queue(front: F back: Item | B size: S + 1)
      end
   end

   % --------------------------------------------------------------------------
   % Dequeue: Pops item from the front list. Returns pair(Item, NewQueue)
   % --------------------------------------------------------------------------
   fun {Dequeue Q}
      case Q
      of queue(front: nil back: _ size: _) then
         pair(none Q)
      [] queue(front: H | nil back: B size: S) then
         NewFront = {Rev B}
         NewQ = queue(front: NewFront back: nil size: S - 1)
      in
         pair(opt(H) NewQ)
      [] queue(front: H | T back: B size: S) then
         NewQ = queue(front: T back: B size: S - 1)
      in
         pair(opt(H) NewQ)
      end
   end

   % --------------------------------------------------------------------------
   % Peek: Inspects front element without removing it
   % --------------------------------------------------------------------------
   fun {Peek Q}
      case Q
      of queue(front: nil back: _ size: _) then
         none
      [] queue(front: H | _ back: _ size: _) then
         opt(H)
      end
   end

   % --------------------------------------------------------------------------
   % Conversion Utilities
   % --------------------------------------------------------------------------
   fun {ToList Q}
      case Q
      of queue(front: F back: B size: _) then
         {Append F {Rev B}}
      end
   end

   fun {FromList Xs}
      fun {Build List Q}
         case List
         of nil then Q
         [] H | T then {Build T {Enqueue Q H}}
         end
      end
   in
      {Build Xs {New}}
   end

   % --------------------------------------------------------------------------
   % Thread-Safe Bounded Buffer using Active Port and Logic Tokens
   % Provides backpressure: Put suspends when buffer is full
   % --------------------------------------------------------------------------
   fun {NewBoundedBuffer Capacity}
      local InStream Port in
         Port = {NewPort InStream}
         thread
            proc {Loop S CurrentQueue FreeSlots}
               case S
               of nil then skip
               [] put(Item Ack) | Rest then
                  if FreeSlots > 0 then
                     NewQ = {Enqueue CurrentQueue Item}
                     Ack = true
                     {Loop Rest NewQ FreeSlots - 1}
                  else
                     % Buffer full, suspend until item is consumed
                     Ack = wait
                     {Loop Rest CurrentQueue 0}
                  end
               [] get(ResultVar) | Rest then
                  case {Dequeue CurrentQueue}
                  of pair(opt(Val) NewQ) then
                     ResultVar = Val
                     {Loop Rest NewQ FreeSlots + 1}
                  [] pair(none _) then
                     ResultVar = empty_queue
                     {Loop Rest CurrentQueue FreeSlots}
                  end
               end
            end
         in
            {Loop InStream {New} Capacity}
         end
         buffer(port: Port capacity: Capacity)
      end
   end

end
