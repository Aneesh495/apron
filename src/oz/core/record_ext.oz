% =============================================================================
% APRON AIRPORT COLLABORATIVE DECISION MAKING SYSTEM
% Module: Core.RecordExt
% Description: Associative record operations, feature projection, record merging,
%              and dynamic schema validation for flight and aerodrome records.
% =============================================================================

functor
import
   Record
   System
export
   HasFeature: HasFeature
   GetFeatureDefault: GetFeatureDefault
   ProjectRecord: ProjectRecord
   SubtractFeatures: SubtractFeatures
   MergeRecords: MergeRecords
   RecordToList: RecordToList
   ValidateSchema: ValidateSchema
define

   % --------------------------------------------------------------------------
   % HasFeature: Checks whether feature F exists on Record R
   % --------------------------------------------------------------------------
   fun {HasFeature R F}
      try
         _ = R.F
         true
      catch _ then
         false
      end
   end

   % --------------------------------------------------------------------------
   % GetFeatureDefault: Returns R.F if feature exists, otherwise DefaultVal
   % --------------------------------------------------------------------------
   fun {GetFeatureDefault R F DefaultVal}
      try
         R.F
      catch _ then
         DefaultVal
      end
   end

   % --------------------------------------------------------------------------
   % RecordToList: Converts record features into list of pair(Feature, Value)
   % --------------------------------------------------------------------------
   fun {RecordToList R}
      Arity = {Record.arity R}
      fun {Convert Features}
         case Features
         of nil then nil
         [] F | Rest then
            pair(F R.F) | {Convert Rest}
         end
      end
   in
      {Convert Arity}
   end

   % --------------------------------------------------------------------------
   % ProjectRecord: Filters record features to only those in AllowedList
   % --------------------------------------------------------------------------
   fun {ProjectRecord R AllowedList}
      fun {Collect Feats}
         case Feats
         of nil then nil
         [] F | Rest then
            if {HasFeature R F} then
               pair(F R.F) | {Collect Rest}
            else
               {Collect Rest}
            end
         end
      end
   in
      {Collect AllowedList}
   end

   % --------------------------------------------------------------------------
   % SubtractFeatures: Removes features in ExcludedList
   % --------------------------------------------------------------------------
   fun {SubtractFeatures R ExcludedList}
      Arity = {Record.arity R}
      fun {IsExcluded F List}
         case List
         of nil then false
         [] E | Rest then
            if F == E then true else {IsExcluded F Rest} end
         end
      end
      fun {FilterFeats Feats}
         case Feats
         of nil then nil
         [] F | Rest then
            if {IsExcluded F ExcludedList} then
               {FilterFeats Rest}
            else
               pair(F R.F) | {FilterFeats Rest}
            end
         end
      end
   in
      {FilterFeats Arity}
   end

   % --------------------------------------------------------------------------
   % MergeRecords: Combines two records; features in R2 override R1
   % --------------------------------------------------------------------------
   fun {MergeRecords R1 R2}
      L1 = {RecordToList R1}
      L2 = {RecordToList R2}
      fun {UpdateList BaseList NewItems}
         case NewItems
         of nil then BaseList
         [] pair(KF VF) | Rest then
            fun {ReplaceOrAppend List Found}
               case List
               of nil then
                  if Found then nil else pair(KF VF) | nil end
               [] pair(K V) | Tail then
                  if K == KF then
                     pair(KF VF) | {ReplaceOrAppend Tail true}
                  else
                     pair(K V) | {ReplaceOrAppend Tail Found}
                  end
               end
            end
         in
            {UpdateList {ReplaceOrAppend BaseList false} Rest}
         end
      end
   in
      {UpdateList L1 L2}
   end

   % --------------------------------------------------------------------------
   % ValidateSchema: Verifies that Record R contains all RequiredFeatures
   % Returns pair(IsValid, MissingFeaturesList)
   % --------------------------------------------------------------------------
   fun {ValidateSchema R RequiredFeatures}
      fun {CheckMissing Feats MissingAcc}
         case Feats
         of nil then MissingAcc
         [] F | Rest then
            if {HasFeature R F} then
               {CheckMissing Rest MissingAcc}
            else
               {CheckMissing Rest F | MissingAcc}
            end
         end
      end
      Missing = {CheckMissing RequiredFeatures nil}
   in
      if Missing == nil then
         pair(true nil)
      else
         pair(false Missing)
      end
   end

end
