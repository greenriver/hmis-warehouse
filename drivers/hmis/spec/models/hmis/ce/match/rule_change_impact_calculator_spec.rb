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

  describe '.for_rule' do
    it 'counts candidates that would be removed by the proposed requirement' do
      rule = build(:hmis_ce_eligibility_requirement, owner: project, expression: 'veteran_status = 1')
      result = described_class.for_rule(rule: rule)

      expect(result.affected_unit_groups.size).to eq(1)

      impact = result.affected_unit_groups.first
      expect(impact.unit_group).to eq(unit_group)
      expect(impact.current_candidate_count).to eq(3)
      expect(impact.removed_candidate_count).to eq(2)
    end

    it 'returns zero removals when all current candidates pass the proposed requirement' do
      rule = build(:hmis_ce_eligibility_requirement, owner: project, expression: 'current_age >= 18')
      result = described_class.for_rule(rule: rule)

      impact = result.affected_unit_groups.first
      expect(impact.removed_candidate_count).to eq(0)
    end

    it 'skips unit groups without a candidate pool' do
      unit_group.update!(candidate_pool: nil)

      rule = build(:hmis_ce_eligibility_requirement, owner: project, expression: 'veteran_status = 1')
      result = described_class.for_rule(rule: rule)

      expect(result.affected_unit_groups).to be_empty
    end

    context 'with a project_types applicability_config filter' do
      let!(:other_project) { create(:hmis_hud_project, organization: organization, project_type: 4) }
      let!(:other_pool) { create(:hmis_ce_match_candidate_pool, requirement_expression: 'TRUE', priority_expression: '{2}') }
      let!(:other_unit_group) { create(:hmis_unit_group, project: other_project, candidate_pool: other_pool) }

      it 'includes only unit groups whose project type matches' do
        rule = build(
          :hmis_ce_eligibility_requirement,
          owner: organization,
          expression: 'veteran_status = 1',
          applicability_config: { project_types: [project.project_type] },
        )
        result = described_class.for_rule(rule: rule)

        unit_groups = result.affected_unit_groups.map(&:unit_group)
        expect(unit_groups).to contain_exactly(unit_group)
      end
    end

    context 'with a project_funders applicability_config filter' do
      let!(:other_project) { create(:hmis_hud_project, organization: organization, funders: [50]) }
      let!(:other_pool) { create(:hmis_ce_match_candidate_pool, requirement_expression: 'TRUE', priority_expression: '{2}') }
      let!(:other_unit_group) { create(:hmis_unit_group, project: other_project, candidate_pool: other_pool) }

      it 'includes only unit groups whose project has a matching funder' do
        # `project` has no funders; `other_project` is funded by 50.
        rule = build(
          :hmis_ce_eligibility_requirement,
          owner: organization,
          expression: 'veteran_status = 1',
          applicability_config: { project_funders: [50] },
        )
        result = described_class.for_rule(rule: rule)

        unit_groups = result.affected_unit_groups.map(&:unit_group)
        expect(unit_groups).to contain_exactly(other_unit_group)
      end
    end

    context 'with a CDE field expression' do
      let!(:hmis_data_source) { project.data_source }
      let!(:form_definition) { create(:hmis_form_definition, identifier: 'eligibility_form', data_source: hmis_data_source) }
      let!(:cded) do
        create(
          :hmis_custom_data_element_definition,
          owner_type: 'Hmis::Hud::CustomAssessment',
          key: 'eligible_for_program',
          field_type: 'string',
          form_definition_identifier: 'eligibility_form',
          data_source: hmis_data_source,
        )
      end

      let(:new_rule) { build(:hmis_ce_eligibility_requirement, owner: project, expression: '`cde.custom_assessment.eligible_for_program` = "yes"') }

      it 'evaluates the proposed expression against CDE values without raising' do
        result = described_class.for_rule(rule: new_rule)

        impact = result.affected_unit_groups.first
        # No CDE values exist for any candidate, so the expression evaluates to nil
        # for all of them and they all get removed.
        expect(impact.removed_candidate_count).to eq(impact.current_candidate_count)
      end

      context 'when a candidate has a matching CDE value' do
        # Create a source client on the same data source as the form / CDE definition
        let!(:eligible_source_client) { create(:hmis_hud_client_with_warehouse_client, data_source: hmis_data_source) }
        let!(:eligible_candidate) { create(:hmis_ce_match_candidate, candidate_pool: candidate_pool, client: eligible_source_client.destination_client) }
        let!(:custom_assessment) { create(:hmis_custom_assessment, client: eligible_source_client, data_source: hmis_data_source, definition: form_definition) }
        let!(:custom_data_element) { create(:hmis_custom_data_element, owner: custom_assessment, data_element_definition: cded, data_source: hmis_data_source, value_string: 'yes') }

        it 'does not count that candidate as removed' do
          result = described_class.for_rule(rule: new_rule)

          impact = result.affected_unit_groups.first
          expect(impact.current_candidate_count).to eq(4)
          # The 3 original candidates have no CDE value (nil → removed); the eligible_candidate has "yes" so they are kept.
          expect(impact.removed_candidate_count).to eq(3)
        end
      end
    end

    context 'when the proposed rule is a priority scheme' do
      it 'raises' do
        rule = build(:hmis_ce_priority_scheme, owner: project, expression: 'current_age')

        expect { described_class.for_rule(rule: rule) }.to raise_error(ArgumentError, /priority scheme impact preview is not supported/)
      end
    end

    context 'with a persisted rule that has unpersisted changes' do
      let!(:rule) { create(:hmis_ce_eligibility_requirement, owner: project, expression: 'current_age >= 18') }

      before do
        client1.destination_client.update!(dob: 30.years.ago(current_date))
        client2.destination_client.update!(dob: 35.years.ago(current_date))
        client3.destination_client.update!(dob: 50.years.ago(current_date))
      end

      it 'evaluates the in-memory expression against current candidates' do
        rule.expression = 'current_age >= 40'
        result = described_class.for_rule(rule: rule)

        impact = result.affected_unit_groups.first
        expect(impact.unit_group).to eq(unit_group)
        expect(impact.current_candidate_count).to eq(3)
        expect(impact.removed_candidate_count).to eq(2)
      end
    end
  end
end
