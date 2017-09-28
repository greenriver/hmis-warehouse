module GrdaWarehouse::Export::HMISSixOneOne
  class IncomeBenefit < GrdaWarehouse::Hud::IncomeBenefit
    include ::Export::HMISSixOneOne::Shared
    include TsqlImport
    
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

    def self.date_provided_column 
      :InformationDate
    end
    
    def self.file_name
      'IncomeBenefits.csv'
    end

    # Currently this translates back to HMIS 5.1
    # and does other data cleanup as necessary
    def self.translate_to_db_headers(row)
      row[:ProjectEntryID] = row.delete(:EnrollmentID)
      return row
    end
  end
end