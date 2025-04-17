require 'rails_helper'

RSpec.describe Sources::ActiveRecordAssociation do
  describe 'preloader behavior' do
    let!(:data_source) { create(:hmis_data_source) }
    let!(:project) { create(:hmis_hud_project, data_source: data_source) }
    let!(:project2) { create(:hmis_hud_project, data_source: data_source) }
    let!(:enrollment) { create(:hmis_hud_enrollment, data_source: data_source, project: project) }
    let!(:enrollment2) { create(:hmis_hud_enrollment, data_source: data_source, project: project) }
    let!(:assessment) { create(:hmis_custom_assessment, data_source: data_source, enrollment: enrollment) }
    let!(:assessment2) { create(:hmis_custom_assessment, data_source: data_source, enrollment: enrollment2) }

    it 'handles multiple preloads without unscoped queries' do
      records = [Hmis::Hud::CustomAssessment.find(assessment.id)]

      # Warm up connections and table name caches
      [Hmis::Hud::Project, Hmis::Hud::Enrollment, Hmis::Hud::CustomAssessment].each(&:connection)

      queries = []
      callback = ->(*, payload) { queries << payload[:sql] }

      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
        ActiveRecord::Associations::Preloader.new(records: records, associations: :project).call
        ActiveRecord::Associations::Preloader.new(records: records, associations: :enrollment).call
      end

      enrollment_queries = queries.grep /"Enrollment".*WHERE.*"EnrollmentID" = '#{enrollment.enrollment_id}'/
      expect(enrollment_queries.size).to eq(1)
      project_queries = queries.grep /Project.*WHERE.*"Project"."id" = /
      expect(project_queries.size).to eq(1)
      expect(records.first.project).to eq(project)
      expect(records.first.enrollment).to eq(enrollment)
    end

    it 'handles single preload with multiple associations' do
      records = [Hmis::Hud::CustomAssessment.find(assessment.id)]

      queries = []
      callback = ->(*, payload) { queries << payload[:sql] }

      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
        ActiveRecord::Associations::Preloader.new(records: records, associations: [:project, :enrollment]).call
      end

      enrollment_queries = queries.grep /"Enrollment".*WHERE.*"EnrollmentID" = '#{enrollment.enrollment_id}'/
      expect(enrollment_queries.size).to eq(1)
      project_queries = queries.grep /Project.*WHERE.*"Project"."id" = /
      expect(project_queries.size).to eq(1)
      expect(records.first.project).to eq(project)
      expect(records.first.enrollment).to eq(enrollment)
    end
  end
end
