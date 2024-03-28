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

    # Most likely you don't need the extra db call issued with a reload
    # leaving it as the default behavior for now to preserve backwards compatibility
    def as_warehouse(force_reload: true)
      warehouse_class = "GrdaWarehouse::Hud::#{self.class.name.demodulize}".constantize
      columns = self.class.column_names - warehouse_class.ignored_columns
      warehouse_entity = warehouse_class.new(attributes.slice(*columns))
      return warehouse_entity unless force_reload

      warehouse_entity.reload
    end

    def self.hud_class_names
      [
        'Export',
        'Organization',
        'Project',
        'Client',
        'Disability',
        'EmploymentEducation',
        'Enrollment',
        'HmisParticipation',
        'CeParticipation',
        'Exit',
        'Funder',
        'HealthAndDv',
        'IncomeBenefit',
        'Inventory',
        'ProjectCoc',
        'Affiliation',
        'Service',
        'CurrentLivingSituation',
        'Assessment',
        'AssessmentQuestion',
        'AssessmentResult',
        'Event',
        'User',
        'YouthEducationStatus',
      ].freeze
    end

    def self.hmis_classes
      hud_class_names.map do |name|
        "Hmis::Hud::#{name}".constantize
      end
    end
  end
end
