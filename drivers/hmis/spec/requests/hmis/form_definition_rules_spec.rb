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

  let!(:access_control) { create_access_control(hmis_user, ds1) }

  before(:each) do
    hmis_login(user)
  end

  describe 'Form definition rule application (Assessment form)' do
    let(:form_role) { 'INTAKE' }
    let(:rule) { {} } # can be overridden in tests
    let(:custom_rule) { {} } # can be overridden in tests
    let(:assessment_date) { nil } # nil for new assessments, can be overridden in tests
    let!(:intake_definition) do
      create(:hmis_intake_assessment_definition, data_source: ds1, append_items: [
               {
                 'type': 'STRING',
                 'link_id': 'test_question_1',
                 'rule': rule,
                 'custom_rule': custom_rule,
               },
               {
                 'type': 'STRING',
                 'link_id': 'test_question_2',
               },
             ])
    end
    let!(:instance) { create(:hmis_form_instance, definition: intake_definition, entity: p1) }

    let(:query) do
      <<~GRAPHQL
        query GetAssessmentFormDefinition($projectId: ID!, $role: AssessmentRole, $assessmentDate: ISO8601Date) {
          assessmentFormDefinition(projectId: $projectId, role: $role, assessmentDate: $assessmentDate) {
            #{form_definition_fragment}
          }
        }
      GRAPHQL
    end

    def perform_assessment_query
      response, result = post_graphql({ project_id: p1.id.to_s, role: form_role, assessment_date: assessment_date }) { query }
      expect(response.status).to eq(200), result.inspect
      result.dig('data', 'assessmentFormDefinition')
    end

    shared_examples 'context matches rule' do
      it 'includes conditional item' do
        form = perform_assessment_query
        expect(form['id']).to eq(intake_definition.id.to_s)
        items = form.dig('definition', 'item', 0, 'item')
        link_ids = items.map { |item| item['linkId'] }
        expect(link_ids).to include('test_question_1')
      end
    end

    shared_examples 'context does not match rule' do
      it 'excludes conditional item' do
        form = perform_assessment_query
        expect(form['id']).to eq(intake_definition.id.to_s)
        items = form.dig('definition', 'item', 0, 'item')
        link_ids = items.map { |item| item['linkId'] }
        expect(link_ids).not_to include('test_question_1')
        expect(link_ids).to include('test_question_2')
      end
    end

    describe 'form definition with no added rules' do
      it_behaves_like 'context matches rule'
    end

    describe 'form definition with projectType rule' do
      let(:project_type) { 5 }
      let(:rule) { { variable: 'projectType', operator: 'EQUAL', value: project_type } }

      it_behaves_like 'context does not match rule'
      describe 'with matches' do
        before(:each) { p1.update!(project_type: project_type) }
        it_behaves_like 'context matches rule'
      end
    end

    describe 'form definition with projectType custom_rule' do
      let(:project_type) { 5 }
      let(:custom_rule) { { operator: 'ANY', parts: [{ variable: 'projectType', operator: 'EQUAL', value: project_type }] } }

      it_behaves_like 'context does not match rule'
      describe 'with match' do
        before(:each) { p1.update!(project_type: project_type) }
        it_behaves_like 'context matches rule'
      end
    end

    describe 'form definition with projectType rule AND projectType custom_rule' do
      let(:project_type) { 5 }
      let(:project_type_2) { 6 }
      let(:rule) { { operator: 'ANY', parts: [{ variable: 'projectType', operator: 'EQUAL', value: project_type }] } }
      let(:custom_rule) { { operator: 'ANY', parts: [{ variable: 'projectType', operator: 'EQUAL', value: project_type_2 }] } }

      it_behaves_like 'context does not match rule'
      describe 'with match on HUD Rule (and no match on Custom rule)' do
        before(:each) { p1.update!(project_type: project_type) }
        it_behaves_like 'context matches rule'
      end
      describe 'with match on custom rule (and no match on HUD rule)' do
        before(:each) { p1.update!(project_type: project_type_2) }
        it_behaves_like 'context matches rule'
      end
    end

    describe 'form definition with projectFunders rule' do
      let(:funder) { 1234 }
      let(:rule) { { variable: 'projectFunders', operator: 'INCLUDE', value: funder } }

      it_behaves_like 'context does not match rule'
      describe 'with matches' do
        before(:each) { create :hmis_hud_funder, data_source: ds1, project: p1, funder: funder }
        it_behaves_like 'context matches rule'
      end
      describe 'with active date specified' do
        before(:each) { create :hmis_hud_funder, start_date: 2.years.ago, end_date: 1.year.ago, data_source: ds1, project: p1, funder: funder }
        it_behaves_like 'context does not match rule' # funder is not currently active

        context 'when funder was NOT active at specified date' do
          let(:assessment_date) { 6.months.ago }
          it_behaves_like 'context does not match rule'
        end
        context 'when funder WAS active at specified date' do
          let(:assessment_date) { 18.months.ago }
          it_behaves_like 'context matches rule'
        end
      end
    end

    describe 'form definition with projectOtherFunders rule' do
      let(:other_funder) { '123XYZ' }
      let(:rule) { { variable: 'projectOtherFunders', operator: 'INCLUDE', value: other_funder } }

      it_behaves_like 'context does not match rule'
      describe 'with matches' do
        before(:each) { create :hmis_hud_funder, data_source: ds1, project: p1, other_funder: other_funder }
        it_behaves_like 'context matches rule'
      end
    end

    describe 'form definition with all rule' do
      let(:project_type) { 5 }
      let(:funder) { 1234 }
      let(:rule) { { operator: 'ALL', parts: [{ variable: 'projectType', operator: 'EQUAL', value: project_type }, { variable: 'projectFunders', operator: 'INCLUDE', value: funder }] } }

      it_behaves_like 'context does not match rule'
      describe 'with partial match' do
        before(:each) { p1.update!(project_type: project_type) }
        it_behaves_like 'context does not match rule'
      end
      describe 'with complete match' do
        before(:each) do
          p1.update!(project_type: project_type)
          create :hmis_hud_funder, data_source: ds1, project: p1, funder: funder
        end
        it_behaves_like 'context matches rule'
      end
    end

    describe 'form definition with any rule' do
      let(:project_type) { 5 }
      let(:funder) { 1234 }
      let(:rule) { { operator: 'ANY', parts: [{ variable: 'projectType', operator: 'EQUAL', value: project_type }, { variable: 'projectFunders', operator: 'INCLUDE', value: funder }] } }

      it_behaves_like 'context does not match rule'
      describe 'with partial match' do
        before(:each) { p1.update!(project_type: project_type) }
        it_behaves_like 'context matches rule'
      end
    end
  end

  describe 'Form definition Project rule application (Enrollment form)' do
    let(:form_role) { 'ENROLLMENT' }

    let(:enrollment_definition) do
      create(:hmis_form_definition, role: form_role, definition: { 'item' => [
               {
                 'type': 'STRING',
                 'link_id': 'conditional-question',
                 'rule': { variable: 'projectType', operator: 'EQUAL', value: 12 },
               },
               {
                 'type': 'STRING',
                 'link_id': 'unconditional-question',
               },
             ] })
    end
    # apply the custom enrollment form to the project
    let!(:enrollment_instance) { create(:hmis_form_instance, role: form_role, entity: p1, definition: enrollment_definition) }

    let(:query) do
      <<~GRAPHQL
        query recordFormDefinition($projectId: ID, $role: RecordFormRole!) {
          recordFormDefinition(projectId: $projectId, role: $role) {
            #{form_definition_fragment}
          }
        }
      GRAPHQL
    end

    def query_form_definition
      response, result = post_graphql({ project_id: p1.id.to_s, role: form_role }) { query }
      expect(response.status).to eq(200), result.inspect
      result.dig('data', 'recordFormDefinition')
    end

    describe 'applies projectType rule' do
      it 'excludes filtered items' do
        expect(query_form_definition).to be_present
        expect(query_form_definition['id']).to eq(enrollment_definition.id.to_s)
        items = query_form_definition['definition']['item'].map { |item| item['linkId'] }
        expect(items).to contain_exactly('unconditional-question')
        expect(items).not_to include('conditional-question')
      end
      describe 'with matches' do
        before(:each) { p1.update!(project_type: 12) }
        it 'includes all items' do
          expect(query_form_definition).to be_present
          items = query_form_definition['definition']['item'].map { |item| item['linkId'] }
          expect(items).to contain_exactly('conditional-question', 'unconditional-question')
        end
      end
    end
  end

  describe 'Form definition Project rule application (resolved on Assessment lookup)' do
    let(:items_with_rule) do
      [
        {
          'type': 'STRING',
          'link_id': 'field-project-type-2',
          'rule': { variable: 'projectType', operator: 'EQUAL', value: 12 },
        },
        {
          'type': 'STRING',
          'link_id': 'field-2',
        },
      ]
    end

    let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }
    let!(:assessment) do
      a1 = create(:hmis_custom_assessment, client: c1, enrollment: e1, data_source: ds1)
      a1.form_processor.definition.update(definition: { 'item' => [{ 'type': 'GROUP', 'link_id': 'group-1', 'item': items_with_rule }] })
      a1
    end

    let(:query) do
      <<~GRAPHQL
        query GetAssessment($id: ID!) {
          assessment(id: $id) {
            id
            definition {
              #{form_definition_fragment}
            }
          }
        }
      GRAPHQL
    end

    def query_form_definition_items
      response, result = post_graphql({ id: assessment.id.to_s }) { query }
      expect(response.status).to eq(200), result.inspect
      result.dig('data', 'assessment', 'definition', 'definition', 'item', 0, 'item')
    end

    describe 'applies projectType rule' do
      it 'excludes filtered items' do
        expect(query_form_definition_items.size).to eq(items_with_rule.size - 1)
      end
      describe 'with matches' do
        before(:each) { p1.update!(project_type: 12) }
        it 'includes all items' do
          expect(query_form_definition_items.size).to eq(items_with_rule.size)
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
