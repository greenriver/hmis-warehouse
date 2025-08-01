###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Referral, type: :model do
  include_context 'ce spec helper'

  let(:client) { create(:hmis_hud_client_with_warehouse_client, data_source: ds1, dob: 22.years.ago, veteran_status: 8) }
  let!(:rule) { create(:hmis_ce_eligibility_requirement, expression: requirement_expression, owner: project) }

  # Override in specific tests
  let(:requirement_expression) { 'TRUE' }

  describe 'resolve_match_rule_fields' do
    context 'when resolving custom data element field' do
      let(:requirement_expression) { '`cde.custom_assessment.housing_preference` = "apartment"' }
      let(:enrollment) { create(:hmis_hud_enrollment, client: client, data_source: ds1) }
      let(:assessment) { create(:hmis_custom_assessment, enrollment: enrollment, data_source: ds1) }

      let(:cded) { create(:hmis_custom_data_element_definition, data_source: ds1, key: 'housing_preference', label: 'Preferred Housing', owner_type: 'Hmis::Hud::CustomAssessment', form_definition_identifier: assessment.definition.identifier) }
      let!(:cde) { create(:hmis_custom_data_element, data_element_definition: cded, owner: assessment, value_string: 'house') }

      it 'resolves fields for custom data elements correctly' do
        resolved_fields = referral.resolve_match_rule_fields
        expect(resolved_fields).to include(
          have_attributes(
            field_name: cded.label,
            field_values: ['house'],
          ),
        )
      end
    end

    context 'when resolving project type field' do
      let(:requirement_expression) { 'INCLUDES(open_enrollment_project_types, PROJECT_TYPE("CE"))' }
      before do
        # enrollment at ES project
        p1 = create(:hmis_hud_project, project_type: 1, data_source: ds1)
        create(:hmis_hud_enrollment, client: client, data_source: ds1, project: p1)
        # enrollment at CE project
        p2 = create(:hmis_hud_project, project_type: 14, data_source: ds1)
        create(:hmis_hud_enrollment, client: client, data_source: ds1, project: p2)
        create(:hmis_hud_enrollment, client: client, data_source: ds1, project: p2)
      end

      it 'resolves fields for project types correctly' do
        resolved_fields = referral.resolve_match_rule_fields
        expect(resolved_fields).to include(
          have_attributes(
            field_name: 'Open enrollment project types',
            field_values: ['Emergency Shelter - Night-by-Night', 'Coordinated Entry'],
          ),
        )
      end
    end

    context 'when resolving expression with repeated fields' do
      let(:requirement_expression) { 'current_age > 18 AND current_age < 25 AND veteran_status = 1' }

      it 'deduplicates and transforms fields' do
        resolved_fields = referral.resolve_match_rule_fields
        expect(resolved_fields).to include(
          have_attributes(
            field_name: 'Current age',
            field_values: [22],
          ),
          have_attributes(
            field_name: 'Veteran status',
            field_values: ['Client doesn\'t know'], # 8
          ),
        )
      end
    end
  end
end
