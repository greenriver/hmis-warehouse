###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'
  include_context 'hmis service setup'
  include_context 'file upload setup'

  TIME_FMT = '%Y-%m-%d %T.%3N'.freeze

  let!(:access_control) { create_access_control(hmis_user, ds1) }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: '2000-01-01' }
  let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
  let!(:f1) { create :hmis_hud_funder, data_source: ds1, project: p1, user: u1, end_date: nil }
  let!(:pc1) { create :hmis_hud_project_coc, data_source: ds1, project: p1, coc_code: 'CO-500', user: u1 }
  let!(:i1) { create :hmis_hud_inventory, data_source: ds1, project: p1, coc_code: pc1.coc_code, inventory_start_date: '2020-01-01', inventory_end_date: nil, user: u1 }
  let!(:s1) { create :hmis_hud_service, data_source: ds1, client: c1, enrollment: e1, user: u1 }
  let!(:cs1) { create :hmis_custom_service, custom_service_type: cst1, data_source: ds1, client: c1, enrollment: e1, user: u1 }
  let!(:hmis_hud_service1) do
    hmis_service = Hmis::Hud::HmisService.find_by(owner: s1)
    hmis_service.custom_service_type = Hmis::Hud::CustomServiceType.find_by(hud_record_type: s1.record_type, hud_type_provided: s1.type_provided)
    hmis_service
  end
  let!(:file1) { create :file, client: c1, enrollment: e1, blob: blob, user_id: hmis_user.id, tags: [tag] }

  before(:each) do
    hmis_login(user)
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
            ... on File {
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
      :PROJECT,
      :FUNDER,
      :PROJECT_COC,
      :INVENTORY,
      :ORGANIZATION,
      :CLIENT,
      :SERVICE,
      :FILE,
    ].each do |role|
      describe "for #{role.to_s.humanize}" do
        let(:definition) { Hmis::Form::Definition.find_by(role: role) }
        let(:test_input) do
          {
            form_definition_id: definition.id,
            organization_id: o1.id,
            project_id: p1.id,
            enrollment_id: e1.id,
            service_type_id: hmis_hud_service1.custom_service_type_id,
            client_id: c1.id,
            confirmed: true, # ignore warnings, they are tested separately
            **completed_form_values_for_role(role) do |values|
              if role == :FILE
                # values[:values]['tags'] = [tag2.id.to_s]
                values[:values]['fileBlobId'] = blob.id.to_s
                # values[:hud_values]['tags'] = [tag2.id.to_s]
                values[:hud_values]['fileBlobId'] = blob.id.to_s
              end
              values
            end,
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
            input_record_id = case role
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
              hmis_hud_service1.id
            when :FILE
              file1.id
            end

            input = input_proc.call(test_input.merge(record_id: input_record_id))
            response, result = post_graphql(input: { input: input }) { mutation }
            record_id = result.dig('data', 'submitForm', 'record', 'id')
            errors = result.dig('data', 'submitForm', 'errors')

            aggregate_failures 'checking response' do
              expect(response.status).to eq 200
              expect(errors).to be_empty
              expect(record_id).to be_present
              expect(record_id).to eq(input[:record_id].to_s) if input[:record_id].present?
              record = definition.record_class_name.constantize.find_by(id: record_id)
              expect(record).to be_present
              expect(Hmis::Form::CustomForm.count).to eq(0)
              expect(Hmis::Form::FormProcessor.count).to eq(0)

              # Expect that all of the fields that were submitted exist on the record
              expected_present_keys = input[:hud_values].map { |k, v| [k, v == '_HIDDEN' ? nil : v] }.to_h.compact.keys
              expected_present_keys.map(&:to_s).map(&:underscore).each do |method|
                expect(record.send(method)).not_to be_nil unless ['race', 'gender', 'tags', 'file_blob_id'].include?(method)
              end
            end
          end
        end

        it 'should fail if required field is missing' do
          required_item = find_required_item(definition)
          next unless required_item.present?

          input = test_input.merge(
            values: test_input[:values].merge(required_item.link_id => nil),
            hud_values: test_input[:hud_values].merge(required_item.mapping.field_name => nil),
          )
          response, result = post_graphql(input: { input: input }) { mutation }
          record = result.dig('data', 'submitForm', 'record')
          errors = result.dig('data', 'submitForm', 'errors')
          expected_error = {
            type: :required,
            attribute: required_item.mapping.field_name,
            severity: :error,
          }

          aggregate_failures 'checking response' do
            expect(response.status).to eq 200
            expect(record).to be_nil
            expect(errors).to include(
              a_hash_including(**expected_error.transform_keys(&:to_s).transform_values(&:to_s)),
            )
          end
        end

        it 'should fail if user lacks permission' do
          remove_permissions(access_control, *Array(definition.record_editing_permission))
          expect_gql_error post_graphql(input: { input: test_input }) { mutation }
        end

        it 'should update user correctly' do
          _response, result = post_graphql(input: { input: test_input }) { mutation }
          expect(result.dig('data', 'submitForm', 'errors')).to be_blank
          record_id = result.dig('data', 'submitForm', 'record', 'id')
          record = definition.record_class_name.constantize.find_by(id: record_id)

          if role == :FILE
            expect(record.user).to eq(hmis_user)
            expect(record.updated_by).to eq(hmis_user)
          else
            expect(record.user).to eq(Hmis::Hud::User.from_user(hmis_user))
          end

          next_input = test_input.merge(record_id: record.id)
          record.update(user_id: 999, updated_by_id: nil) if role == :FILE

          _response, result = post_graphql(input: { input: next_input }) { mutation }
          record_id = result.dig('data', 'submitForm', 'record', 'id')
          record = definition.record_class_name.constantize.find_by(id: record_id)

          if role == :FILE
            expect(record.user_id).to eq(999)
            expect(record.updated_by).to eq(hmis_user)
          else
            expect(record.user).to eq(Hmis::Hud::User.from_user(hmis_user))
          end
        end
      end
    end
  end

  describe 'SubmitForm for Project (side effects)' do
    let(:definition) { Hmis::Form::Definition.find_by(role: :PROJECT) }
    let(:test_input) do
      {
        form_definition_id: definition.id,
        record_id: p1.id,
        **completed_form_values_for_role(:PROJECT),
        confirmed: false,
      }
    end

    def merge_hud_values(input, *args)
      input.merge(hud_values: input[:hud_values].merge(*args))
    end

    it 'should warn if changing the end date for a project with open enrollments' do
      # Set end dates on inventory and funder, so that we don't get warnings about them
      i1.update!(inventory_end_date: '2030-01-01')
      f1.update!(end_date: '2030-01-01')

      input = merge_hud_values(
        test_input.merge(confirmed: false),
        'operatingEndDate' => Date.today.strftime('%Y-%m-%d'),
      )

      response, result = post_graphql(input: { input: input }) { mutation }
      record_id = result.dig('data', 'submitForm', 'record', 'id')
      errors = result.dig('data', 'submitForm', 'errors')
      p1.reload
      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(record_id).to be_nil
        expect(p1.operating_end_date).to be_nil
        expect(errors).to match([
                                  a_hash_including('severity' => 'warning', 'type' => 'information', 'fullMessage' => Hmis::Hud::Validators::ProjectValidator.open_enrollments_message(1)),
                                ])
      end
    end

    it 'should NOT warn if the operating end date was not changed' do
      p1.update!(operating_end_date: '2030-01-01')
      input = merge_hud_values(
        test_input.merge(confirmed: false),
        'operatingEndDate' => '2030-01-01',
      )
      response, result = post_graphql(input: { input: input }) { mutation }
      record_id = result.dig('data', 'submitForm', 'record', 'id')
      errors = result.dig('data', 'submitForm', 'errors')
      p1.reload
      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(errors).to be_empty
        expect(record_id).to be_present
        expect(i1.reload.inventory_end_date).to be nil
        expect(f1.reload.end_date).to be nil
      end
    end

    it 'should NOT warn if the operating end date was cleared' do
      p1.update!(operating_end_date: '2030-01-01')
      input = merge_hud_values(
        test_input.merge(confirmed: false),
        'operatingEndDate' => nil,
      )
      response, result = post_graphql(input: { input: input }) { mutation }
      record_id = result.dig('data', 'submitForm', 'record', 'id')
      errors = result.dig('data', 'submitForm', 'errors')
      p1.reload
      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(errors).to be_empty
        expect(record_id).to be_present
        expect(i1.reload.inventory_end_date).to be nil
        expect(f1.reload.end_date).to be nil
      end
    end

    it 'should warn if closing project with open funders and inventory' do
      p1.update!(operating_end_date: nil)
      # Unlink enrollment, so we don't get a warning about it
      e1.update!(project: p2)

      input = merge_hud_values(
        test_input.merge(confirmed: false),
        'operatingEndDate' => Date.today.strftime('%Y-%m-%d'),
      )

      response, result = post_graphql(input: { input: input }) { mutation }
      record_id = result.dig('data', 'submitForm', 'record', 'id')
      errors = result.dig('data', 'submitForm', 'errors')
      p1.reload
      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(record_id).to be_nil
        expect(p1.operating_end_date).to be_nil
        expect(errors).to match([
                                  a_hash_including('severity' => 'warning', 'type' => 'information', 'fullMessage' => Hmis::Hud::Validators::ProjectValidator.open_funders_message(1)),
                                  a_hash_including('severity' => 'warning', 'type' => 'information', 'fullMessage' => Hmis::Hud::Validators::ProjectValidator.open_inventory_message(1)),
                                ])
        expect(i1.reload.inventory_end_date).to be nil
        expect(f1.reload.end_date).to be nil
      end
    end

    it 'should close related funders and inventory if confirmed' do
      p1.update!(operating_end_date: nil)
      i1.update!(inventory_end_date: nil)
      f1.update!(end_date: nil)

      input = merge_hud_values(
        test_input.merge(confirmed: true),
        'operatingEndDate' => Date.today.strftime('%Y-%m-%d'),
      )

      response, result = post_graphql(input: { input: input }) { mutation }
      record_id = result.dig('data', 'submitForm', 'record', 'id')
      errors = result.dig('data', 'submitForm', 'errors')
      p1.reload
      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(record_id).to be_present
        expect(errors.length).to eq(0)
        expect(p1.reload.operating_end_date).to be_present
        expect(i1.reload.inventory_end_date).to be_present
        expect(f1.reload.end_date).to be_present
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
  c.include FormHelpers
end
