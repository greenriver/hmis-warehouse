###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class Event < Base
    include HudSharedScopes
    include ::HmisStructure::Event
    include ::HmisStructure::Shared
    include RailsDrivers::Extensions

    attr_accessor :source_id

    self.table_name = :Event
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :events, optional: true
    belongs_to :user, **hud_assoc(:UserID, 'User'), inverse_of: :events, optional: true
    belongs_to :enrollment, **hud_enrollment_belongs, inverse_of: :events, optional: true
    belongs_to :data_source
    # Setup an association to enrollment that allows us to pull the records even if the
    # enrollment has been deleted
    belongs_to :enrollment_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Enrollment', primary_key: [:EnrollmentID, :PersonalID, :data_source_id], foreign_key: [:EnrollmentID, :PersonalID, :data_source_id], optional: true

    has_one :direct_client, **hud_assoc(:PersonalID, 'Client'), inverse_of: :direct_events
    has_one :client, through: :enrollment, inverse_of: :events

    scope :within_range, ->(range) do
      # convert the range into a standard range for backwards compatability
      range = (range.start..range.end) if range.is_a?(::Filters::DateRange)
      where(EventDate: range)
    end

    scope :importable, -> do
      where(synthetic: false)
    end

    scope :synthetic, -> do
      where(synthetic: true)
    end
  end
end
