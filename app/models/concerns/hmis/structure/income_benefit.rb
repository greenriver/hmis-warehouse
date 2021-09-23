###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HMIS::Structure::IncomeBenefit
  extend ActiveSupport::Concern
  include ::HMIS::Structure::Base

  included do
    self.hud_key = :IncomeBenefitsID
    acts_as_paranoid(column: :DateDeleted)
  end

  module ClassMethods
    def hud_csv_file_name(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      'IncomeBenefits.csv'
    end

    def hmis_configuration(version: nil)
      case version
      when '6.11', '6.12', '2020'
        {
          IncomeBenefitsID: {
            type: :string,
            limit: 32,
            null: false,
          },
          EnrollmentID: {
            type: :string,
            limit: 32,
            null: false,
          },
          PersonalID: {
            type: :string,
            limit: 32,
            null: false,
          },
          InformationDate: {
            type: :date,
            null: false,
          },
          IncomeFromAnySource: {
            type: :integer,
          },
          TotalMonthlyIncome: {
            type: :string,
            limit: 50,
          },
          Earned: {
            type: :integer,
          },
          EarnedAmount: {
            type: :string,
            limit: 50,
            check: :money,
          },
          Unemployment: {
            type: :integer,
          },
          UnemploymentAmount: {
            type: :string,
            limit: 50,
            check: :money,
          },
          SSI: {
            type: :integer,
          },
          SSIAmount: {
            type: :string,
            limit: 50,
            check: :money,
          },
          SSDI: {
            type: :integer,
          },
          SSDIAmount: {
            type: :string,
            limit: 50,
            check: :money,
          },
          VADisabilityService: {
            type: :integer,
          },
          VADisabilityServiceAmount: {
            type: :string,
            limit: 50,
            check: :money,
          },
          VADisabilityNonService: {
            type: :integer,
          },
          VADisabilityNonServiceAmount: {
            type: :string,
            limit: 50,
            check: :money,
          },
          PrivateDisability: {
            type: :integer,
          },
          PrivateDisabilityAmount: {
            type: :string,
            limit: 50,
            check: :money,
          },
          WorkersComp: {
            type: :integer,
          },
          WorkersCompAmount: {
            type: :string,
            limit: 50,
            check: :money,
          },
          TANF: {
            type: :integer,
          },
          TANFAmount: {
            type: :string,
            limit: 50,
            check: :money,
          },
          GA: {
            type: :integer,
          },
          GAAmount: {
            type: :string,
            limit: 50,
            check: :money,
          },
          SocSecRetirement: {
            type: :integer,
          },
          SocSecRetirementAmount: {
            type: :string,
            limit: 50,
            check: :money,
          },
          Pension: {
            type: :integer,
          },
          PensionAmount: {
            type: :string,
            limit: 50,
            check: :money,
          },
          ChildSupport: {
            type: :integer,
          },
          ChildSupportAmount: {
            type: :string,
            limit: 50,
            check: :money,
          },
          Alimony: {
            type: :integer,
          },
          AlimonyAmount: {
            type: :string,
            limit: 50,
            check: :money,
          },
          OtherIncomeSource: {
            type: :integer,
          },
          OtherIncomeAmount: {
            type: :string,
            limit: 50,
            check: :money,
          },
          OtherIncomeSourceIdentify: {
            type: :string,
            limit: 50,
          },
          BenefitsFromAnySource: {
            type: :integer,
          },
          SNAP: {
            type: :integer,
          },
          WIC: {
            type: :integer,
          },
          TANFChildCare: {
            type: :integer,
          },
          TANFTransportation: {
            type: :integer,
          },
          OtherTANF: {
            type: :integer,
          },
          OtherBenefitsSource: {
            type: :integer,
          },
          OtherBenefitsSourceIdentify: {
            type: :string,
            limit: 50,
          },
          InsuranceFromAnySource: {
            type: :integer,
          },
          Medicaid: {
            type: :integer,
          },
          NoMedicaidReason: {
            type: :integer,
          },
          Medicare: {
            type: :integer,
          },
          NoMedicareReason: {
            type: :integer,
          },
          SCHIP: {
            type: :integer,
          },
          NoSCHIPReason: {
            type: :integer,
          },
          VAMedicalServices: {
            type: :integer,
          },
          NoVAMedReason: {
            type: :integer,
          },
          EmployerProvided: {
            type: :integer,
          },
          NoEmployerProvidedReason: {
            type: :integer,
          },
          COBRA: {
            type: :integer,
          },
          NoCOBRAReason: {
            type: :integer,
          },
          PrivatePay: {
            type: :integer,
          },
          NoPrivatePayReason: {
            type: :integer,
          },
          StateHealthIns: {
            type: :integer,
          },
          NoStateHealthInsReason: {
            type: :integer,
          },
          IndianHealthServices: {
            type: :integer,
          },
          NoIndianHealthServicesReason: {
            type: :integer,
          },
          OtherInsurance: {
            type: :integer,
          },
          OtherInsuranceIdentify: {
            type: :string,
            limit: 50,
          },
          HIVAIDSAssistance: {
            type: :integer,
          },
          NoHIVAIDSAssistanceReason: {
            type: :integer,
          },
          ADAP: {
            type: :integer,
          },
          NoADAPReason: {
            type: :integer,
          },
          ConnectionWithSOAR: {
            type: :integer,
          },
          DataCollectionStage: {
            type: :integer,
          },
          DateCreated: {
            type: :datetime,
            null: false,
          },
          DateUpdated: {
            type: :datetime,
            null: false,
          },
          UserID: {
            type: :string,
            limit: 32,
            null: false,
          },
          DateDeleted: {
            type: :datetime,
          },
          ExportID: {
            type: :string,
            limit: 32,
            null: false,
          },
        }
      when '2022'
        {
          IncomeBenefitsID: {
            type: :string,
            limit: 32,
            null: false,
          },
          EnrollmentID: {
            type: :string,
            limit: 32,
            null: false,
          },
          PersonalID: {
            type: :string,
            limit: 32,
            null: false,
          },
          InformationDate: {
            type: :date,
            null: false,
          },
          IncomeFromAnySource: {
            type: :integer,
          },
          TotalMonthlyIncome: {
            type: :string,
            limit: 50,
          },
          Earned: {
            type: :integer,
          },
          EarnedAmount: {
            type: :string,
            limit: 50,
            check: :money,
          },
          Unemployment: {
            type: :integer,
          },
          UnemploymentAmount: {
            type: :string,
            limit: 50,
            check: :money,
          },
          SSI: {
            type: :integer,
          },
          SSIAmount: {
            type: :string,
            limit: 50,
            check: :money,
          },
          SSDI: {
            type: :integer,
          },
          SSDIAmount: {
            type: :string,
            limit: 50,
            check: :money,
          },
          VADisabilityService: {
            type: :integer,
          },
          VADisabilityServiceAmount: {
            type: :string,
            limit: 50,
            check: :money,
          },
          VADisabilityNonService: {
            type: :integer,
          },
          VADisabilityNonServiceAmount: {
            type: :string,
            limit: 50,
            check: :money,
          },
          PrivateDisability: {
            type: :integer,
          },
          PrivateDisabilityAmount: {
            type: :string,
            limit: 50,
            check: :money,
          },
          WorkersComp: {
            type: :integer,
          },
          WorkersCompAmount: {
            type: :string,
            limit: 50,
            check: :money,
          },
          TANF: {
            type: :integer,
          },
          TANFAmount: {
            type: :string,
            limit: 50,
            check: :money,
          },
          GA: {
            type: :integer,
          },
          GAAmount: {
            type: :string,
            limit: 50,
            check: :money,
          },
          SocSecRetirement: {
            type: :integer,
          },
          SocSecRetirementAmount: {
            type: :string,
            limit: 50,
            check: :money,
          },
          Pension: {
            type: :integer,
          },
          PensionAmount: {
            type: :string,
            limit: 50,
            check: :money,
          },
          ChildSupport: {
            type: :integer,
          },
          ChildSupportAmount: {
            type: :string,
            limit: 50,
            check: :money,
          },
          Alimony: {
            type: :integer,
          },
          AlimonyAmount: {
            type: :string,
            limit: 50,
            check: :money,
          },
          OtherIncomeSource: {
            type: :integer,
          },
          OtherIncomeAmount: {
            type: :string,
            limit: 50,
            check: :money,
          },
          OtherIncomeSourceIdentify: {
            type: :string,
            limit: 50,
          },
          BenefitsFromAnySource: {
            type: :integer,
          },
          SNAP: {
            type: :integer,
          },
          WIC: {
            type: :integer,
          },
          TANFChildCare: {
            type: :integer,
          },
          TANFTransportation: {
            type: :integer,
          },
          OtherTANF: {
            type: :integer,
          },
          OtherBenefitsSource: {
            type: :integer,
          },
          OtherBenefitsSourceIdentify: {
            type: :string,
            limit: 50,
          },
          InsuranceFromAnySource: {
            type: :integer,
          },
          Medicaid: {
            type: :integer,
          },
          NoMedicaidReason: {
            type: :integer,
          },
          Medicare: {
            type: :integer,
          },
          NoMedicareReason: {
            type: :integer,
          },
          SCHIP: {
            type: :integer,
          },
          NoSCHIPReason: {
            type: :integer,
          },
          VAMedicalServices: {
            type: :integer,
          },
          NoVAMedReason: {
            type: :integer,
          },
          EmployerProvided: {
            type: :integer,
          },
          NoEmployerProvidedReason: {
            type: :integer,
          },
          COBRA: {
            type: :integer,
          },
          NoCOBRAReason: {
            type: :integer,
          },
          PrivatePay: {
            type: :integer,
          },
          NoPrivatePayReason: {
            type: :integer,
          },
          StateHealthIns: {
            type: :integer,
          },
          NoStateHealthInsReason: {
            type: :integer,
          },
          IndianHealthServices: {
            type: :integer,
          },
          NoIndianHealthServicesReason: {
            type: :integer,
          },
          OtherInsurance: {
            type: :integer,
          },
          OtherInsuranceIdentify: {
            type: :string,
            limit: 50,
          },
          HIVAIDSAssistance: {
            type: :integer,
          },
          NoHIVAIDSAssistanceReason: {
            type: :integer,
          },
          ADAP: {
            type: :integer,
          },
          NoADAPReason: {
            type: :integer,
          },
          RyanWhiteMedDent: {
            type: :integer,
          },
          NoRyanWhiteReason: {
            type: :integer,
          },
          ConnectionWithSOAR: {
            type: :integer,
          },
          DataCollectionStage: {
            type: :integer,
          },
          DateCreated: {
            type: :datetime,
            null: false,
          },
          DateUpdated: {
            type: :datetime,
            null: false,
          },
          UserID: {
            type: :string,
            limit: 32,
            null: false,
          },
          DateDeleted: {
            type: :datetime,
          },
          ExportID: {
            type: :string,
            limit: 32,
            null: false,
          },
        }
      end
    end

    def hmis_indices(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      {
        [:DateCreated] => nil,
        [:DateUpdated] => nil,
        [:EnrollmentID] => nil,
        [:PersonalID] => nil,
        [:IncomeBenefitsID] => nil,
        [:InformationDate] => nil,
        [:Earned, :DataCollectionStage] => nil,
        [:IncomeFromAnySource, :DataCollectionStage] => nil,
        [:ExportID] => nil,
      }
    end
  end
end
