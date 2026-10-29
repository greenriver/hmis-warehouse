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

  it_behaves_like 'a criteria that always applies'

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

    it 'returns every enrollment when no CoC is chosen' do
      no_coc_criteria = described_class.new(input: ::Filters::FilterBase.new(user_id: user.id), config: config)

      expect(no_coc_criteria.apply(scope).pluck(:id)).to contain_exactly(selected_enrollment.id, other_enrollment.id)
    end
  end

  describe 'ProjectCoC join guard' do
    let(:no_coc_criteria) { described_class.new(input: ::Filters::FilterBase.new(user_id: user.id), config: config) }
    let(:guard_error) { described_class::UnlimitedProjectCocJoin }

    it 'raises on joins through project to project_cocs, with or without selected CoCs' do
      expect { criteria.apply(scope).joins(project: :project_cocs) }.to raise_error(guard_error)
      expect { no_coc_criteria.apply(scope).joins(:client, project: :project_cocs) }.to raise_error(guard_error)
    end

    it 'raises on left_outer_joins through project to project_cocs' do
      expect { criteria.apply(scope).left_outer_joins(project: :project_cocs) }.to raise_error(guard_error)
    end

    it 'raises when the join arrives through merge' do
      expect { criteria.apply(scope).merge(GrdaWarehouse::ServiceHistoryEnrollment.joins(project: :project_cocs)) }.
        to raise_error(guard_error)
    end

    it 'allows other joins' do
      expect(criteria.apply(scope).joins(:project, :client).pluck(:id)).to eq([selected_enrollment.id])
    end

    it 'allows joins_project_cocs, which keeps only the selected CoCs' do
      create(:hud_project_coc, project: project, CoCCode: 'MA-501', data_source: data_source)

      coc_codes = criteria.apply(scope).joins_project_cocs(coc_codes: ['MA-500']).
        pluck(GrdaWarehouse::Hud::ProjectCoc.arel_table[:CoCCode])

      expect(coc_codes).to eq(['MA-500', 'MA-500'])
    end

    it 'allows the ServiceHistoryEnrollment in_coc, in_zip and in_place scopes' do
      create(:hud_project_coc, project: other_project, CoCCode: 'MA-500', Zip: '01001', City: 'Agawam', data_source: data_source)
      filtered = criteria.apply(scope)

      expect(filtered.in_coc(coc_code: 'MA-500').distinct.pluck(:id)).to contain_exactly(selected_enrollment.id, other_enrollment.id)
      expect(filtered.in_zip(zip_code: '01001').pluck(:id)).to eq([other_enrollment.id])
      expect(filtered.in_place(place: 'agawam').pluck(:id)).to eq([other_enrollment.id])
    end
  end

  describe 'ServiceHistoryEnrollment.joins_project_cocs' do
    it 'keeps every non-deleted ProjectCoC row when no CoC is given' do
      create(:hud_project_coc, project: project, CoCCode: 'MA-502', data_source: data_source).destroy

      coc_codes = scope.where(id: selected_enrollment.id).joins_project_cocs(coc_codes: []).
        pluck(GrdaWarehouse::Hud::ProjectCoc.arel_table[:CoCCode])

      expect(coc_codes).to eq(['MA-500', 'MA-500'])
    end
  end
end
