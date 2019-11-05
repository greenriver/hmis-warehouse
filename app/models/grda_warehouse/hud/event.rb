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
      ].freeze
    end

    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :events, optional: true
    belongs_to :enrollment, **hud_enrollment_belongs, inverse_of: :events
    has_one :direct_client, **hud_assoc(:PersonalID, 'Client'), inverse_of: :direct_events
    has_one :client, through: :enrollment, inverse_of: :events
    belongs_to :data_source

  end
end
