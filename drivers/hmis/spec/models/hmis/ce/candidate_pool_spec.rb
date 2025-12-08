# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::CandidatePool do
  let!(:ds1) { create :hmis_data_source }
  let!(:p1) { create :hmis_hud_project, data_source: ds1, project_type: 13 }
  let!(:project_config) { create :hmis_project_ce_config, supports_waitlist_referrals: true, project: p1 }

  describe 'scopes' do
    let!(:pool) { create :hmis_ce_match_candidate_pool }

    describe '.active' do
      context 'with open opportunities' do
        let!(:opp) { create :hmis_ce_opportunity, project: p1, data_source: ds1, status: :open, candidate_pool: pool }

        it 'includes pools with open opportunities' do
          expect(described_class.active).to include(pool)
        end
      end

      context 'with locked opportunities' do
        let!(:opp) { create :hmis_ce_opportunity, project: p1, data_source: ds1, status: :locked, candidate_pool: pool }

        it 'includes pools with locked opportunities' do
          expect(described_class.active).to include(pool)
        end
      end

      context 'with only closed opportunities' do
        let!(:opp) { create :hmis_ce_opportunity, project: p1, data_source: ds1, status: :closed, candidate_pool: pool }

        it 'excludes pools with only closed opportunities' do
          expect(described_class.active).not_to include(pool)
        end
      end

      context 'with unit groups but no opportunities' do
        let!(:ug) { create :hmis_unit_group, project: p1, candidate_pool: pool }

        it 'includes pools referenced by unit groups' do
          expect(described_class.active).to include(pool)
        end
      end
    end

    describe '.receiving_referrals' do
      context 'with open opportunities' do
        let!(:opp) { create :hmis_ce_opportunity, project: p1, data_source: ds1, status: :open, candidate_pool: pool }

        it 'includes pools with open opportunities' do
          expect(described_class.receiving_referrals).to include(pool)
        end
      end

      context 'with only locked opportunities' do
        let!(:opp) { create :hmis_ce_opportunity, project: p1, data_source: ds1, status: :locked, candidate_pool: pool }

        it 'excludes pools with only locked opportunities' do
          expect(described_class.receiving_referrals).not_to include(pool)
        end
      end

      context 'with both open and locked opportunities' do
        let!(:opp_open) { create :hmis_ce_opportunity, project: p1, data_source: ds1, status: :open, candidate_pool: pool }
        let!(:opp_locked) { create :hmis_ce_opportunity, project: p1, data_source: ds1, status: :locked, candidate_pool: pool }

        it 'includes pools with at least one open opportunity' do
          expect(described_class.receiving_referrals).to include(pool)
        end
      end

      context 'with only closed and locked opportunities' do
        let!(:opp_closed) { create :hmis_ce_opportunity, project: p1, data_source: ds1, status: :closed, candidate_pool: pool }
        let!(:opp_locked) { create :hmis_ce_opportunity, project: p1, data_source: ds1, status: :locked, candidate_pool: pool }

        it 'excludes pools with only closed and locked opportunities' do
          expect(described_class.receiving_referrals).not_to include(pool)
        end
      end

      context 'with unit groups but no opportunities' do
        let!(:ug) { create :hmis_unit_group, project: p1, candidate_pool: pool }

        it 'includes pools referenced by unit groups' do
          expect(described_class.receiving_referrals).to include(pool)
        end
      end

      context 'with stale open opportunities and locked opportunities from old pool' do
        let!(:old_pool) { create :hmis_ce_match_candidate_pool }
        let!(:new_pool) { create :hmis_ce_match_candidate_pool }
        let!(:opp_locked) { create :hmis_ce_opportunity, project: p1, data_source: ds1, status: :locked, candidate_pool: old_pool }
        let!(:opp_open) { create :hmis_ce_opportunity, project: p1, data_source: ds1, status: :open, candidate_pool: new_pool }
        let!(:ug) { create :hmis_unit_group, project: p1, candidate_pool: new_pool }

        it 'excludes old pool with only locked opportunities' do
          expect(described_class.receiving_referrals).not_to include(old_pool)
        end

        it 'includes new pool with open opportunities' do
          expect(described_class.receiving_referrals).to include(new_pool)
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
