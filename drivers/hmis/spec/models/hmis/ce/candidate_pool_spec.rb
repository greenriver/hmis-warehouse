# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::CandidatePool do
  before(:each) do
    # Stub CandidatePoolBuilder to prevent it from overwriting the unit groups' pools in after_create callbacks
    allow_any_instance_of(Hmis::Ce::Match::CandidatePoolBuilder).to receive(:call)
  end

  let!(:ds1) { create :hmis_data_source }
  let!(:p1) { create :hmis_hud_project, data_source: ds1, project_type: 13 }
  let!(:project_config) { create :hmis_project_ce_config, supports_waitlist_referrals: true, project: p1 }

  # Initial setup: project with 1 unit group that contains 2 units and is associated with a candidate pool
  let!(:pool) { create :hmis_ce_match_candidate_pool }
  let!(:ug) { create :hmis_unit_group, project: p1, candidate_pool: pool }
  let!(:unit1) { create :hmis_unit, project: p1, unit_group: ug }
  let!(:unit2) { create :hmis_unit, project: p1, unit_group: ug }

  describe 'scopes' do
    describe '.active_for_maintenance and .active_for_current_eligibility' do
      it 'both include pools referenced by unit groups' do
        expect(described_class.active_for_maintenance).to include(pool)
        expect(described_class.active_for_current_eligibility).to include(pool)
      end

      context 'when pool is not referenced by any unit groups' do
        # Mimic the situation where the unit group now refers to a new candidate pool, but there are stale opportunities that still reference the old pool
        let!(:new_pool) { create :hmis_ce_match_candidate_pool }
        let!(:ug) { create :hmis_unit_group, project: p1, candidate_pool: new_pool }

        context 'with open opportunities' do
          let!(:opp) { create :hmis_ce_opportunity, unit: unit1, status: :open, candidate_pool: pool }

          it 'both include pools with open opportunities' do
            expect(described_class.active_for_maintenance).to include(pool)
            expect(described_class.active_for_current_eligibility).to include(pool)
          end
        end

        context 'with locked opportunities' do
          let!(:opp) { create :hmis_ce_opportunity, unit: unit1, status: :locked, candidate_pool: pool }

          it 'active_for_maintenance includes pools with only locked opportunities' do
            expect(described_class.active_for_maintenance).to include(pool)
          end

          it 'active_for_current_eligibility excludes pools with only locked opportunities' do
            expect(described_class.active_for_current_eligibility).not_to include(pool)
          end
        end

        context 'with only closed opportunities' do
          let!(:opp) { create :hmis_ce_opportunity, unit: unit1, status: :closed, candidate_pool: pool }

          it 'both exclude pools with only closed opportunities' do
            expect(described_class.active_for_maintenance).not_to include(pool)
            expect(described_class.active_for_current_eligibility).not_to include(pool)
          end
        end

        context 'with stale open opportunities and locked opportunities from old pool' do
          let!(:new_pool) { create :hmis_ce_match_candidate_pool }
          let!(:opp_locked) { create :hmis_ce_opportunity, unit: unit1, status: :locked, candidate_pool: pool }
          let!(:opp_open) { create :hmis_ce_opportunity, unit: unit1, status: :open, candidate_pool: new_pool }
          let!(:ug) { create :hmis_unit_group, project: p1, candidate_pool: new_pool }

          it 'active_for_current_eligibility excludes old pool with only locked opportunities' do
            expect(described_class.active_for_current_eligibility).not_to include(pool)
          end

          it 'active_for_current_eligibility includes new pool with open opportunities' do
            expect(described_class.active_for_current_eligibility).to include(new_pool)
          end
        end
      end
    end
  end

  describe '#relevant_form_definition_identifiers' do
    context 'with expressions that refer to CDEs' do
      let!(:fd1) { create(:hmis_form_definition, role: :CUSTOM_ASSESSMENT, status: :published, version: 1) }
      # default form definition factory generates cded "fieldOne"
      let!(:cded1) { create :hmis_custom_data_element_definition, owner_type: 'Hmis::Hud::CustomAssessment', key: 'fieldOne', form_definition: fd1 }

      let!(:fd2) { create(:custom_assessment_with_custom_fields, role: :CUSTOM_ASSESSMENT, status: :published, version: 1) }
      # custom_assessment_with_custom_fields factory generates cded "custom_question_1"
      let!(:cded2) { create :hmis_custom_data_element_definition, owner_type: 'Hmis::Hud::CustomAssessment', key: 'custom_question_1', form_definition: fd2 }

      let!(:pool) { create :hmis_ce_match_candidate_pool, requirement_expression: "`cde.custom_assessment.fieldOne` = '1'", priority_expression: 'cde.custom_assessment.custom_question_1' }

      it 'returns associated form definition identifiers' do
        expect(pool.relevant_form_definition_identifiers).to contain_exactly(
          fd1.identifier,
          fd2.identifier,
        )
      end
    end
  end
end
