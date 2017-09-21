module GrdaWarehouse::Import::HMISFiveOne
  class IncomeBenefit < GrdaWarehouse::Hud::IncomeBenefit
    include ::Import::HMISFiveOne::Shared
    include TsqlImport
    
    setup_hud_column_access( 
      [
        :IncomeBenefitsID,
        :ProjectEntryID,
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
        :RentalAssistanceOngoing,
        :RentalAssistanceTemp,
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
  end
end