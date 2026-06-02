CREATE OR REPLACE FUNCTION source_hash_hmis_2026_enrollments()
RETURNS trigger AS $$
BEGIN
  NEW.source_hash := encode(
    sha256(
      convert_to(
        COALESCE(NEW."EnrollmentID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."PersonalID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ProjectID", E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."EntryDate", 'YYYY-MM-DD'), E'\x1f') || E'\x1e' ||
        COALESCE(NEW."HouseholdID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."RelationshipToHoH"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."EnrollmentCoC", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."LivingSituation"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."RentalSubsidyType"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."LengthOfStay"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."LOSUnderThreshold"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."PreviousStreetESSH"::text, E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."DateToStreetESSH", 'YYYY-MM-DD'), E'\x1f') || E'\x1e' ||
        COALESCE(NEW."TimesHomelessPastThreeYears"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."MonthsHomelessPastThreeYears"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."DisablingCondition"::text, E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."DateOfEngagement", 'YYYY-MM-DD'), E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."MoveInDate", 'YYYY-MM-DD'), E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."DateOfPATHStatus", 'YYYY-MM-DD'), E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ClientEnrolledInPATH"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ReasonNotEnrolled"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."PercentAMI"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ReferralSource"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."CountOutreachReferralApproaches"::text, E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."DateOfBCPStatus", 'YYYY-MM-DD'), E'\x1f') || E'\x1e' ||
        COALESCE(NEW."EligibleForRHY"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ReasonNoServices"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."RunawayYouth"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."FormerWardChildWelfare"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ChildWelfareYears"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ChildWelfareMonths"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."FormerWardJuvenileJustice"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."JuvenileJusticeYears"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."JuvenileJusticeMonths"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."UnemploymentFam"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."MentalHealthDisorderFam"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."PhysicalDisabilityFam"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."AlcoholDrugUseDisorderFam"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."InsufficientIncome"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."IncarceratedParent"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."VAMCStation", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."TargetScreenReqd"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."TimeToHousingLoss"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."AnnualPercentAMI"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."LiteralHomelessHistory"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ClientLeaseholder"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."HOHLeaseholder"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."SubsidyAtRisk"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."EvictionHistory"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."CriminalRecord"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."IncarceratedAdult"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."PrisonDischarge"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."SexOffender"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."DisabledHoH"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."CurrentPregnant"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."SingleParent"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."DependentUnder6"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."HH5Plus"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."CoCPrioritized"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."HPScreeningScore"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ThresholdScore"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."MentalHealthConsultation"::text, E'\x1f') || E'\x1e' ||
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
