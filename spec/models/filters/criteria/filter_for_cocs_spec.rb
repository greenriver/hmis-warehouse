###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe Filters::Criteria::FilterForCocs do
  include_context 'filter criteria setup'

  let(:filter) { ::Filters::FilterBase.new(user_id: user.id, coc_codes: ['MA-500']) }
  let(:criteria) { described_class.new(input: filter, config: config) }
  let!(:other_project) { create_project }

  let!(:selected_enrollment) do
    create_enrollment_for_client(create(:hud_client), enrollment_attributes: { EnrollmentCoC: 'MA-500' })
  end
  let!(:other_enrollment) do
    create_enrollment_for_client(
      create(:hud_client),
      project_id: other_project.ProjectID,
      enrollment_attributes: { EnrollmentCoC: 'MA-500' },
    )
  end

  before do
    # two ProjectCoC rows in the selected CoC, as with one row per geocode
    create(:hud_project_coc, project: project, CoCCode: 'MA-500', data_source: data_source)
    create(:hud_project_coc, project: project, CoCCode: 'MA-500', data_source: data_source)
    create(:hud_project_coc, project: other_project, CoCCode: 'MA-501', data_source: data_source)
  end

  it_behaves_like 'a criteria that applies conditionally', :coc_codes, ['MA-500']

  describe '#apply' do
    it 'returns each enrollment once when its project has two ProjectCoC rows in the selected CoC' do
      expect(criteria.apply(scope).pluck(:id)).to eq([selected_enrollment.id])
    end

    it 'excludes enrollments whose project has no ProjectCoC in the selected CoCs' do
      expect(scope.pluck(:id)).to contain_exactly(selected_enrollment.id, other_enrollment.id)
      expect(criteria.apply(scope).pluck(:id)).to contain_exactly(selected_enrollment.id)
    end

    it 'keeps the CoC restriction when a project filter is applied afterward' do
      project_filter = ::Filters::FilterBase.new(user_id: user.id, coc_codes: ['MA-500'], project_ids: [other_project.id])
      projects_criteria = Filters::Criteria::FilterForProjects.new(input: project_filter, config: config)

      expect(projects_criteria.apply(scope).pluck(:id)).to contain_exactly(other_enrollment.id)
      expect(projects_criteria.apply(criteria.apply(scope)).pluck(:id)).to eq([])
    end
  end
end
