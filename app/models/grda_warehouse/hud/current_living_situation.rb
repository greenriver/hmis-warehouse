###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Hud
  class CurrentLivingSituation < Base
    include HudSharedScopes
    self.table_name = :CurrentLivingSituation
    self.hud_key = :CurrentLivingSitID
    acts_as_paranoid column: :DateDeleted

    def self.hud_csv_headers(version: nil)
      [
        :CurrentLivingSitID,
        :EnrollmentID,
        :PersonalID,
        :InformationDate,
        :CurrentLivingSituation,
        :VerifiedBy,
        :LeaveSituation14Days,
        :SubsequentResidence,
        :ResourcesToObtain,
        :LeaseOwn60Day,
        :MovedTwoOrMore,
        :LocationDetails,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ].freeze
    end

    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :current_living_situation, optional: true
    belongs_to :enrollment, **hud_enrollment_belongs
    has_many :client, through: :enrollment
    belongs_to :direct_client, **hud_assoc(:PersonalID, 'Client')
    belongs_to :data_source

  end
end
