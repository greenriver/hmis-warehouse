# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::Rule, type: :model do
  let!(:organization) { create :hmis_hud_organization }
  let!(:template) { create(:hmis_workflow_definition_template, data_source: organization.data_source) }
  let!(:project1) { create :hmis_hud_project, organization: organization, project_type: 0 }
  let!(:project2) { create :hmis_hud_project, organization: organization, project_type: 5 }
  let!(:project3) { create :hmis_hud_project, data_source: organization.data_source }
  let!(:unit_1a) { create(:hmis_unit_in_group, project: project1) }
  let!(:unit_2a) { create(:hmis_unit_in_group, project: project2) }
  let(:opportunity_1a) { create(:hmis_ce_opportunity, workflow_template: template, project: project1, unit: unit_1a) }
  let(:opportunity_1b) { create(:hmis_ce_opportunity, workflow_template: template, project: project1) }
  let(:opportunity_2) { create(:hmis_ce_opportunity, workflow_template: template, project: project2) }
  let(:opportunity_3) { create(:hmis_ce_opportunity, workflow_template: template, project: project3) }

  describe '.by_owner_precedence' do
    let!(:org_rule) { create(:hmis_ce_eligibility_requirement, owner: organization) }
    let!(:project_rule) { create(:hmis_ce_eligibility_requirement, owner: project1) }
    let!(:unit_group_rule) { create(:hmis_ce_eligibility_requirement, owner: unit_1a.unit_group) }

    # Create additional rules to test secondary sorting by id
    let!(:org_rule_2) { create(:hmis_ce_priority_scheme, owner: organization) }
    let!(:project_rule_2) { create(:hmis_ce_priority_scheme, owner: project1) }

    it 'orders rules by owner precedence (UnitGroup > Project > Organization) then by id' do
      rules = described_class.by_owner_precedence.to_a

      # Find positions of our rules in the ordered result
      unit_group_pos = rules.index(unit_group_rule)
      project_pos_1 = rules.index(project_rule)
      project_pos_2 = rules.index(project_rule_2)
      org_pos_1 = rules.index(org_rule)
      org_pos_2 = rules.index(org_rule_2)

      # UnitGroup rules should come first
      expect(unit_group_pos).to be < project_pos_1
      expect(unit_group_pos).to be < org_pos_1

      # Project rules should come before Organization rules
      expect(project_pos_1).to be < org_pos_1
      expect(project_pos_2).to be < org_pos_1

      # Within same owner type, rules should be ordered by id
      expect(project_pos_1).to be < project_pos_2  # assuming project_rule has lower id
      expect(org_pos_1).to be < org_pos_2          # assuming org_rule has lower id
    end

    it 'produces deterministic ordering across multiple calls' do
      first_call = described_class.by_owner_precedence.pluck(:id)
      second_call = described_class.by_owner_precedence.pluck(:id)

      expect(first_call).to eq(second_call)
    end
  end

  describe 'for_entity scope' do
    let!(:org_rule) { create(:hmis_ce_eligibility_requirement, owner: organization) }
    let!(:project_rule) { create(:hmis_ce_eligibility_requirement, owner: project1) }
    let!(:unit_group_rule) { create(:hmis_ce_eligibility_requirement, owner: unit_1a.unit_group) }

    # Rules that should not be returned for project1 or its descendants
    let!(:other_project_rule) { create(:hmis_ce_eligibility_requirement, owner: project2) }

    context 'when entity is an Organization' do
      it 'returns rules owned by that organization' do
        rules = described_class.for_entity(organization)
        expect(rules).to contain_exactly(org_rule)
      end
    end

    context 'when entity is a Project' do
      it 'returns rules for that project and its parent organization' do
        rules = described_class.for_entity(project1)
        expect(rules).to contain_exactly(project_rule, org_rule)
      end

      it 'does not return rules for other projects' do
        rules = described_class.for_entity(project2)
        expect(rules).to contain_exactly(other_project_rule, org_rule)
        expect(rules).not_to include(project_rule, unit_group_rule)
      end
    end

    context 'when entity is a UnitGroup' do
      it 'returns rules for that unit group and all ancestor entities' do
        rules = described_class.for_entity(unit_1a.unit_group)
        expect(rules).to contain_exactly(unit_group_rule, project_rule, org_rule)
      end
    end

    context 'with project_type applicability config' do
      let!(:type_rule) do
        create(:hmis_ce_eligibility_requirement, owner: organization,
                                                 applicability_config: { project_types: [0, 1, 2] })
      end

      it 'returns the rule for projects with a matching type' do
        rules = described_class.for_entity(project1) # project_type: 0
        expect(rules).to include(type_rule)
      end

      it 'does not return the rule for projects with a non-matching type' do
        rules = described_class.for_entity(project2) # project_type: 5
        expect(rules).not_to include(type_rule)
      end
    end

    context 'with project_funders applicability config' do
      let!(:funder1) { create(:hmis_hud_funder, funder: 20, project: project1, data_source: project1.data_source) }
      let!(:funder_rule) do
        create(:hmis_ce_eligibility_requirement, owner: organization,
                                                 applicability_config: { project_funders: [funder1.funder] })
      end

      before do
        # Create a funder for project2 that should not match
        create(:hmis_hud_funder, funder: 30, project: project2, data_source: project2.data_source)
      end

      it 'returns the rule for projects with a matching funder' do
        rules = described_class.for_entity(project1)
        expect(rules).to include(funder_rule)
      end

      it 'does not return the rule for projects without a matching funder' do
        rules = described_class.for_entity(project2)
        expect(rules).not_to include(funder_rule)
      end
    end

    context 'with unsupported entity types' do
      it 'raises an ArgumentError' do
        expect { described_class.for_entity(unit_1a) }.
          to raise_error(ArgumentError, /Unexpected entity type/)
      end
    end

    context 'when there are many rules' do
      it 'queries the db a reasonable number of times' do
        # Setup additional data for performance testing
        create_list(:hmis_ce_eligibility_requirement, 20, owner: unit_1a.unit_group)
        create_list(:hmis_ce_eligibility_requirement, 20, owner: project1)
        create_list(:hmis_ce_eligibility_requirement, 20, owner: organization)

        expect { described_class.for_entity(project1) }.to make_database_queries(count: 4..10)
      end
    end
  end
end
