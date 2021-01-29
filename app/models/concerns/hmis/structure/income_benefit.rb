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
    def hmis_configuration(version: nil)
      case version
      when '6.11', '6.12', '2020', nil
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
          },
          Unemployment: {
            type: :integer,
          },
          UnemploymentAmount: {
            type: :string,
            limit: 50,
          },
          SSI: {
            type: :integer,
          },
          SSIAmount: {
            type: :string,
            limit: 50,
          },
          SSDI: {
            type: :integer,
          },
          SSDIAmount: {
            type: :string,
            limit: 50,
          },
          VADisabilityService: {
            type: :integer,
          },
          VADisabilityServiceAmount: {
            type: :string,
            limit: 50,
          },
          VADisabilityNonService: {
            type: :integer,
          },
          VADisabilityNonServiceAmount: {
            type: :string,
            limit: 50,
          },
          PrivateDisability: {
            type: :integer,
          },
          PrivateDisabilityAmount: {
            type: :string,
            limit: 50,
          },
          WorkersComp: {
            type: :integer,
          },
          WorkersCompAmount: {
            type: :string,
            limit: 50,
          },
          TANF: {
            type: :integer,
          },
          TANFAmount: {
            type: :string,
            limit: 50,
          },
          GA: {
            type: :integer,
          },
          GAAmount: {
            type: :string,
            limit: 50,
          },
          SocSecRetirement: {
            type: :integer,
          },
          SocSecRetirementAmount: {
            type: :string,
            limit: 50,
          },
          Pension: {
            type: :integer,
          },
          PensionAmount: {
            type: :string,
            limit: 50,
          },
          ChildSupport: {
            type: :integer,
          },
          ChildSupportAmount: {
            type: :string,
            limit: 50,
          },
          Alimony: {
            type: :integer,
          },
          AlimonyAmount: {
            type: :string,
            limit: 50,
          },
          OtherIncomeSource: {
            type: :integer,
          },
          OtherIncomeAmount: {
            type: :string,
            limit: 50,
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
      end
    end

    def hmis_indices(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      {
        [:DateCreated] => nil,
        [:DateUpdated] => nil,
        [:EnrollmentID] => nil,
        [:PersonalID] => nil,
        [:IncomeBenefitsID] => nil,
        [:ExportID] => nil,
      }
    end
  end
end
