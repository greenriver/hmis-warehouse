module GrdaWarehouse::Hud
  class IncomeBenefit < Base
    self.table_name = 'IncomeBenefits'
    self.hud_key = 'IncomeBenefitsID'
    acts_as_paranoid column: :DateDeleted

    def self.hud_csv_headers(version: nil)
      [
        "IncomeBenefitsID",
        "ProjectEntryID",
        "PersonalID",
        "InformationDate",
        "IncomeFromAnySource",
        "TotalMonthlyIncome",
        "Earned",
        "EarnedAmount",
        "Unemployment",
        "UnemploymentAmount",
        "SSI",
        "SSIAmount",
        "SSDI",
        "SSDIAmount",
        "VADisabilityService",
        "VADisabilityServiceAmount",
        "VADisabilityNonService",
        "VADisabilityNonServiceAmount",
        "PrivateDisability",
        "PrivateDisabilityAmount",
        "WorkersComp",
        "WorkersCompAmount",
        "TANF",
        "TANFAmount",
        "GA",
        "GAAmount",
        "SocSecRetirement",
        "SocSecRetirementAmount",
        "Pension",
        "PensionAmount",
        "ChildSupport",
        "ChildSupportAmount",
        "Alimony",
        "AlimonyAmount",
        "OtherIncomeSource",
        "OtherIncomeAmount",
        "OtherIncomeSourceIdentify",
        "BenefitsFromAnySource",
        "SNAP",
        "WIC",
        "TANFChildCare",
        "TANFTransportation",
        "OtherTANF",
        "RentalAssistanceOngoing",
        "RentalAssistanceTemp",
        "OtherBenefitsSource",
        "OtherBenefitsSourceIdentify",
        "InsuranceFromAnySource",
        "Medicaid",
        "NoMedicaidReason",
        "Medicare",
        "NoMedicareReason",
        "SCHIP",
        "NoSCHIPReason",
        "VAMedicalServices",
        "NoVAMedReason",
        "EmployerProvided",
        "NoEmployerProvidedReason",
        "COBRA",
        "NoCOBRAReason",
        "PrivatePay",
        "NoPrivatePayReason",
        "StateHealthIns",
        "NoStateHealthInsReason",
        "IndianHealthServices",
        "NoIndianHealthServicesReason",
        "OtherInsurance",
        "OtherInsuranceIdentify",
        "HIVAIDSAssistance",
        "NoHIVAIDSAssistanceReason",
        "ADAP",
        "NoADAPReason",
        "DataCollectionStage",
        "DateCreated",
        "DateUpdated",
        "UserID",
        "DateDeleted",
        "ExportID"
      ]
    end

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', foreign_key: ['PersonalID', 'data_source_id'], primary_key: ['PersonalID', 'data_source_id'], inverse_of: :income_benefits
    belongs_to :project, class_name: 'GrdaWarehouse::Hud::Project', primary_key: ['ProjectID',  :data_source_id], foreign_key: ['ProjectID', :data_source_id], inverse_of: :income_benefits
    belongs_to :enrollment, **hud_belongs(Enrollment), inverse_of: :income_benefits
    belongs_to :export, **hud_belongs(Export), inverse_of: :income_benefits

    scope :any_benefits, -> {
      at = arel_table
      conditions = SOURCES.keys.map{ |k| at[k].eq 1 }
      condition = conditions.shift
      condition = condition.or( conditions.shift ) while conditions.any?
      where( condition )
    }

    # produced by eliminating those columns matching /id|date|amount|reason|stage/i
    SOURCES = {
      Alimony:                :AlimonyAmount,
      ChildSupport:           :ChildSupportAmount,
      Earned:                 :EarnedAmount,
      GA:                     :GAAmount,
      OtherIncomeSource:      :OtherIncomeAmount,
      Pension:                :PensionAmount,
      PrivateDisability:      :PrivateDisabilityAmount,
      SSDI:                   :SSDIAmount,
      SSI:                    :SSIAmount,
      SocSecRetirement:       :SocSecRetirementAmount,
      TANF:                   :TANFAmount,
      Unemployment:           :UnemploymentAmount,
      VADisabilityNonService: :VADisabilityNonServiceAmount,
      VADisabilityService:    :VADisabilityServiceAmount,
      WorkersComp:            :WorkersCompAmount,
    }.freeze

    def sources
      @sources ||= SOURCES.keys.select{ |c| send(c) == 1 }
    end

    def sources_and_amounts
      @sources_and_amounts ||= sources.map{ |s| [ s, send(SOURCES[s]) ] }.to_h
    end

    def amounts
      sources_and_amounts.values
    end
  end
end