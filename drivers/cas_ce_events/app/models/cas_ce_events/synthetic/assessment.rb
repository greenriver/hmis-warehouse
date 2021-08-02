###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CasCeEvents::Synthetic
  class Assessment < ::GrdaWarehouse::Synthetic::Assessment
    include ArelHelper

    validates_presence_of :source

    delegate :assessment_date, to: :source
    delegate :assessment_location, to: :source
    delegate :assessment_type, to: :source

    def self.sync
      remove_orphans
      add_new
    end

    def self.remove_orphans
      orphan_ids = pluck(:source_id) - CasCeEvents::GrdaWarehouse::CasCeAssessment.pluck(:id)
      return unless orphan_ids.present?

      where(source_id: orphan_ids).delete_all
    end

    def self.add_new
      new_assessments = CasCeEvents::GrdaWarehouse::CasCeAssessment.where.not(id: self.select(:source_id))
      new_assessments.find_each do |assessment|
        next unless assessment.client.present?

        create(enrollment: find_enrollment(assessment), client: assessment.client, source: assessment)
      end
    end

    def self.find_enrollment(assessment)
      assessment.client.source_enrollments.
        joins(:project).
        where(p_t[:id].in(assessment.projects.pluck(:project_id))).
        open_on_date(assessment.assessment_date).
        first
    end
  end
end
