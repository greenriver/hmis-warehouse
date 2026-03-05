###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  before(:each) do
    hmis_login(user)
  end

  let(:query) do
    <<~GRAPHQL
      query EnrollmentWithOccurrencePoints(
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

  let!(:access_control) { create_access_control(hmis_user, ds1) }

  context 'with form containing a custom_rule' do
    let!(:p1) { create :hmis_hud_project, data_source: ds1 }
    let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1 }
    let!(:p2) { create(:hmis_hud_project, data_source: ds1) }
    let!(:e2) { create :hmis_hud_enrollment, data_source: ds1, project: p2 }

    # custom form where 'question_2' is only collected for project p1
    let!(:definition) do
      create(:hmis_form_definition, identifier: 'occurrence_point_form_with_custom_rule', definition: { 'item' => [
               {
                 'text': 'Question 1',
                 'type': 'STRING',
                 'link_id': 'question_1',
                 'mapping': {
                   'custom_field_key': 'question_1',
                 },
               },
               {
                 'text': 'Question 2',
                 'type': 'STRING',
                 'link_id': 'question_2',
                 'mapping': {
                   'custom_field_key': 'question_2',
                 },
                 'custom_rule': {
                   'variable': 'projectId',
                   'operator': 'EQUAL',
                   'value': p1.project_id,
                 },
               },
             ] })
    end
    let!(:instance1) { create(:hmis_form_instance, role: :OCCURRENCE_POINT, entity: p1, active: true, definition: definition) }
    let!(:instance2) { create(:hmis_form_instance, role: :OCCURRENCE_POINT, entity: p2, active: true, definition: definition) }

    def query_forms(enrollment_id)
      response, result = post_graphql(enrollment_id: enrollment_id) { query }
      expect(response.status).to eq(200), result.inspect
      result.dig('data', 'enrollment', 'occurrencePointForms')
    end

    context 'for project that matches the custom rule' do
      it 'custom_rule is applied (question_2 is included)' do
        forms = query_forms(e1.id)
        expected_id = "#{definition.id}:#{p1.id}"
        expect(forms).to include(a_hash_including('id' => expected_id))

        # ensure question_2 is included in items
        items = forms.find { |form| form['id'] == expected_id }.dig('definition', 'definition', 'item')
        expect(items.size).to eq(2)
        expect(items).to contain_exactly(
          a_hash_including('linkId' => 'question_1'),
          a_hash_including('linkId' => 'question_2'),
        )
      end
    end

    context 'for project that does not match the custom rule' do
      it 'custom_rule is applied (question_2 is excluded)' do
        forms = query_forms(e2.id)
        expected_id = "#{definition.id}:#{p2.id}"
        expect(forms).to include(a_hash_including('id' => expected_id))

        # ensure question_2 is excluded from items
        items = forms.find { |form| form['id'] == expected_id }.dig('definition', 'definition', 'item')
        expect(items.size).to eq(1)
        expect(items).not_to include(a_hash_including('linkId' => 'question_2'))
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
