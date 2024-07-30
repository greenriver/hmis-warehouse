###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SyntheticCeAssessment
  class EnrollmentCeAssessment < ::GrdaWarehouse::Synthetic::Assessment
    include ArelHelper

    validates_presence_of :source

    def assessment_date
      source.entry_date
    end

    def assessment_location
      source.project.project_id
    end

    def assessment_type
      source.project.synthetic_ce_project_config&.assessment_type
    end

    def assessment_level
      source.project.synthetic_ce_project_config&.assessment_level
    end

    def prioritization_status
      source.project.synthetic_ce_project_config&.prioritization_status
    end

    def data_source
      # TODO: is this correct? or should it be source.data_source or something else?
      'Enrollment CE Assessment'
    end

    def self.sync
      remove_orphans
      add_new
    end

    def self.remove_orphans
      active_ids = active_source_scope.pluck(:id)
      orphan_ids = pluck(:source_id) - active_ids
      return unless orphan_ids.present?

      where(source_id: orphan_ids).delete_all
    end

    def self.add_new
      active_source_scope.preload(:client).where.not(id: self.select(:source_id)).find_each do |enrollment|
        create(enrollment: enrollment, client: enrollment.client, source: enrollment)
      end
    end

    def self.active_source_scope
      ::GrdaWarehouse::Hud::Enrollment.
        joins(project: :synthetic_ce_project_config).
        merge(SyntheticCeAssessment::ProjectConfig.active)
    end

    private def created_at_from(source)
      source.DateCreated
    end

    private def updated_at_from(source)
      source.DateUpdated
    end
  end
end
