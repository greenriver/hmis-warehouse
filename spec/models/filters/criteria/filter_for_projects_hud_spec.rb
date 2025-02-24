require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe Filters::Criteria::FilterForProjectsHud do
  include_context 'filter criteria setup'

  let(:project_ids) { [project.id] }
  let(:filter) { ::Filters::FilterBase.new(user_id: user.id, project_ids: project_ids) }
  let(:criteria) { described_class.new(input: filter, config: config) }

  # Create projects and enrollments
  let!(:project2) { create_project }
  let!(:project3) { create_project(confidential: true) }

  let!(:enrollments) do
    [
      # Enrollment in the selected project
      create_enrollment_for_client(create(:hud_client), project_id: project.ProjectID),
      # Enrollment in another project
      create_enrollment_for_client(create(:hud_client), project_id: project2.ProjectID),
      # Enrollment in a confidential project
      create_enrollment_for_client(create(:hud_client), project_id: project3.ProjectID),
    ]
  end

  it_behaves_like 'a criteria that applies conditionally', :project_ids, [1]

  describe '#apply' do
    it 'returns enrollments from selected projects only' do
      result = criteria.apply(scope)
      expect(result.pluck(:id)).to contain_exactly(enrollments[0].id)
    end

    it 'filters out enrollments from projects the user cannot view' do
      # Make all projects confidential
      project.update(confidential: true)

      # User should not see any enrollments
      result = criteria.apply(scope)
      expect(result).to be_empty
    end

    context 'with multiple project ids' do
      let(:project_ids) { [project.id, project2.id] }

      it 'returns enrollments from all selected projects' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[0].id, enrollments[1].id)
      end
    end

    context 'with no project ids' do
      let(:project_ids) { [] }

      it 'applies? returns false' do
        expect(criteria.applies?).to be false
      end
    end
  end
end
