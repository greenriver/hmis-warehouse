# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::UnitGroupRuleResolver do
  let!(:organization) { create(:hmis_hud_organization) }
  let!(:project) { create(:hmis_hud_project, organization: organization) }
  let!(:unit_group) { create(:hmis_unit_group, project: project) }

  subject(:resolver) { described_class.new }

  describe '#key_for_unit_group' do
    context 'when no rules apply' do
      it 'returns nil' do
        key = resolver.key_for_unit_group(unit_group)
        expect(key).to be_nil
      end
    end

    context 'when only a priority rule applies' do
      it 'returns nil because a requirement is also needed' do
        create(:hmis_ce_priority_scheme, owner: unit_group, expression: 'days_homeless')
        key = resolver.key_for_unit_group(unit_group)
        expect(key).to be_nil
      end
    end

    context 'when only a requirement rule applies' do
      it 'returns nil because a priority is also needed' do
        create(:hmis_ce_eligibility_requirement, owner: unit_group, expression: 'current_age >= 18')
        key = resolver.key_for_unit_group(unit_group)
        expect(key).to be_nil
      end
    end

    context 'with rules at multiple owner levels' do
      let!(:org_req) { create(:hmis_ce_eligibility_requirement, owner: organization, expression: 'current_age >= 18') }
      let!(:proj_req) { create(:hmis_ce_eligibility_requirement, owner: project, expression: 'days_homeless >= 7') }
      let!(:ug_priority) { create(:hmis_ce_priority_scheme, owner: unit_group, expression: 'days_homeless') }

      it 'returns a key respecting precedence and AND composition' do
        key = resolver.key_for_unit_group(unit_group)
        # Eligibility requirements are ordered by owner precedence (UnitGroup > Project > Organization) then by id
        # and joined with AND. The first priority scheme is used.
        expect(key).to eq(['{days_homeless}', 'days_homeless >= 7 AND current_age >= 18'])
      end
    end
  end

  describe '#keys_for_all_unit_groups' do
    let!(:unit_group_2) { create(:hmis_unit_group, project: project) }
    let!(:unit_group_3_no_rules) { create(:hmis_unit_group, project: project) }

    before do
      # UG1 gets a priority and requirement
      create(:hmis_ce_priority_scheme, owner: unit_group, expression: 'score_a')
      create(:hmis_ce_eligibility_requirement, owner: project, expression: 'current_age >= 18')
      # UG2
      create(:hmis_ce_priority_scheme, owner: unit_group_2, expression: '0')
      create(:hmis_ce_eligibility_requirement, owner: unit_group_2, expression: 'veteran = TRUE')
      # UG3
      create(:hmis_ce_priority_scheme, owner: unit_group_3_no_rules, expression: '0')
    end

    it 'returns a hash of unit_group_id => key for groups with rules' do
      map = resolver.keys_for_all_unit_groups
      expect(map).to be_a(Hash)
      # Project-level requirement applies to all unit groups, so all three should appear
      expect(map.keys).to contain_exactly(unit_group.id, unit_group_2.id, unit_group_3_no_rules.id)
      expect(map[unit_group.id]).to eq(['{score_a}', 'current_age >= 18'])
      expect(map[unit_group_2.id]).to eq(['{0}', 'veteran = TRUE AND current_age >= 18'])
      expect(map[unit_group_3_no_rules.id]).to eq(['{0}', 'current_age >= 18'])
    end

    it 'can be scoped to a subset of unit groups' do
      scope = Hmis::UnitGroup.where(id: [unit_group.id, unit_group_3_no_rules.id])
      map = resolver.keys_for_all_unit_groups(scope)
      expect(map).to be_a(Hash)
      # Within the scope, both groups have applicable rules (project-level requirement)
      expect(map.keys).to contain_exactly(unit_group.id, unit_group_3_no_rules.id)
      expect(map).not_to have_key(unit_group_2.id)
    end

    it 'includes unit groups with only inherited (project-level) rules' do
      map = resolver.keys_for_all_unit_groups
      expect(map).to have_key(unit_group_3_no_rules.id)
    end
  end

  describe '#rules_for_unit_group' do
    let!(:org_req) { create(:hmis_ce_eligibility_requirement, owner: organization, expression: 'TRUE') }
    let!(:proj_req) { create(:hmis_ce_eligibility_requirement, owner: project, expression: 'score >= 10') }
    let!(:ug_priority) { create(:hmis_ce_priority_scheme, owner: unit_group, expression: 'score') }

    it 'returns deterministically ordered rules for the unit group' do
      rules = resolver.rules_for_unit_group(unit_group)
      expect(rules.map(&:owner).map(&:class)).to eq([Hmis::UnitGroup, Hmis::Hud::Project, Hmis::Hud::Organization])
      expect(rules.map(&:id)).to eq([ug_priority.id, proj_req.id, org_req.id])
    end
  end
end
