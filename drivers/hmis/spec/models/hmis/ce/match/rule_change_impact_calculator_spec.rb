# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::RuleChangeImpactCalculator do
  let(:current_date) { Date.new(2024, 12, 26) }
  let!(:candidate_pool) { create(:hmis_ce_match_candidate_pool, requirement_expression: 'TRUE', priority_expression: '{1}') }

  let!(:organization) { create(:hmis_hud_organization) }
  let!(:project) { create(:hmis_hud_project, organization: organization) }
  let!(:unit_group) { create(:hmis_unit_group, project: project, candidate_pool: candidate_pool) }

  let!(:client1) { create(:hmis_hud_client_with_warehouse_client, dob: 30.years.ago(current_date), veteran_status: 1) }
  let!(:client2) { create(:hmis_hud_client_with_warehouse_client, dob: 30.years.ago(current_date), veteran_status: 0) }
  let!(:client3) { create(:hmis_hud_client_with_warehouse_client, dob: 30.years.ago(current_date), veteran_status: 0) }

  let!(:candidate1) { create(:hmis_ce_match_candidate, candidate_pool: candidate_pool, client: client1.destination_client) }
  let!(:candidate2) { create(:hmis_ce_match_candidate, candidate_pool: candidate_pool, client: client2.destination_client) }
  let!(:candidate3) { create(:hmis_ce_match_candidate, candidate_pool: candidate_pool, client: client3.destination_client) }

  describe '.for_create' do
    it 'counts candidates that would be removed by the proposed requirement' do
      rule = build(:hmis_ce_eligibility_requirement, owner: project, expression: 'veteran_status = 1')
      result = described_class.for_create(rule: rule)

      expect(result.affected_unit_groups.size).to eq(1)

      impact = result.affected_unit_groups.first
      expect(impact.unit_group).to eq(unit_group)
      expect(impact.current_candidate_count).to eq(3)
      expect(impact.removed_candidate_count).to eq(2)
    end

    it 'returns zero removals when all current candidates pass the proposed requirement' do
      rule = build(:hmis_ce_eligibility_requirement, owner: project, expression: 'current_age >= 18')
      result = described_class.for_create(rule: rule)

      impact = result.affected_unit_groups.first
      expect(impact.removed_candidate_count).to eq(0)
    end

    it 'skips unit groups without a candidate pool' do
      unit_group.update!(candidate_pool: nil)

      rule = build(:hmis_ce_eligibility_requirement, owner: project, expression: 'veteran_status = 1')
      result = described_class.for_create(rule: rule)

      expect(result.affected_unit_groups).to be_empty
    end

    context 'with applicability_config filters' do
      let!(:other_project) { create(:hmis_hud_project, organization: organization, project_type: 4) }
      let!(:other_unit_group) { create(:hmis_unit_group, project: other_project, candidate_pool: other_pool) }
      let!(:other_pool) { create(:hmis_ce_match_candidate_pool, requirement_expression: 'TRUE', priority_expression: '{2}') }

      let!(:client4) { create(:hmis_hud_client_with_warehouse_client, dob: 30.years.ago(current_date), veteran_status: 0) }
      let!(:candidate4) { create(:hmis_ce_match_candidate, candidate_pool: other_pool, client: client4.destination_client) }

      it 'only includes unit groups matching project type constraints' do
        rule = build(
          :hmis_ce_eligibility_requirement,
          owner: organization,
          expression: 'veteran_status = 1',
          applicability_config: { project_types: [project.project_type] },
        )
        result = described_class.for_create(rule: rule)

        unit_group_ids = result.affected_unit_groups.map(&:unit_group)
        expect(unit_group_ids).to contain_exactly(unit_group)
      end
    end

    context 'when the proposed rule is a priority scheme' do
      it 'raises' do
        rule = build(:hmis_ce_priority_scheme, owner: project, expression: 'current_age')

        expect { described_class.for_create(rule: rule) }.to raise_error(ArgumentError, /priority scheme impact preview is not supported/)
      end
    end
  end
end
