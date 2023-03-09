require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'
require_relative '../../models/hmis/form/hmis_form_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'
  include_context 'hmis service setup'
  include_context 'hmis form setup'

  TIME_FMT = '%Y-%m-%d %T.%3N'.freeze

  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: '2000-01-01' }
  let!(:f1) { create :hmis_hud_funder, data_source: ds1, project: p1 }
  let!(:pc1) { create :hmis_hud_project_coc, data_source: ds1, project: p1, coc_code: 'CO-500' }
  let!(:i1) { create :hmis_hud_inventory, data_source: ds1, project: p1, coc_code: pc1.coc_code, inventory_start_date: '2020-01-01' }
  let!(:s1) { create :hmis_hud_service, data_source: ds1, client: c1, enrollment: e1, user: u1 }
  let!(:cs1) { create :hmis_custom_service, custom_service_type: cst1, data_source: ds1, client: c1, enrollment: e1, user: u1 }

  before(:each) do
    hmis_login(user)
    assign_viewable(edit_access_group, o1.as_warehouse, hmis_user)
    assign_viewable(view_access_group, o1.as_warehouse, hmis_user)
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation SubmitForm($input: SubmitFormInput!) {
        submitForm(input: $input) {
          record {
            ... on Client {
              id
            }
            ... on Organization {
              id
            }
            ... on Project {
              id
            }
            ... on Funder {
              id
            }
            ... on ProjectCoc {
              id
            }
            ... on Inventory {
              id
            }
            ... on Service {
              id
            }
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  describe 'SubmitForm' do
    [
      :PROJECT, :FUNDER, :PROJECT_COC, :INVENTORY, :ORGANIZATION
      # :CLIENT, :SERVICE,
    ].each do |role|
      describe "for #{role.to_s.humanize}" do
        let(:definition) { Hmis::Form::Definition.find_by(role: role) }
        let(:test_input) do
          {
            form_definition_id: definition.id,
            organization_id: o1.id,
            project_id: p1.id,
            enrollment_id: e1.id,
            **completed_form_values_for_role(role),
          }
        end

        [
          [
            'should create a new record',
            ->(input) { input.except(:record_id) },
          ],
          [
            'should update an existing record',
            ->(input) { input },
          ],
        ].each do |test_name, input_proc|
          it test_name do
            # Set record_id based on role
            record_id = case role
            when :CLIENT
              c1.id
            when :PROJECT
              p1.id
            when :ORGANIZATION
              o1.id
            when :PROJECT_COC
              pc1.id
            when :FUNDER
              f1.id
            when :INVENTORY
              i1.id
            when :SERVICE
              cs1.id
            end

            input = input_proc.call(test_input.merge(record_id: record_id))
            puts ">>> input: #{input}"
            response, result = post_graphql(input: { input: input }) { mutation }
            puts ">>> result: #{result}"
            puts hmis_user.can_edit_organization?
            puts hmis_user.permission_for?(o1, :can_edit_organization)
            record_id = result.dig('data', 'submitForm', 'record', 'id')
            errors = result.dig('data', 'submitForm', 'errors')

            aggregate_failures 'checking response' do
              expect(response.status).to eq 200
              expect(errors).to be_empty
              expect(record_id).to be_present
              expect(record_id).to eq(input[:record_id].to_s) if input[:record_id].present?
              record = definition.role_class_name.constantize.find_by(id: record_id)
              expect(record).to be_present
              expect(Hmis::Form::CustomForm.where(owner: record).count).to eq(1)

              # Expect that all of the fields that were submitted exist on the record
              input[:hud_values].compact.keys.map(&:to_s).map(&:underscore).each do |method|
                expect(record.send(method)).to be_present
              end
            end
          end
        end

        it 'should fail if required field is missing' do
          required_item = find_required_item(definition)
          next unless required_item.present?

          input = test_input.merge(
            values: test_input[:values].merge(required_item.link_id => nil),
            hud_values: test_input[:hud_values].merge(required_item.field_name => nil),
          )
          response, result = post_graphql(input: { input: input }) { mutation }
          record = result.dig('data', 'submitForm', 'record')
          errors = result.dig('data', 'submitForm', 'errors')
          expected_errors = [
            {
              type: :required,
              attribute: required_item.field_name,
              severity: :error,
            },
          ]

          aggregate_failures 'checking response' do
            expect(response.status).to eq 200
            expect(record).to be_nil
            expect(errors).to match(expected_errors.map do |h|
              a_hash_including(**h.transform_keys(&:to_s).transform_values(&:to_s))
            end)
          end
        end

        it 'should fail if user lacks permission' do
          remove_permissions(hmis_user, Hmis::Form::Definition::FORM_ROLE_PERMISSIONS[role])
          response, result = post_graphql(input: { input: test_input }) { mutation }
          record = result.dig('data', 'submitForm', 'record')
          errors = result.dig('data', 'submitForm', 'errors')
          expected_errors = [
            {
              type: :not_allowed,
              attribute: :record,
              severity: :error,
            },
          ]

          aggregate_failures 'checking response' do
            expect(response.status).to eq 200
            expect(record).to be_nil
            expect(errors).to match(expected_errors.map do |h|
              a_hash_including(**h.transform_keys(&:to_s).transform_values(&:to_s))
            end)
          end
        end

        #   [
        #     [
        #       'should fail if required field is missing',
        #       ->(input) {
        #         input.merge(
        #           # change this to dynamically look for a required field and make it null
        #           values: input[:values].merge('2.02.2': ''),
        #           hud_values: input[:hud_values].merge('projectName': nil),
        #         )
        #       },
        # {
        #   type: :required,
        #   attribute: :projectName,
        #   severity: :error,
        # },
        #     ],
        #   ].each do |test_name, input_proc, *expected_errors|
        #     it test_name do
        #       input = input_proc.call(test_input)
        #       puts input
        #       response, result = post_graphql(input: { input: input }) { mutation }
        #       record = result.dig('data', 'submitForm', 'record')
        #       errors = result.dig('data', 'submitForm', 'errors')
        #       aggregate_failures 'checking response' do
        #         expect(response.status).to eq 200
        #         expect(record).to be_nil
        #         expect(errors).to match(expected_errors.map do |h|
        #           a_hash_including(**h.transform_keys(&:to_s).transform_values(&:to_s))
        #         end)
        #       end
        #     end
        #   end
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
  c.include FormHelpers
end
