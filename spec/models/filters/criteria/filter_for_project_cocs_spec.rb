# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe Filters::Criteria::FilterForProjectCocs do
  include_context 'filter criteria setup'

  let(:coc_codes) { ['MA-500', 'NY-600'] }
  let(:filter) { ::Filters::FilterBase.new(user_id: user.id, coc_codes: coc_codes) }
  let(:criteria) { described_class.new(input: filter, config: config) }

  let!(:enrollments) do
    [
      # Enrollment in MA-500 CoC
      create_enrollment_for_client(create(:hud_client), project_id: project.ProjectID, data_source: data_source),
      # Enrollment in NY-600 CoC
      create_enrollment_for_client(create(:hud_client), project_id: project2.ProjectID, data_source: data_source),
      # Enrollment in different CoC
      create_enrollment_for_client(create(:hud_client), project_id: project3.ProjectID, data_source: data_source),
    ]
  end

  let!(:project2) { create_project }
  let!(:project3) { create_project }

  before do
    # Create ProjectCoC records
    create(:hud_project_coc, project: project, CoCCode: 'MA-500', data_source: data_source)
    create(:hud_project_coc, project: project2, CoCCode: 'NY-600', data_source: data_source)
    create(:hud_project_coc, project: project3, CoCCode: 'CA-500', data_source: data_source)
  end

  it_behaves_like 'a criteria that always applies'

  describe '#apply' do
    it 'returns enrollments from projects in selected CoCs' do
      result = criteria.apply(scope)
      expect(result.pluck(:id)).to contain_exactly(enrollments[0].id, enrollments[1].id)
    end
  end
end
