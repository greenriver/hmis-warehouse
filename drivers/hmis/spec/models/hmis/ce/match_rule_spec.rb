# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::Rule, type: :model do
  let!(:template) { create(:hmis_workflow_definition_template) }
  let!(:organization) { create :hmis_hud_organization }
  let!(:project1) { create :hmis_hud_project, organization: organization, project_type: 0 }
  let!(:project2) { create :hmis_hud_project, organization: organization, project_type: 5 }
  let!(:project3) { create :hmis_hud_project }
  let!(:unit_1a) { create(:hmis_unit, project: project1) }
  let!(:opportunity_1a) { create(:hmis_ce_opportunity, workflow_template: template, project: project1, owner: unit_1a) }
  let!(:opportunity_1b) { create(:hmis_ce_opportunity, workflow_template: template, project: project1) }
  let!(:opportunity_2) { create(:hmis_ce_opportunity, workflow_template: template, project: project2) }
  let!(:opportunity_3) { create(:hmis_ce_opportunity, workflow_template: template, project: project3) }

  describe 'for_opportunity scope' do
    context 'when rule is owned by a unit' do
      let!(:rule) { create(:hmis_ce_eligibility_requirement, owner: unit_1a) }

      it 'returns the rule for opportunity owned by that unit' do
        rules = Hmis::Ce::Match::Rule.for_opportunity(opportunity_1a)
        expect(rules).to contain_exactly(rule)
      end

      it 'does not return the rule for other opportunities' do
        [opportunity_1b, opportunity_2, opportunity_3].each do |opportunity|
          rules = Hmis::Ce::Match::Rule.for_opportunity(opportunity)
          expect(rules).to be_empty
        end
      end
    end

    # TODO add: unit group

    context 'when rule is owned by a project' do
      let!(:rule) { create(:hmis_ce_eligibility_requirement, owner: project1) }

      it 'returns the rule for opportunities in that project' do
        [opportunity_1a, opportunity_1b].each do |opportunity|
          rules = Hmis::Ce::Match::Rule.for_opportunity(opportunity)
          expect(rules).to contain_exactly(rule)
        end
      end

      it 'does not return the rule for opportunities in a different project' do
        [opportunity_2, opportunity_3].each do |opportunity|
          rules = Hmis::Ce::Match::Rule.for_opportunity(opportunity)
          expect(rules).to be_empty
        end
      end
    end

    context 'when rule is owned by an organization' do
      let!(:rule) { create(:hmis_ce_eligibility_requirement, owner: organization) }

      it 'returns the rule for opportunities in that organization' do
        [opportunity_1a, opportunity_1b, opportunity_2].each do |opportunity|
          rules = Hmis::Ce::Match::Rule.for_opportunity(opportunity)
          expect(rules).to contain_exactly(rule)
        end
      end

      it 'does not return the rule for opportunities in a different project' do
        rules = Hmis::Ce::Match::Rule.for_opportunity(opportunity_3)
        expect(rules).to be_empty
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
        rules = Hmis::Ce::Match::Rule.for_opportunity(opportunity_1a)
        expect(rules).to contain_exactly(rule)
      end

      it 'does not return the rule for other projects' do
        rules = Hmis::Ce::Match::Rule.for_opportunity(opportunity_2)
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
        rules = Hmis::Ce::Match::Rule.for_opportunity(opportunity_1a)
        expect(rules).to contain_exactly(rule)
      end

      it 'does not return the rule for other projects' do
        rules = Hmis::Ce::Match::Rule.for_opportunity(opportunity_2)
        expect(rules).to be_empty
      end

      context 'when there are many rules' do
        before(:each) do
          # 20.times { create(:hmis_ce_eligibility_requirement, owner: opportunity_1a) }
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
            rules = Hmis::Ce::Match::Rule.for_opportunity(opportunity_1a)
            expect(rules.length).to eq(81)
          end.to make_database_queries(count: 4..10)
        end
      end
    end
  end
end
