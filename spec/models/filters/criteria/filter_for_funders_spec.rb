# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe Filters::Criteria::FilterForFunders do
  include_context 'filter criteria setup'

  let(:funder_ids) { [] }
  let(:funder_others) { [] }
  let(:filter) do
    ::Filters::FilterBase.new(
      user_id: user.id,
      funder_ids: funder_ids,
      funder_others: funder_others,
    )
  end
  let(:criteria) { described_class.new(input: filter, config: config) }

  # Create projects with different funders
  let!(:project_with_funder1) { create_project }
  let!(:project_with_funder2) { create_project }
  let!(:project_with_other_funder) { create_project }

  # Create funders for each project
  let!(:funder1) do
    create(
      :hud_funder,
      data_source_id: data_source.id,
      ProjectID: project_with_funder1.ProjectID,
      Funder: 2, # HUD:CoC
      OtherFunder: nil,
    )
  end

  let!(:funder2) do
    create(
      :hud_funder,
      data_source_id: data_source.id,
      ProjectID: project_with_funder2.ProjectID,
      Funder: 10, # Other federal
      OtherFunder: nil,
    )
  end

  let!(:other_funder) do
    create(
      :hud_funder,
      data_source_id: data_source.id,
      ProjectID: project_with_other_funder.ProjectID,
      Funder: 17, # Other
      OtherFunder: 'Local Foundation',
    )
  end

  let!(:enrollments) do
    [
      create_enrollment_for_client(create(:hud_client), project_id: project_with_funder1.ProjectID),
      create_enrollment_for_client(create(:hud_client), project_id: project_with_funder2.ProjectID),
      create_enrollment_for_client(create(:hud_client), project_id: project_with_other_funder.ProjectID),
    ]
  end

  describe '#apply' do
    context 'when filtering by specific funder IDs' do
      let(:funder_ids) { [2] } # HUD:CoC

      it 'returns enrollments from projects with matching funders' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[0].id)
      end
    end

    context 'when filtering by multiple funder IDs' do
      let(:funder_ids) { [2, 10] } # HUD:CoC and Other federal

      it 'returns enrollments from projects with any matching funders' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[0].id, enrollments[1].id)
      end
    end

    context 'when filtering by other funder texts' do
      let(:funder_others) { ['Local Foundation'] }

      it 'returns enrollments from projects with matching other funders' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[2].id)
      end
    end
  end
end
