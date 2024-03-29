###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Hud::Concerns::Shared
  extend ActiveSupport::Concern
  include Hmis::Hud::Concerns::HasEnums
  include ::HmisStructure::Shared

  included do
    # Filter down scope to only HMIS records. Helpful for finding records in the
    # rails console for single-HMIS installatinos, but should not be used otherwise
    # (because it does not take _which_ HMIS into account).
    scope :hmis, -> do
      joins(:data_source).merge(GrdaWarehouse::DataSource.hmis)
    end

    def as_warehouse
      "GrdaWarehouse::Hud::#{self.class.name.demodulize}".constantize.find(id)
    end

    def self.enrollment_related_hud_class_names
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
      ].freeze
    end

    def self.hud_class_names
      [
        *enrollment_related_hud_class_names,
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
      enrollment_related_hud_class_names.map do |name|
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
