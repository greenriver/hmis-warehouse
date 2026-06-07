###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  module Builders
    # Creates the Coordinated Entry (or other lifecycle-type) enrollment and
    # corresponding HmisSimulation::LifecycleEnrollment state record.
    #
    # Lifecycle enrollments are condition-triggered (not timed):
    #   - Opens when a client enters a trigger_population
    #   - EntryDate may be backdated by days_before_trigger
    #   - Closes on housing_move_in, disengagement timeout, or pre_entry_exit
    class LifecycleEnrollmentBuilder
      EXPORT_ID = Bootstrapper::EXPORT_ID

      def initialize(client:, lifecycle_name:, ce_project:, opens_on:, coc_code:, data_source:, user_id:)
        @client         = client
        @lifecycle_name = lifecycle_name
        @project        = ce_project
        @opens_on       = opens_on
        @coc_code       = coc_code
        @ds             = data_source
        @uid            = user_id
      end

      def build!
        enrollment = Hmis::Hud::Enrollment.create!(
          data_source_id: @ds.id,
          UserID: @uid,
          ExportID: EXPORT_ID,
          DateCreated: @opens_on.to_datetime,
          DateUpdated: @opens_on.to_datetime,
          EnrollmentID: FakeIdentifier.uuid,
          PersonalID: @client.PersonalID,
          project_pk: @project.id,
          ProjectID: @project.ProjectID,
          HouseholdID: FakeIdentifier.uuid,
          EntryDate: @opens_on,
          RelationshipToHoH: 1,
          DisablingCondition: 99,
          LivingSituation: 116,
          EnrollmentCoC: @coc_code,
        )

        LifecycleEnrollment.create!(
          data_source_id: @ds.id,
          hud_client_id: @client.id,
          hud_enrollment_id: enrollment.id,
          lifecycle_name: @lifecycle_name,
          status: 'open',
          opens_on: @opens_on,
        )
      end
    end
  end
end
