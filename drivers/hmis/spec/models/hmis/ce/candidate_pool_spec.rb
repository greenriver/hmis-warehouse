# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::CandidatePool do
  let!(:ds1) { create :hmis_data_source }
  let!(:p1) { create :hmis_hud_project, data_source: ds1, project_type: 13 }
  let!(:project_config) { create :hmis_project_ce_config, supports_waitlist_referrals: true, project: p1 }

  # Initial setup: project with 1 unit group that contains 2 units and is associated with a candidate pool
  let!(:pool) { create :hmis_ce_match_candidate_pool }
  let!(:ug) { create :hmis_unit_group, project: p1, candidate_pool: pool }
  let!(:unit1) { create :hmis_unit, project: p1, unit_group: ug }
  let!(:unit2) { create :hmis_unit, project: p1, unit_group: ug }

  describe 'scopes' do
    describe '.active' do
      context 'when pool is referenced by unit group in open project with waitlists enabled' do
        it 'includes the pool' do
          expect(described_class.active).to include(pool)
        end
      end

      context 'when pool has no unit groups' do
        let!(:pool_with_no_unit_groups) { create :hmis_ce_match_candidate_pool }
        it 'excludes the pool' do
          expect(described_class.active).not_to include(pool_with_no_unit_groups)
        end
      end

      context 'when pool is only referenced by unit group in closed project' do
        let!(:pool_in_inactive_project) { create :hmis_ce_match_candidate_pool }
        let!(:inactive_project) { create :hmis_hud_project, data_source: ds1, operating_end_date: 1.day.ago }
        let!(:inactive_project_config) { create :hmis_project_ce_config, supports_waitlist_referrals: true, project: inactive_project }
        let!(:inactive_unit_group) { create :hmis_unit_group, project: inactive_project, candidate_pool: pool_in_inactive_project }

        it 'excludes the pool' do
          expect(described_class.active).not_to include(pool_in_inactive_project)
        end
      end

      context 'when pool is only referenced by unit group in project without waitlists enabled' do
        let!(:pool_in_non_ce_project) { create :hmis_ce_match_candidate_pool }
        let!(:non_ce_project) { create :hmis_hud_project, data_source: ds1 }
        let!(:non_ce_unit_group) { create :hmis_unit_group, project: non_ce_project, candidate_pool: pool_in_non_ce_project }

        it 'excludes the pool' do
          expect(described_class.active).not_to include(pool_in_non_ce_project)
        end
      end

      context 'when pool is referenced by both active and inactive unit groups' do
        let!(:inactive_project) { create :hmis_hud_project, data_source: ds1, operating_end_date: 1.day.ago }
        let!(:inactive_project_config) { create :hmis_project_ce_config, supports_waitlist_referrals: true, project: inactive_project }
        let!(:inactive_unit_group) { create :hmis_unit_group, project: inactive_project, candidate_pool: pool }

        it 'includes the pool' do
          expect(described_class.active).to include(pool)
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
