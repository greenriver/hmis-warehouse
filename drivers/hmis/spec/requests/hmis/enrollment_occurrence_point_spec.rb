###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

#  Copyright 2016 - 2025 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  before(:all) do
    cleanup_test_environment
    Hmis::Form::Definition.delete_all
    Hmis::Form::Instance.delete_all
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'

  before(:each) do
    hmis_login(user)
  end

  let(:query) do
    <<~GRAPHQL
      query EnrollmentsWithOccurrencePoints(
        $enrollmentId: ID!
      ) {
        enrollment(id: $enrollmentId) {
          occurrencePointForms {
            id
            definition {
              #{form_definition_fragment}
            }
            dataCollectedAbout
          }
        }
      }
    GRAPHQL
  end

  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1 }
  let!(:access_control) { create_access_control(hmis_user, p1) }
  let!(:definition) do
    item_with_rule = {
      'text': 'Move-in address',
      'type': 'OBJECT',
      'link_id': 'address',
      'mapping': {
        'field_name': 'moveInAddresses',
        'record_type': 'ENROLLMENT',
      },
      'component': 'ADDRESS',
      'custom_rule': {
        'operator': 'ANY',
        'parts': [
          {
            'variable': 'projectId',
            'operator': 'NOT_EQUAL',
            'value': p1.project_id,
          },
        ],
      },
    }
    create(:occurrence_point_form, append_items: item_with_rule)
  end
  let!(:instance) { create(:hmis_form_instance, role: :OCCURRENCE_POINT, entity: p1, active: true, definition: definition) }

  it 'returns the correct definition with custom rules applied' do
    response, result = post_graphql(enrollment_id: e1.id) { query }
    expect(response.status).to eq(200), result.inspect
    occurrence_point_form = result.dig('data', 'enrollment', 'occurrencePointForms', 0)
    expect(occurrence_point_form.dig('id')).to eq("#{definition.id}:#{p1.id}")

    # Excludes the question that has a custom rule excluding it for this project
    definition_items = occurrence_point_form.dig('definition', 'definition', 'item')
    expect(definition_items.size).to eq(1)
    expect(definition_items.first['text']).to eq('Move-in Date')
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
