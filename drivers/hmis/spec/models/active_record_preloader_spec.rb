# frozen_string_literal: true

require 'rails_helper'

#  testing preloader behavior
RSpec.describe Sources::ActiveRecordAssociation do
  describe 'preloader behavior' do
    let!(:data_source) { create(:hmis_data_source) }
    let!(:project) { create(:hmis_hud_project, data_source: data_source) }
    let!(:project2) { create(:hmis_hud_project, data_source: data_source) }
    let!(:enrollment) { create(:hmis_hud_enrollment, data_source: data_source, project: project) }
    let!(:enrollment2) { create(:hmis_hud_enrollment, data_source: data_source, project: project) }
    let!(:assessment) { create(:hmis_custom_assessment, data_source: data_source, enrollment: enrollment) }
    let!(:assessment2) { create(:hmis_custom_assessment, data_source: data_source, enrollment: enrollment2) }

    def capture_sql_queries
      queries = []
      callback = ->(*, payload) { queries << payload[:sql] }

      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
        yield
      end

      queries
    end

    shared_examples 'has loaded association' do |record, association|
      it "has loaded #{association} association" do
        expect(record.association(association).loaded?).to be true
      end
    end

    it 'handles multiple preloads without unscoped queries' do
      records = [Hmis::Hud::CustomAssessment.find(assessment.id)]

      # Warm up connections and table name caches
      [Hmis::Hud::Project, Hmis::Hud::Enrollment, Hmis::Hud::CustomAssessment].each(&:connection)

      queries = capture_sql_queries do
        ActiveRecord::Associations::Preloader.new(records: records, associations: :project).call
        ActiveRecord::Associations::Preloader.new(records: records, associations: :enrollment).call
      end

      enrollment_queries = queries.grep(/"Enrollment" WHERE.*"EnrollmentID" = \$1/)
      expect(enrollment_queries.size).to eq(1)
      project_queries = queries.grep(/Project.*WHERE.*"Project"."id" = \$1/)
      expect(project_queries.size).to eq(1)
      expect(records.first.project).to eq(project)
      expect(records.first.enrollment).to eq(enrollment)
    end

    it 'handles single preload with multiple associations' do
      records = [Hmis::Hud::CustomAssessment.find(assessment.id)]

      queries = capture_sql_queries do
        ActiveRecord::Associations::Preloader.new(records: records, associations: [:project, :enrollment]).call
      end

      enrollment_queries = queries.grep(/"Enrollment" WHERE.*"EnrollmentID" = \$1/)
      expect(enrollment_queries.size).to eq(1)
      project_queries = queries.grep(/Project.*WHERE.*"Project"."id" = \$1/)
      expect(project_queries.size).to eq(1)
      expect(records.first.project).to eq(project)
      expect(records.first.enrollment).to eq(enrollment)
    end

    it 'honors scopes when preloading associations' do
      records = [project]
      scope = Hmis::Hud::Enrollment.where(id: enrollment.id)

      queries = capture_sql_queries do
        ActiveRecord::Associations::Preloader.new(records: records, associations: :enrollments, scope: scope).call
      end

      enrollment_queries = queries.grep(/Enrollment.*WHERE/)
      expect(enrollment_queries.size).to eq(1)
      expect(queries.any? { |q| q.include?('WHERE') && q.include?('"id" = $1') }).to be true
      expect(records.first.enrollments).to include(enrollment)
      expect(records.first.enrollments.size).to eq(1) # Only the scoped enrollment should be loaded
    end

    it 'preloads has_many associations correctly' do
      records = [project]

      queries = capture_sql_queries do
        ActiveRecord::Associations::Preloader.new(records: records, associations: :enrollments).call
      end

      enrollment_queries = queries.grep(/Enrollment.*WHERE.*"project_pk" = \$1/)
      expect(enrollment_queries.size).to eq(1)
      expect(records.first.association(:enrollments).loaded?).to be true
      expect(records.first.enrollments).to include(enrollment, enrollment2)
      expect(records.first.enrollments.size).to eq(2)
    end

    it 'handles nested association preloading' do
      records = [assessment]

      capture_sql_queries do
        ActiveRecord::Associations::Preloader.new(
          records: records,
          associations: { enrollment: :project },
        ).call
      end

      expect(records.first.association(:enrollment).loaded?).to be true
      expect(records.first.enrollment.association(:project).loaded?).to be true
      expect(records.first.enrollment.project).to eq(project)
    end

    describe 'Sources::ActiveRecordAssociation' do
      let(:test_record) { assessment }

      it 'loads associations and returns results via Source' do
        source = Sources::ActiveRecordAssociation.new(:project)
        records = [test_record]

        results = source.fetch(records)

        expect(results).to eq([project])
        expect(test_record.association(:project).loaded?).to be true
      end

      it 'raises error for non-symbol association names via Source' do
        expect do
          Sources::ActiveRecordAssociation.new('project')
        end.to raise_error(/association must be symbol/)
      end

      it 'respects custom scopes via Source' do
        scope = Hmis::Hud::Project.where(id: project.id)
        source = Sources::ActiveRecordAssociation.new(:project, scope)
        records = [test_record]

        results = source.fetch(records)

        expect(results).to eq([project])
        expect(test_record.association(:project).loaded?).to be true
      end

      it 'generates appropriate batch keys' do
        scope = Hmis::Hud::Project.where(id: 1)
        key1 = Sources::ActiveRecordAssociation.batch_key_for(:project)
        key2 = Sources::ActiveRecordAssociation.batch_key_for(:project, scope)

        expect(key1).to eq([:project])
        expect(key2).not_to eq(key1)
        expect(key2).to eq([:project, scope.to_sql])
      end
    end

    # Test for performance with large record sets
    it 'efficiently preloads large record sets' do
      # Create a larger dataset
      5.times.map do |_i|
        create(:hmis_hud_enrollment, data_source: data_source, project: project2)
      end
      create(:hmis_hud_enrollment, data_source: data_source, project: project)
      additional_assessments = 10.times.map do |i|
        current_enrollment = i.even? ? enrollment : enrollment2
        create(:hmis_custom_assessment, data_source: data_source, enrollment: current_enrollment)
      end

      all_records = [assessment, assessment2] + additional_assessments

      all_records.map(&:reload)
      queries = capture_sql_queries do
        ActiveRecord::Associations::Preloader.new(records: all_records, associations: :enrollment).call
        all_records.first
        ActiveRecord::Associations::Preloader.new(records: all_records.map(&:enrollment).compact.uniq, associations: :project).call
        all_records.first.enrollment
      end

      enrollment_queries = queries.grep(/Enrollment.*WHERE.*"EnrollmentID" IN/)
      expect(enrollment_queries.size).to eq(1), "Expected 1 enrollment query, got #{enrollment_queries.size}"

      project_queries = queries.grep(/Project.*WHERE.*"Project"."id" IN/)
      expect(project_queries.size).to be <= 1, "Expected at most 1 project query, got #{project_queries.size}"

      # All records should have their associations loaded
      expect(all_records.all? { |r| r.association(:enrollment).loaded? }).to be true
      expect(all_records.map(&:enrollment).compact.all? { |e| e.association(:project).loaded? }).to be true
    end
  end
end
