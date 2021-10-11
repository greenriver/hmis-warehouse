###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class Exit < Base
    include HudSharedScopes
    include ::HMIS::Structure::Exit
    include RailsDrivers::Extensions

    attr_accessor :source_id

    self.table_name = 'Exit'
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    belongs_to :enrollment, **hud_enrollment_belongs, inverse_of: :exit, optional: true
    belongs_to :data_source, inverse_of: :exits, optional: true
    has_one :client, through: :enrollment, inverse_of: :exits
    belongs_to :direct_client, **hud_assoc(:PersonalID, 'Client'), inverse_of: :direct_exits, optional: true
    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :exits, optional: true, optional: true
    has_one :project, through: :enrollment
    has_one :destination_client, through: :enrollment

    scope :permanent, -> do
      where(Destination: ::HUD.permanent_destinations)
    end

    scope :closed_within_range, ->(range) do
      where(ExitDate: range)
    end

    def self.related_item_keys
      [
        :PersonalID,
        :EnrollmentID,
      ]
    end
  end
end
