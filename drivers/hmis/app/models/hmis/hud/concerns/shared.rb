###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Hud::Concerns::Shared
  extend ActiveSupport::Concern
  include Hmis::Hud::Concerns::HasEnums
  include ::HmisStructure::Shared
  include ::Hmis::Hud::Concerns::WithStrictAttributes

  included do
    # Filter down scope to only HMIS records. Helpful for finding records in the
    # rails console for single-HMIS installatinos, but should not be used otherwise
    # (because it does not take _which_ HMIS into account).
    scope :hmis, -> do
      joins(:data_source).merge(GrdaWarehouse::DataSource.hmis)
    end

    # This will return an equivalent record in the GrdaWarehouse format
    # Note: this will incur a db call.  Without it, permissions
    # refuse to function.
    def as_warehouse
      warehouse_class = "GrdaWarehouse::Hud::#{self.class.name.demodulize}".constantize
      warehouse_class.find(id)
    end

    # Classes that use EnrollmentID + PersonalID composite keys to associate with enrollments.
    # Includes both HUD-defined and custom record types that follow this association pattern.
    def self.enrollment_personal_id_keyed_class_names
      [
        'Disability',
        'EmploymentEducation',
        'Exit',
        'HealthAndDv',
        'IncomeBenefit',
        'Service',
        'CurrentLivingSituation',
        'Assessment',
        'AssessmentQuestion',
        'AssessmentResult',
        'Event',
        'YouthEducationStatus',
        'CustomAssessment',
        'CustomCaseNote',
        'CustomService',
      ].freeze
    end

    def self.hud_class_names
      [
        *enrollment_personal_id_keyed_class_names.filter { |name| !name.start_with?('Custom') },
        'Export',
        'Organization',
        'Project',
        'Client',
        'Enrollment',
        'HmisParticipation',
        'CeParticipation',
        'Funder',
        'Inventory',
        'ProjectCoc',
        'Affiliation',
        'User',
      ].freeze
    end

    def self.hmis_enrollment_related_classes
      enrollment_personal_id_keyed_class_names.map do |name|
        "Hmis::Hud::#{name}".constantize
      end
    end

    def self.hmis_classes
      hud_class_names.map do |name|
        "Hmis::Hud::#{name}".constantize
      end
    end
  end
end
