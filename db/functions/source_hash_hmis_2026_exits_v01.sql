CREATE OR REPLACE FUNCTION source_hash_hmis_2026_exits()
RETURNS trigger AS $$
BEGIN
  NEW.source_hash := encode(
    sha256(
      convert_to(
        COALESCE(NEW."ExitID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."EnrollmentID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."PersonalID", E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."ExitDate", 'YYYY-MM-DD'), E'\x1f') || E'\x1e' ||
        COALESCE(NEW."Destination"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."DestinationSubsidyType"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."OtherDestination", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."HousingAssessment"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."SubsidyInformation"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ProjectCompletionStatus"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."EarlyExitReason"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ExchangeForSex"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ExchangeForSexPastThreeMonths"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."CountOfExchangeForSex"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."AskedOrForcedToExchangeForSex"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."AskedOrForcedToExchangeForSexPastThreeMonths"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."WorkPlaceViolenceThreats"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."WorkplacePromiseDifference"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."CoercedToContinueWork"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."LaborExploitPastThreeMonths"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."CounselingReceived"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."IndividualCounseling"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."FamilyCounseling"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."GroupCounseling"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."SessionCountAtExit"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."PostExitCounselingPlan"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."SessionsInPlan"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."DestinationSafeClient"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."DestinationSafeWorker"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."PosAdultConnections"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."PosPeerConnections"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."PosCommunityConnections"::text, E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."AftercareDate", 'YYYY-MM-DD'), E'\x1f') || E'\x1e' ||
        COALESCE(NEW."AftercareProvided"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."EmailSocialMedia"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."Telephone"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."InPersonIndividual"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."InPersonGroup"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."CMExitReason"::text, E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."DateCreated", 'YYYY-MM-DD HH24:MI:SS.US'), E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."DateUpdated", 'YYYY-MM-DD HH24:MI:SS.US'), E'\x1f') || E'\x1e' ||
        COALESCE(NEW."UserID", E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."DateDeleted", 'YYYY-MM-DD HH24:MI:SS.US'), E'\x1f'),
        'UTF8'
      )
    ),
    'hex'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
