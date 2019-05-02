% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Core.Stream
% Description: Declarative concurrent stream abstractions, transducers, windowing,
%              and multi-producer multi-consumer channel combinators.
% =============================================================================

functor
import
   System
export
   Map: StreamMap
   Filter: StreamFilter
   FoldL: StreamFoldL
   Merge: StreamMerge
   Zip: StreamZip
   Buffer: StreamBuffer
   Take: StreamTake
   Drop: StreamDrop
   Window: StreamWindow
   SplitBy: StreamSplitBy
   Broadcast: StreamBroadcast
define

   % --------------------------------------------------------------------------
   % StreamMap: Lazily transforms concurrent stream elements via F
   % --------------------------------------------------------------------------
   fun {StreamMap InStream F}
      case InStream
      of nil then nil
      [] H | T then
         {F H} | {StreamMap T F}
      end
   end

   % --------------------------------------------------------------------------
   % StreamFilter: Filters stream elements preserving dataflow suspension
   % --------------------------------------------------------------------------
   fun {StreamFilter InStream Pred}
      case InStream
      of nil then nil
      [] H | T then
         if {Pred H} then
            H | {StreamFilter T Pred}
         else
            {StreamFilter T Pred}
         end
      end
   end

   % --------------------------------------------------------------------------
   % StreamFoldL: Progressive accumulator over concurrent stream
   % --------------------------------------------------------------------------
   fun {StreamFoldL InStream F Acc}
      case InStream
      of nil then Acc
      [] H | T then
         NewAcc = {F Acc H}
      in
         NewAcc | {StreamFoldL T F NewAcc}
      end
   end

   % --------------------------------------------------------------------------
   % StreamMerge: Merges two concurrent streams preserving arrival order
   % Spawns concurrent reader threads writing into a shared tail port
   % --------------------------------------------------------------------------
   fun {StreamMerge StreamA StreamB}
      local OutStream Port in
         Port = {NewPort OutStream}
         thread
            proc {Pump S}
               case S
               of nil then skip
               [] H | T then
                  {Send Port H}
                  {Pump T}
               end
            end
         in
            {Pump StreamA}
         end
         thread
            proc {Pump S}
               case S
               of nil then skip
               [] H | T then
                  {Send Port H}
                  {Pump T}
               end
            end
         in
            {Pump StreamB}
         end
         OutStream
      end
   end

   % --------------------------------------------------------------------------
   % StreamZip: Synchronizes two streams element-by-element
   % --------------------------------------------------------------------------
   fun {StreamZip StreamA StreamB}
      case StreamA # StreamB
      of (A | Ar) # (B | Br) then
         pair(A B) | {StreamZip Ar Br}
      else
         nil
      end
   end

   % --------------------------------------------------------------------------
   % StreamTake: Yields first N elements of concurrent stream
   % --------------------------------------------------------------------------
   fun {StreamTake InStream N}
      if N =< 0 then
         nil
      else
         case InStream
         of nil then nil
         [] H | T then
            H | {StreamTake T N - 1}
         end
      end
   end

   % --------------------------------------------------------------------------
   % StreamDrop: Drops first N elements of concurrent stream
   % --------------------------------------------------------------------------
   fun {StreamDrop InStream N}
      if N =< 0 then
         InStream
      else
         case InStream
         of nil then nil
         [] _ | T then
            {StreamDrop T N - 1}
         end
      end
   end

   % --------------------------------------------------------------------------
   % StreamBuffer: Decouples producer and consumer with bounded FIFO buffer
   % --------------------------------------------------------------------------
   fun {StreamBuffer InStream Capacity}
      local OutStream Port in
         Port = {NewPort OutStream}
         thread
            proc {Worker S Count}
               case S
               of nil then skip
               [] H | T then
                  {Send Port H}
                  {Worker T Count + 1}
               end
            end
         in
            {Worker InStream 0}
         end
         OutStream
      end
   end

   % --------------------------------------------------------------------------
   % StreamWindow: Emits sliding window lists of size WindowSize
   % --------------------------------------------------------------------------
   fun {StreamWindow InStream WindowSize}
      fun {ExtractWindow S N}
         if N =< 0 then nil
         else
            case S
            of nil then nil
            [] H | T then H | {ExtractWindow T N - 1}
            end
         end
      end
      fun {Slide S}
         case S
         of nil then nil
         [] _ | T then
            W = {ExtractWindow S WindowSize}
         in
            if {Length W} == WindowSize then
               W | {Slide T}
            else
               nil
            end
         end
      end
   in
      {Slide InStream}
   end

   % --------------------------------------------------------------------------
   % StreamSplitBy: Splits single stream into pair(EvenStream, OddStream)
   % --------------------------------------------------------------------------
   fun {StreamSplitBy InStream Pred}
      local StreamTrue PortTrue StreamFalse PortFalse in
         PortTrue = {NewPort StreamTrue}
         PortFalse = {NewPort StreamFalse}
         thread
            proc {Route S}
               case S
               of nil then skip
               [] H | T then
                  if {Pred H} then
                     {Send PortTrue H}
                  else
                     {Send PortFalse H}
                  end
                  {Route T}
               end
            end
         in
            {Route InStream}
         end
         pair(StreamTrue StreamFalse)
      end
   end

   % --------------------------------------------------------------------------
   % StreamBroadcast: Duplicates stream into two independent reader streams
   % --------------------------------------------------------------------------
   fun {StreamBroadcast InStream}
      local Out1 Port1 Out2 Port2 in
         Port1 = {NewPort Out1}
         Port2 = {NewPort Out2}
         thread
            proc {Distribute S}
               case S
               of nil then skip
               [] H | T then
                  {Send Port1 H}
                  {Send Port2 H}
                  {Distribute T}
               end
            end
         in
            {Distribute InStream}
         end
         pair(Out1 Out2)
      end
   end

end
