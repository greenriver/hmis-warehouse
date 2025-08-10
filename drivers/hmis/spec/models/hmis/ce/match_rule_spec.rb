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
    context 'when rule is owned by a unit group' do
      let!(:rule) { create(:hmis_ce_eligibility_requirement, owner: unit_1a.unit_group) }

      it 'returns the rule for that unit group' do
        rules = Hmis::Ce::Match::Rule.for_entity(unit_1a.unit_group)
        expect(rules).to contain_exactly(rule)
      end

      it 'does not return the rule for other unit groups or projects' do
        expect(Hmis::Ce::Match::Rule.for_entity(unit_2a.unit_group)).to be_empty
        expect(Hmis::Ce::Match::Rule.for_entity(project1)).not_to include(rule)
        expect(Hmis::Ce::Match::Rule.for_entity(project2)).to be_empty
      end
    end

    context 'when rule is owned by a project' do
      let!(:rule) { create(:hmis_ce_eligibility_requirement, owner: project1) }

      it 'returns the rule for that project' do
        rules = Hmis::Ce::Match::Rule.for_entity(project1)
        expect(rules).to include(rule)
      end

      it 'does not return the rule for a different project' do
        rules = Hmis::Ce::Match::Rule.for_entity(project2)
        expect(rules).to be_empty
      end
    end

    context 'when rule is owned by an organization' do
      let!(:rule) { create(:hmis_ce_eligibility_requirement, owner: organization) }

      it 'returns the rule for that organization' do
        rules = Hmis::Ce::Match::Rule.for_entity(organization)
        expect(rules).to include(rule)
      end

      it 'returns the rule for projects within the organization' do
        rules = Hmis::Ce::Match::Rule.for_entity(project1)
        expect(rules).to include(rule)
      end
    end

    context 'when the rule has applicability config regarding project type' do
      let!(:rule) do
        create(
          :hmis_ce_eligibility_requirement,
          owner: organization,
          applicability_config: {
            project_types: [0, 1, 2],
          },
        )
      end

      it 'returns the rule for projects with one of the specified types' do
        rules = Hmis::Ce::Match::Rule.for_entity(project1)
        expect(rules).to contain_exactly(rule)
      end

      it 'does not return the rule for other projects' do
        rules = Hmis::Ce::Match::Rule.for_entity(project2)
        expect(rules).to be_empty
      end
    end

    context 'when the rule has applicability config regarding funders' do
      let!(:funder1) { create(:hmis_hud_funder, funder: 20, project: project1, data_source: project1.data_source) }
      let!(:funder2) { create(:hmis_hud_funder, funder: 30, project: project2, data_source: project2.data_source) }

      let!(:rule) do
        create(
          :hmis_ce_eligibility_requirement,
          owner: organization,
          applicability_config: {
            project_funders: [funder1.funder],
          },
        )
      end

      it 'returns the rule for projects with one of the specified funders' do
        rules = Hmis::Ce::Match::Rule.for_entity(project1)
        expect(rules).to contain_exactly(rule)
      end

      it 'does not return the rule for other projects' do
        rules = Hmis::Ce::Match::Rule.for_entity(project2)
        expect(rules).to be_empty
      end

      context 'when there are many rules' do
        before(:each) do
          20.times { create(:hmis_ce_eligibility_requirement, owner: unit_1a.unit_group) }
          20.times { create(:hmis_ce_eligibility_requirement, owner: project1) }
          20.times { create(:hmis_ce_eligibility_requirement, owner: organization) }
          20.times do
            create(
              :hmis_ce_eligibility_requirement,
              owner: organization,
              applicability_config: {
                project_types: [0, 1, 2],
              },
            )
          end
          20.times do
            create(
              :hmis_ce_eligibility_requirement,
              owner: organization,
              applicability_config: {
                project_funders: [funder1.funder],
              },
            )
          end
        end

        it 'queries the db a reasonable amount' do
          expect do
            rules = Hmis::Ce::Match::Rule.for_entity(project1)
            # Includes one previously-declared funder applicability rule plus bulk-created ones
            expect(rules.length).to eq(81)
          end.to make_database_queries(count: 4..10)
        end
      end
    end
  end

  describe 'for_entity scope' do
    # Rules for each allowed entity type
    let!(:rule_for_unit_group) { create(:hmis_ce_eligibility_requirement, owner: unit_1a.unit_group) }
    let!(:rule_for_project) { create(:hmis_ce_eligibility_requirement, owner: project1) }
    let!(:rule_for_organization) { create(:hmis_ce_eligibility_requirement, owner: organization) }

    # cruft: rules for other entities
    let!(:rule_for_project2) { create(:hmis_ce_eligibility_requirement, owner: project2) }

    context 'when entity is a unit' do
      it 'raises for unsupported entity type' do
        expect { Hmis::Ce::Match::Rule.for_entity(unit_1a) }.
          to raise_error(ArgumentError, /Unexpected entity type/)
      end
    end

    context 'when entity is a unit group' do
      it 'returns rules for that unit group, and rules for all ancestor entities' do
        rules = Hmis::Ce::Match::Rule.for_entity(unit_1a.unit_group)
        expect(rules).to contain_exactly(rule_for_unit_group, rule_for_project, rule_for_organization)
      end
    end

    context 'when entity is a project' do
      it 'returns rules for that project, and rules for all ancestor entities' do
        rules = Hmis::Ce::Match::Rule.for_entity(project1)
        expect(rules).to contain_exactly(rule_for_project, rule_for_organization)
      end
    end

    context 'when entity is an organization' do
      it 'returns rules for that organization' do
        rules = Hmis::Ce::Match::Rule.for_entity(organization)
        expect(rules).to contain_exactly(rule_for_organization)
      end
    end
  end
end
