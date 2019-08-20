###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
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

    belongs_to :export, **hud_belongs(Export), inverse_of: :current_living_situations
    belongs_to :enrollment, **hud_belongs(Enrollment)
    belongs_to :client, **hud_belongs(Client)
    belongs_to :data_source

  end
end
