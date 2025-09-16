# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
    belongs_to :enrollment_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Enrollment', primary_key: [:EnrollmentID, :PersonalID, :data_source_id], query_constraints: [:EnrollmentID, :PersonalID, :data_source_id], optional: true

    has_one :direct_client, **hud_assoc(:PersonalID, 'Client'), inverse_of: :direct_events
    has_one :client, through: :enrollment, inverse_of: :events

    scope :within_range, ->(range) do
      # convert the range into a standard range for backwards compatability
      range = (range.start..range.end) if range.is_a?(::Filters::DateRange)
      where(EventDate: range)
    end

    # Finds events that occurred during a project's Coordinated Entry (CE) participation period
    # Joins through the following associations:
    # - enrollment
    # - project
    # - ce_participations
    #
    # Conditions:
    # - EventDate must fall between CEParticipationStatusStartDate and CEParticipationStatusEndDate
    # - AccessPoint must be 1 (active)
    scope :within_ce_participation_range, -> do
      ce_t = GrdaWarehouse::Hud::CeParticipation.arel_table
      joins(enrollment: { project: :ce_participations }).
        where(
          ce_t[:AccessPoint].eq(1).and(
            arel_table[:EventDate].gteq(ce_t[:CEParticipationStatusStartDate]).and(
              arel_table[:EventDate].lteq(ce_t[:CEParticipationStatusEndDate]),
            ).or(ce_t[:CEParticipationStatusEndDate].eq(nil)),
          ),
        )
    end

    # hide previous declaration of :importable, we'll use this one
    replace_scope :importable, -> do
      where(synthetic: false)
    end

    scope :synthetic, -> do
      where(synthetic: true)
    end
  end
end
