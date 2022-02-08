###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HMIS::Structure::Exit
  extend ActiveSupport::Concern
  include ::HMIS::Structure::Base

  included do
    self.hud_key = :ExitID
    acts_as_paranoid(column: :DateDeleted)
  end

  module ClassMethods
    def hmis_configuration(version: nil)
      case version
      when '6.11', '6.12'
        {
          ExitID: {
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
          ExitDate: {
            type: :date,
            null: false,
          },
          Destination: {
            type: :integer,
            null: false,
          },
          OtherDestination: {
            type: :string,
            limit: 50,
          },
          AssessmentDisposition: {
            type: :integer,
            null: false,
          },
          OtherDisposition: {
            type: :string,
            limit: 50,
          },
          HousingAssessment: {
            type: :integer,
          },
          SubsidyInformation: {
            type: :integer,
          },
          ProjectCompletionStatus: {
            type: :integer,
          },
          EarlyExitReason: {
            type: :integer,
          },
          ExchangeForSex: {
            type: :integer,
          },
          ExchangeForSexPastThreeMonths: {
            type: :integer,
          },
          CountOfExchangeForSex: {
            type: :integer,
          },
          AskedOrForcedToExchangeForSex: {
            type: :integer,
          },
          AskedOrForcedToExchangeForSexPastThreeMonths: {
            type: :integer,
          },
          WorkPlaceViolenceThreats: {
            type: :integer,
          },
          WorkplacePromiseDifference: {
            type: :integer,
          },
          CoercedToContinueWork: {
            type: :integer,
          },
          LaborExploitPastThreeMonths: {
            type: :integer,
          },
          CounselingReceived: {
            type: :integer,
          },
          IndividualCounseling: {
            type: :integer,
          },
          FamilyCounseling: {
            type: :integer,
          },
          GroupCounseling: {
            type: :integer,
          },
          SessionCountAtExit: {
            type: :integer,
          },
          PostExitCounselingPlan: {
            type: :integer,
          },
          SessionsInPlan: {
            type: :integer,
          },
          DestinationSafeClient: {
            type: :integer,
          },
          DestinationSafeWorker: {
            type: :integer,
          },
          PosAdultConnections: {
            type: :integer,
          },
          PosPeerConnections: {
            type: :integer,
          },
          PosCommunityConnections: {
            type: :integer,
          },
          AftercareDate: {
            type: :date,
          },
          AftercareProvided: {
            type: :integer,
          },
          EmailSocialMedia: {
            type: :integer,
          },
          Telephone: {
            type: :integer,
          },
          InPersonIndividual: {
            type: :integer,
          },
          InPersonGroup: {
            type: :integer,
          },
          CMExitReason: {
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
      when '2020', '2022'
        {
          ExitID: {
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
          ExitDate: {
            type: :date,
            null: false,
          },
          Destination: {
            type: :integer,
            null: false,
          },
          OtherDestination: {
            type: :string,
            limit: 50,
          },
          HousingAssessment: {
            type: :integer,
          },
          SubsidyInformation: {
            type: :integer,
          },
          ProjectCompletionStatus: {
            type: :integer,
          },
          EarlyExitReason: {
            type: :integer,
          },
          ExchangeForSex: {
            type: :integer,
          },
          ExchangeForSexPastThreeMonths: {
            type: :integer,
          },
          CountOfExchangeForSex: {
            type: :integer,
          },
          AskedOrForcedToExchangeForSex: {
            type: :integer,
          },
          AskedOrForcedToExchangeForSexPastThreeMonths: {
            type: :integer,
          },
          WorkPlaceViolenceThreats: {
            type: :integer,
          },
          WorkplacePromiseDifference: {
            type: :integer,
          },
          CoercedToContinueWork: {
            type: :integer,
          },
          LaborExploitPastThreeMonths: {
            type: :integer,
          },
          CounselingReceived: {
            type: :integer,
          },
          IndividualCounseling: {
            type: :integer,
          },
          FamilyCounseling: {
            type: :integer,
          },
          GroupCounseling: {
            type: :integer,
          },
          SessionCountAtExit: {
            type: :integer,
          },
          PostExitCounselingPlan: {
            type: :integer,
          },
          SessionsInPlan: {
            type: :integer,
          },
          DestinationSafeClient: {
            type: :integer,
          },
          DestinationSafeWorker: {
            type: :integer,
          },
          PosAdultConnections: {
            type: :integer,
          },
          PosPeerConnections: {
            type: :integer,
          },
          PosCommunityConnections: {
            type: :integer,
          },
          AftercareDate: {
            type: :date,
          },
          AftercareProvided: {
            type: :integer,
          },
          EmailSocialMedia: {
            type: :integer,
          },
          Telephone: {
            type: :integer,
          },
          InPersonIndividual: {
            type: :integer,
          },
          InPersonGroup: {
            type: :integer,
          },
          CMExitReason: {
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
        [:DateDeleted] => nil,
        [:EnrollmentID] => nil,
        [:ExitDate] => nil,
        [:PersonalID] => nil,
        [:ExitID] => nil,
        [:ExportID] => nil,
      }
    end
  end
end
