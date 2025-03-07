# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_filter_criteria_context'

RSpec.describe Filters::Criteria::FilterForProjectType do
  include_context 'filter criteria setup'

  let(:project_type_ids) { [1, 2] } # Emergency Shelter and Transitional Housing
  let(:config_project_types) { nil }
  let(:ce_as_homeless) { false }

  let(:filter) do
    ::Filters::FilterBase.new(
      user_id: user.id,
      # note, filter base is doing input mangling here, there's several inputs that apply to project_type_ids
      project_type_numbers: project_type_ids,
      coordinated_assessment_living_situation_homeless: ce_as_homeless,
    )
  end

  let(:criteria) do
    described_class.new(
      input: filter,
      config: Filters::Criteria::Configuration.new(
        project_types: config_project_types,
        all_project_types: nil,
      ),
    )
  end

  let!(:enrollments) do
    [
      # Emergency Shelter enrollment
      create_enrollment_for_client(create(:hud_client), project_type: 1),
      # Transitional Housing enrollment
      create_enrollment_for_client(create(:hud_client), project_type: 2),
      # Permanent Housing enrollment
      create_enrollment_for_client(create(:hud_client), project_type: 3),
      # Coordinated Entry enrollment
      create_enrollment_for_client(create(:hud_client), project_type: 14),
    ]
  end

  it_behaves_like 'a criteria that applies conditionally', :project_type_numbers, [1, 2], { default_project_type_codes: [] }

  describe '#apply' do
    it 'filters by selected project types' do
      result = criteria.apply(scope)
      expect(result.pluck(:id)).to contain_exactly(enrollments[0].id, enrollments[1].id)
    end

    context 'with config-specified project types' do
      let(:config_project_types) { [2, 3] }

      it 'uses config project types instead of filter types' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to contain_exactly(enrollments[1].id, enrollments[2].id)
      end
    end

    context 'with coordinated entry as homeless' do
      let(:ce_as_homeless) { true }

      it 'includes coordinated entry projects' do
        result = criteria.apply(scope)
        expect(result.pluck(:id)).to include(enrollments[3].id)
      end
    end
  end
end
