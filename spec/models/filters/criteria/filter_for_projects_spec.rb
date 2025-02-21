require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe Filters::Criteria::FilterForProjects do
  include_context 'filter criteria setup'

  let(:project_ids) { [] }
  let(:project_group_ids) { [] }
  let(:filter) do
    ::Filters::FilterBase.new(
      user_id: user.id,
      project_ids: project_ids,
      project_group_ids: project_group_ids,
    )
  end
  let(:criteria) { described_class.new(input: filter, config: config) }

  # Create additional projects and groups
  let!(:project2) { create_project }
  let!(:project3) { create_project }
  let!(:project_group) { create(:project_group, projects: [project2, project3]) }

  let!(:enrollments) do
    [
      create_enrollment_for_client(create(:hud_client), project_id: project.ProjectID),
      create_enrollment_for_client(create(:hud_client), project_id: project2.ProjectID),
      create_enrollment_for_client(create(:hud_client), project_id: project3.ProjectID),
    ]
  end

  it_behaves_like 'a criteria that applies conditionally', :project_ids, [1]

  describe '#apply' do
    context 'with project_ids' do
      let(:project_ids) { [project.id, project2.id] }

      it 'filters by selected projects' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[0].id, enrollments[1].id)
      end
    end

    context 'with project_group_ids' do
      let(:project_group_ids) { [project_group.id] }

      it 'filters by projects in the selected groups' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[1].id, enrollments[2].id)
      end
    end

    context 'when user cannot view project_ids' do
      let(:role) do
        create(:role, can_view_project_related_filters: false)
      end
      before { allow(user).to receive(:report_filter_visible?).with(:project_ids).and_return(false) }
      let(:project_ids) { [project.id] }

      it 'ignores project_ids filter' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(*enrollments.map(&:id))
      end
    end
  end
end
