CREATE OR REPLACE FUNCTION source_hash_hmis_2026_income_benefits()
RETURNS trigger AS $$
BEGIN
  NEW.source_hash := encode(
    sha256(
      convert_to(
        COALESCE(NEW."IncomeBenefitsID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."EnrollmentID", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."PersonalID", E'\x1f') || E'\x1e' ||
        COALESCE(to_char(NEW."InformationDate", 'YYYY-MM-DD'), E'\x1f') || E'\x1e' ||
        COALESCE(NEW."IncomeFromAnySource"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."TotalMonthlyIncome", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."Earned"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."EarnedAmount", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."Unemployment"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."UnemploymentAmount", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."SSI"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."SSIAmount", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."SSDI"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."SSDIAmount", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."VADisabilityService"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."VADisabilityServiceAmount", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."VADisabilityNonService"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."VADisabilityNonServiceAmount", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."PrivateDisability"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."PrivateDisabilityAmount", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."WorkersComp"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."WorkersCompAmount", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."TANF"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."TANFAmount", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."GA"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."GAAmount", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."SocSecRetirement"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."SocSecRetirementAmount", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."Pension"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."PensionAmount", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ChildSupport"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ChildSupportAmount", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."Alimony"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."AlimonyAmount", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."OtherIncomeSource"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."OtherIncomeAmount", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."OtherIncomeSourceIdentify", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."BenefitsFromAnySource"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."SNAP"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."WIC"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."TANFChildCare"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."TANFTransportation"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."OtherTANF"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."OtherBenefitsSource"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."OtherBenefitsSourceIdentify", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."InsuranceFromAnySource"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."Medicaid"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."NoMedicaidReason"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."Medicare"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."NoMedicareReason"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."SCHIP"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."NoSCHIPReason"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."VHAServices"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."NoVHAReason"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."EmployerProvided"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."NoEmployerProvidedReason"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."COBRA"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."NoCOBRAReason"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."PrivatePay"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."NoPrivatePayReason"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."StateHealthIns"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."NoStateHealthInsReason"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."IndianHealthServices"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."NoIndianHealthServicesReason"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."OtherInsurance"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."OtherInsuranceIdentify", E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ADAP"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."NoADAPReason"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."RyanWhiteMedDent"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."NoRyanWhiteReason"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."ConnectionWithSOAR"::text, E'\x1f') || E'\x1e' ||
        COALESCE(NEW."DataCollectionStage"::text, E'\x1f') || E'\x1e' ||
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
