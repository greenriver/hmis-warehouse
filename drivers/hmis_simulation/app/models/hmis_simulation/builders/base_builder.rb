###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  module Builders
    # Shared foundation for all HmisSimulation builder classes.
    #
    # Provides:
    #   EXPORT_ID                — shared constant sourced from Bootstrapper
    #   DATA_COLLECTION_STAGES   — HUD DataCollectionStage code map
    #   audit_attrs(date)        — 5 common HUD record fields for **-splat
    #   create_solo_enrollment   — single-person enrollment (class + instance form)
    class BaseBuilder
      EXPORT_ID = Bootstrapper::EXPORT_ID
      # HUD 4.11 code 116 — "Place not meant for habitation"
      PLACE_NOT_MEANT_FOR_HABITATION = 116
      DATA_COLLECTION_STAGES = { entry: 1, update: 2, exit: 3, annual: 5 }.freeze

      def initialize(data_source:, user_id:)
        @ds  = data_source
        @uid = user_id
      end

      # Creates a minimal solo (single-person, no household) HUD enrollment.
      # Used by ConcurrentEnrollmentBuilder, LifecycleEnrollmentBuilder, and Engine.
      def self.create_solo_enrollment(
        client:, project:, date:, coc_code:, data_source:, user_id:,
        living_situation: PLACE_NOT_MEANT_FOR_HABITATION, date_of_engagement: nil
      )
        Hmis::Hud::Enrollment.create!(
          data_source_id: data_source.id,
          UserID: user_id,
          ExportID: EXPORT_ID,
          DateCreated: date.to_datetime,
          DateUpdated: date.to_datetime,
          EnrollmentID: FakeIdentifier.uuid,
          PersonalID: client.PersonalID,
          project_pk: project.id,
          ProjectID: project.ProjectID,
          HouseholdID: FakeIdentifier.uuid,
          EntryDate: date,
          RelationshipToHoH: 1,
          DisablingCondition: 99,
          LivingSituation: living_situation,
          DateOfEngagement: date_of_engagement,
          EnrollmentCoC: coc_code,
        )
      end

      private

      def audit_attrs(date)
        {
          data_source_id: @ds.id,
          UserID: @uid,
          ExportID: EXPORT_ID,
          DateCreated: date.to_datetime,
          DateUpdated: date.to_datetime,
        }
      end

      def create_solo_enrollment(client:, project:, date:, coc_code:, **opts)
        self.class.create_solo_enrollment(
          client: client,
          project: project,
          date: date,
          coc_code: coc_code,
          data_source: @ds,
          user_id: @uid,
          **opts,
        )
      end
    end
  end
end
