###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'
  let(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let(:c2) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let(:c3) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, relationship_to_ho_h: 1, household_id: '1', user: u1 }
  let!(:e2) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c2, relationship_to_ho_h: 2, household_id: '1', user: u1 }
  let!(:e3) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c3, relationship_to_ho_h: 3, household_id: '1', user: u1 }

  before(:each) do
    hmis_login(user)
    assign_viewable(edit_access_group, p1.as_warehouse, hmis_user)
  end

  let(:test_input) do
    {
      confirmed: true,
      relationship_to_ho_h: Types::HmisSchema::Enums::Hud::RelationshipToHoH.enum_member_for_value(1).first,
    }
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation UpdateRelationshipToHoH($input: UpdateRelationshipToHoHInput!) {
        updateRelationshipToHoH(input: $input) {
          enrollment {
            id
            relationshipToHoH
            client {
              id
            }
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  it 'should change hoh correctly' do
    response, result = post_graphql(input: { enrollment_id: e3.id, **test_input }) { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      enrollment = result.dig('data', 'updateRelationshipToHoH', 'enrollment')
      errors = result.dig('data', 'updateRelationshipToHoH', 'errors')
      expect(enrollment).to be_present
      expect(errors).to be_empty
      expect(Hmis::Hud::Enrollment.all).to contain_exactly(
        have_attributes(personal_id: c1.personal_id, relationship_to_ho_h: 99),
        have_attributes(personal_id: c2.personal_id, relationship_to_ho_h: 2),
        have_attributes(personal_id: c3.personal_id, relationship_to_ho_h: 1),
      )
    end
  end

  it 'should throw error if unauthorized' do
    remove_permissions(hmis_user, :can_edit_enrollments)
    response, result = post_graphql(input: { enrollment_id: e3.id, **test_input }) { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      enrollment = result.dig('data', 'updateRelationshipToHoH', 'enrollment')
      errors = result.dig('data', 'updateRelationshipToHoH', 'errors')
      expect(enrollment).to be_nil
      expect(errors).to be_present
      expect(errors).to contain_exactly(include('type' => 'not_allowed'))
    end
  end

  describe 'Validity tests' do
    [
      [
        'should emit error if enrollment doesn\'t exist',
        ->(_enrollment = nil) do
          {
            enrollment_id: '0',
          }
        end,
        {
          severity: :error,
          type: :not_found,
          attribute: :enrollment,
        },
      ],
    ].each do |test_name, input_proc, error_attrs|
      it test_name do
        input = input_proc.call(e1).merge(test_input)
        response, result = post_graphql(input: input) { mutation }

        enrollment = result.dig('data', 'updateRelationshipToHoH', 'enrollment')
        errors = result.dig('data', 'updateRelationshipToHoH', 'errors')
        aggregate_failures 'checking response' do
          expect(response.status).to eq 200
          expect(enrollment).to be_nil
          expect(errors).to contain_exactly(
            include(**error_attrs.transform_keys(&:to_s).transform_values(&:to_s)),
          )
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
