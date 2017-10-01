module GrdaWarehouse::Export::HMISSixOneOne
  class IncomeBenefit < GrdaWarehouse::Import::HMISSixOneOne::IncomeBenefit
    include ::Export::HMISSixOneOne::Shared
    setup_hud_column_access( 
      [
        :IncomeBenefitsID,
        :EnrollmentID,
        :PersonalID,
        :InformationDate,
        :IncomeFromAnySource,
        :TotalMonthlyIncome,
        :Earned,
        :EarnedAmount,
        :Unemployment,
        :UnemploymentAmount,
        :SSI,
        :SSIAmount,
        :SSDI,
        :SSDIAmount,
        :VADisabilityService,
        :VADisabilityServiceAmount,
        :VADisabilityNonService,
        :VADisabilityNonServiceAmount,
        :PrivateDisability,
        :PrivateDisabilityAmount,
        :WorkersComp,
        :WorkersCompAmount,
        :TANF,
        :TANFAmount,
        :GA,
        :GAAmount,
        :SocSecRetirement,
        :SocSecRetirementAmount,
        :Pension,
        :PensionAmount,
        :ChildSupport,
        :ChildSupportAmount,
        :Alimony,
        :AlimonyAmount,
        :OtherIncomeSource,
        :OtherIncomeAmount,
        :OtherIncomeSourceIdentify,
        :BenefitsFromAnySource,
        :SNAP,
        :WIC,
        :TANFChildCare,
        :TANFTransportation,
        :OtherTANF,
        :OtherBenefitsSource,
        :OtherBenefitsSourceIdentify,
        :InsuranceFromAnySource,
        :Medicaid,
        :NoMedicaidReason,
        :Medicare,
        :NoMedicareReason,
        :SCHIP,
        :NoSCHIPReason,
        :VAMedicalServices,
        :NoVAMedReason,
        :EmployerProvided,
        :NoEmployerProvidedReason,
        :COBRA,
        :NoCOBRAReason,
        :PrivatePay,
        :NoPrivatePayReason,
        :StateHealthIns,
        :NoStateHealthInsReason,
        :IndianHealthServices,
        :NoIndianHealthServicesReason,
        :OtherInsurance,
        :OtherInsuranceIdentify,
        :HIVAIDSAssistance,
        :NoHIVAIDSAssistanceReason,
        :ADAP,
        :NoADAPReason,
        :ConnectionWithSOAR,
        :DataCollectionStage,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ]
    )
    
    self.hud_key = :IncomeBenefitsID

    # Replace 5.1 versions with 6.11
    # ProjectEntryID with EnrollmentID etc.
    def self.clean_headers(headers)
      headers.map do |k|
        case k
        when :ProjectEntryID
          :EnrollmentID
        else
          k
        end
      end
    end
  end
end