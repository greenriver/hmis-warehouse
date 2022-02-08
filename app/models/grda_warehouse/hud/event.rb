###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class Event < Base
    include HudSharedScopes
    include ::HMIS::Structure::Event
    include RailsDrivers::Extensions

    attr_accessor :source_id

    self.table_name = :Event
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :events, optional: true
    belongs_to :enrollment, **hud_enrollment_belongs, inverse_of: :events, optional: true
    has_one :direct_client, **hud_assoc(:PersonalID, 'Client'), inverse_of: :direct_events
    has_one :client, through: :enrollment, inverse_of: :events
    belongs_to :data_source

    scope :importable, -> do
      where(synthetic: false)
    end

    scope :synthetic, -> do
      where(synthetic: true)
    end
  end
end
