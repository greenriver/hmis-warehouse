###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Hud
  class Event < Base
    include HudSharedScopes
    self.table_name = :Event
    self.hud_key = :EventID
    acts_as_paranoid column: :DateDeleted

    def self.hud_csv_headers(version: nil)
      [
        :EventID,
        :EnrollmentID,
        :PersonalID,
        :EventDate,
        :Event,
        :ProbSolDivRRResult,
        :ReferralCaseManageAfter,
        :LocationCrisisorPHHousing,
        :ReferralResult,
        :ResultDate,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
        :data_source_id,
      ].freeze
    end

    belongs_to :export, **hud_belongs(Export), inverse_of: :events
    belongs_to :enrollment, **hud_belongs(Enrollment)
    belongs_to :client, **hud_belongs(Client)
    belongs_to :data_source

  end
end
