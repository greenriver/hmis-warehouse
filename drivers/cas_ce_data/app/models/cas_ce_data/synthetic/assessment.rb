###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CasCeData::Synthetic
  class Assessment < ::GrdaWarehouse::Synthetic::Assessment
    include ArelHelper

    validates_presence_of :source

    delegate :assessment_date, to: :source
    delegate :assessment_location, to: :source
    delegate :assessment_type, to: :source
    delegate :assessment_level, to: :source
    delegate :assessment_status, to: :source
    alias prioritization_status assessment_status

    def data_source
      'CAS'
    end

    def self.sync
      remove_orphans
      add_new
    end

    def self.remove_orphans
      orphan_ids = pluck(:source_id) - CasCeData::GrdaWarehouse::CasCeAssessment.pluck(:id)
      return unless orphan_ids.present?

      where(source_id: orphan_ids).delete_all
    end

    def self.add_new
      new_assessments = CasCeData::GrdaWarehouse::CasCeAssessment.where.not(id: self.select(:source_id))
      new_assessments.find_each do |assessment|
        next unless assessment.client.present?

        enrollment = find_enrollment(assessment)
        create(enrollment: enrollment, client: assessment.client, source: assessment) if enrollment.present?
      end
    end

    def self.find_enrollment(assessment)
      scope = assessment.client.source_enrollments.
        open_on_date(assessment.assessment_date).
        order(EntryDate: :desc)
      if assessment.projects.exists?
        scope = scope.joins(:project).
          where(p_t[:id].in(assessment.projects.pluck(:project_id)))
      end
      scope.first
    end
  end
end
