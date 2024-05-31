###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
  let!(:c2) { create :hmis_hud_client_complete, data_source: ds1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c2, user: u1, entry_date: '2000-01-01' }
  let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1, with_coc: true }
  let!(:f1) { create :hmis_hud_funder, data_source: ds1, project: p1, user: u1, end_date: nil }
  let!(:pc1) { create :hmis_hud_project_coc, data_source: ds1, project: p1, coc_code: 'CO-500', user: u1 }
  let!(:i1) { create :hmis_hud_inventory, data_source: ds1, project: p1, coc_code: pc1.coc_code, inventory_start_date: '2020-01-01', inventory_end_date: nil, user: u1 }
  let!(:hmis_particip1) { create :hmis_hud_hmis_participation, data_source: ds1, project: p1 }
  let!(:ce_particip1) { create :hmis_hud_ce_participation, data_source: ds1, project: p1 }

  let!(:s1) { create :hmis_hud_service, data_source: ds1, client: c2, enrollment: e1, user: u1 }
  let!(:cs1) { create :hmis_custom_service, custom_service_type: cst1, data_source: ds1, client: c2, enrollment: e1, user: u1 }
  let!(:a1) { create :hmis_hud_assessment, data_source: ds1, client: c2, enrollment: e1, user: u1 }
  let!(:evt1) { create :hmis_hud_event, data_source: ds1, client: c2, enrollment: e1, user: u1 }
  let!(:custom_case_note) do
    create(:hmis_hud_custom_case_note, data_source: ds1, client: c2, enrollment: e1, user: u1)
  end
  let!(:hmis_hud_service1) do
    hmis_service = Hmis::Hud::HmisService.find_by(owner: s1)
    hmis_service.custom_service_type_id = Hmis::Hud::CustomServiceType.find_by(hud_record_type: s1.record_type, hud_type_provided: s1.type_provided).id
    hmis_service
  end
  let!(:file1) { create :file, client: c2, enrollment: e1, blob: blob, user_id: hmis_user.id, tags: [tag] }

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
            ... on CustomCaseNote {
              id
            }
            ... on Enrollment {
              id
              inProgress
              householdSize
            }
            ... on CurrentLivingSituation {
              id
            }
            ... on CeAssessment {
              id
            }
            ... on Event {
              id
            }
            ... on HmisParticipation {
              id
            }
            ... on CeParticipation {
              id
            }
            ... on ReferralPosting {
              id
            }
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  def submit_form(input)
    response, result = post_graphql(input: { input: input }) { mutation }
    expect(response.status).to eq(200), result&.inspect
    record = result.dig('data', 'submitForm', 'record')
    errors = result.dig('data', 'submitForm', 'errors')
    [record, errors]
  end

  describe 'SubmitForm' do
    [
      :PROJECT,
      :FUNDER,
      :PROJECT_COC,
      :INVENTORY,
      :HMIS_PARTICIPATION,
      :CE_PARTICIPATION,
      :ORGANIZATION,
      :CLIENT,
      :SERVICE,
      :FILE,
      :ENROLLMENT,
      :CURRENT_LIVING_SITUATION,
      :CE_ASSESSMENT,
      :CE_EVENT,
      :CASE_NOTE,
      :REFERRAL,
    ].each do |role|
      describe "for #{role.to_s.humanize}" do
        let(:definition) { Hmis::Form::Definition.find_by(role: role) }
        let(:test_input) do
          {
            form_definition_id: definition.id,
            organization_id: o1.id,
            project_id: role == :ENROLLMENT ? p2.id : p1.id, # use p2 because it has 1 coc code
            enrollment_id: e1.id,
            service_type_id: hmis_hud_service1.custom_service_type_id,
            client_id: c2.id,
            confirmed: true, # ignore warnings, they are tested separately
            **mock_form_values_for_definition(definition) do |values|
              if role == :FILE
                # FIXME make this not depend on specific Link IDs in the file form
                values[:values]['file-blob-id'] = blob.id.to_s
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
              c2.id
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
            when :HMIS_PARTICIPATION
              hmis_particip1.id
            when :CE_PARTICIPATION
              ce_particip1.id
            when :SERVICE
              hmis_hud_service1.id
            when :FILE
              file1.id
            when :ENROLLMENT
              e1.id
            when :CE_ASSESSMENT
              a1.id
            when :CASE_NOTE
              custom_case_note.id
            when :CE_EVENT
              evt1.id
            end

            input = input_proc.call(test_input.merge(record_id: input_record_id))
            if role == :ENROLLMENT && test_name == 'should create a new record'
              fresh_client = create(:hmis_hud_client_complete, data_source: ds1)
              input[:client_id] = fresh_client.id
              input.delete(:enrollment_id)
            end

            # delete processing jobs that would have been queued from factory record creation
            Delayed::Job.jobs_for_class(['GrdaWarehouse::Tasks::ServiceHistory::Enrollment', 'GrdaWarehouse::Tasks::IdentifyDuplicates']).delete_all
            # mark enrollment record as processed
            e1.update!(processed_as: 'PROCESSED', processed_hash: 'PROCESSED') if input[:record_id].present?

            record, errors = submit_form(input)
            record_id = record['id']

            aggregate_failures 'checking response' do
              expect(errors).to be_empty
              expect(record).to be_present
              record_id = record['id']
              expect(record_id).to eq(input[:record_id].to_s) if input[:record_id].present?
              record = definition.owner_class.find_by(id: record_id)
              record = record.owner if record.is_a? Hmis::Hud::HmisService # we want to assert on the underlying Service/CustomService model
              expect(record).to be_present

              expect(Hmis::Form::FormProcessor.where(owner: record).count).to eq(1)
              expect(record.form_processor).to be_present

              # Check that enrollment.processed_as: nil and enrollment.processed_hash: nil, but weren't nil before save
              # this should be true if exit, CLS, Service, or Enrollment changed/added/deleted
              expect(e1.reload.processed_as).to be_nil if role.in?([:ENROLLMENT, :SERVICE, :CURRENT_LIVING_SITUATION])

              # check that delayed jobs are queued for when above happens or client is changed
              expect(Delayed::Job.jobs_for_class('GrdaWarehouse::Tasks::ServiceHistory::Enrollment').count).to be_positive if role.in?([:ENROLLMENT, :SERVICE, :CURRENT_LIVING_SITUATION])

              expect(Delayed::Job.jobs_for_class('GrdaWarehouse::Tasks::IdentifyDuplicates').count).to be_positive if role.in?([:CLIENT])

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

          expected_error = {
            type: :required,
            attribute: required_item.mapping.field_name,
            severity: :error,
          }
          record, errors = submit_form(input)

          aggregate_failures 'checking response' do
            expect(record).to be_nil
            expect(errors).to include(
              a_hash_including(**expected_error.transform_keys(&:to_s).transform_values(&:to_s)),
            )
          end
        end

        it 'should fail if user lacks permission' do
          remove_permissions(access_control, *definition.record_editing_permissions)
          expect_gql_error post_graphql(input: { input: test_input }) { mutation }, message: 'access denied'
        end

        it 'should update user correctly' do
          next if role == :REFERRAL # skip for referral, tested separately

          if role == :ENROLLMENT
            _response, result = post_graphql(input: { input: test_input.merge(record_id: e1.id) }) { mutation }
          else
            _response, result = post_graphql(input: { input: test_input }) { mutation }
          end

          expect(result.dig('data', 'submitForm', 'errors')).to be_blank
          record_id = result.dig('data', 'submitForm', 'record', 'id')
          record = definition.owner_class.find_by(id: record_id)

          # FIXME refactor this out to its own file test
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
          record = definition.owner_class.find_by(id: record_id)

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
        **mock_form_values_for_definition(definition),
        confirmed: false,
      }
    end

    def merge_hud_values(input, *args)
      input.merge(hud_values: input[:hud_values].merge(*args))
    end

    context 'with open enrollments' do
      let(:today) { Date.current }
      let!(:project) { create :hmis_hud_project, data_source: ds1, organization: o1, with_coc: true, operating_end_date: nil }
      let!(:enrollment) { create :hmis_hud_enrollment, data_source: ds1, project: project, entry_date: 1.month.ago }
      let!(:exited_enrollment) { create :hmis_hud_enrollment, data_source: ds1, project: project, entry_date: 1.month.ago, exit_date: 2.days.ago }

      def close_project(date = today, proj = project)
        input = merge_hud_values(
          test_input.merge(confirmed: false, record_id: proj.id),
          'operatingEndDate' => date.strftime('%Y-%m-%d'),
        )
        post_graphql(input: { input: input }) { mutation }
      end

      it 'should warn if changing the end date for a project with open enrollments' do
        response, result = close_project
        record_id = result.dig('data', 'submitForm', 'record', 'id')
        errors = result.dig('data', 'submitForm', 'errors')
        project.reload
        aggregate_failures 'checking response' do
          expect(response.status).to eq(200), result&.inspect
          expect(record_id).to be_nil
          expect(project.operating_end_date).to be_nil # didn't update
          expect(errors).to contain_exactly(include('severity' => 'warning', 'type' => 'information', 'fullMessage' => Hmis::Hud::Validators::ProjectValidator.open_enrollments_message(1)))
        end
      end

      it 'should not warn about enrollments that exited today' do
        # exit the enrollment today
        create(:hmis_hud_exit, enrollment: enrollment, client: enrollment.client, data_source: ds1, exit_date: today)

        _, result = close_project
        errors = result.dig('data', 'submitForm', 'errors')
        expect(errors).to be_empty
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
        expect(response.status).to eq(200), result&.inspect
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
        expect(response.status).to eq(200), result&.inspect
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
        'operatingEndDate' => Date.current.strftime('%Y-%m-%d'),
      )

      response, result = post_graphql(input: { input: input }) { mutation }
      record_id = result.dig('data', 'submitForm', 'record', 'id')
      errors = result.dig('data', 'submitForm', 'errors')
      p1.reload
      aggregate_failures 'checking response' do
        expect(response.status).to eq(200), result&.inspect
        expect(record_id).to be_nil
        expect(p1.operating_end_date).to be_nil
        expect(errors).to contain_exactly(
          a_hash_including('severity' => 'warning', 'type' => 'information', 'fullMessage' => Hmis::Hud::Validators::ProjectValidator.open_funders_message(1)),
          a_hash_including('severity' => 'warning', 'type' => 'information', 'fullMessage' => Hmis::Hud::Validators::ProjectValidator.open_inventory_message(1)),
        )
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
        'operatingEndDate' => Date.current.strftime('%Y-%m-%d'),
      )

      response, result = post_graphql(input: { input: input }) { mutation }
      record_id = result.dig('data', 'submitForm', 'record', 'id')
      errors = result.dig('data', 'submitForm', 'errors')
      p1.reload
      aggregate_failures 'checking response' do
        expect(response.status).to eq(200), result&.inspect
        expect(record_id).to be_present
        expect(errors.length).to eq(0)
        expect(p1.reload.operating_end_date).to be_present
        expect(i1.reload.inventory_end_date).to be_present
        expect(f1.reload.end_date).to be_present
      end
    end
  end

  describe 'SubmitForm for Enrollment creation' do
    let(:definition) { Hmis::Form::Definition.find_by(role: :ENROLLMENT) }
    let!(:c3) { create :hmis_hud_client_complete, data_source: ds1 }
    let(:test_input) do
      {
        form_definition_id: definition.id,
        **mock_form_values_for_definition(definition),
        project_id: p2.id,
        client_id: c3.id,
        confirmed: false,
      }
    end

    def merge_hud_values(input, *args)
      input.merge(hud_values: input[:hud_values].merge(*args))
    end

    def expect_error_message(input, exact: true, **expected_error)
      response, result = post_graphql(input: { input: input }) { mutation }
      errors = result.dig('data', 'submitForm', 'errors')
      aggregate_failures 'checking response' do
        expect(response.status).to eq(200), result&.inspect
        if exact
          expect(errors).to contain_exactly(include(expected_error.stringify_keys))
        else
          expect(errors).to include(include(expected_error.stringify_keys))
        end
      end
    end

    it 'should error if adding second HoH to existing household' do
      input = merge_hud_values(
        test_input,
        'householdId' => e1.household_id,
      )
      expect_error_message(input, fullMessage: Hmis::Hud::Validators::EnrollmentValidator.one_hoh_full_message)
    end

    it 'should error if creating household without hoh' do
      input = merge_hud_values(
        test_input,
        'relationshipToHoH' => Types::HmisSchema::Enums::Hud::RelationshipToHoH.key_for(2),
      )
      expect_error_message(input, fullMessage: Hmis::Hud::Validators::EnrollmentValidator.first_member_hoh_full_message)
    end

    it 'should error if client already has an open enrollment in the household' do
      e2 = create(:hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: '2000-01-01', household_id: e1.household_id)
      input = merge_hud_values(
        test_input.merge(client_id: e2.client.id),
        'householdId' => e1.household_id,
        'relationshipToHoH' => Types::HmisSchema::Enums::Hud::RelationshipToHoH.key_for(2),
      )
      expect_error_message(input, exact: false, fullMessage: Hmis::Hud::Validators::EnrollmentValidator.duplicate_member_full_message)
    end

    it 'should not error if client has a closed enrollment in the household' do
      e2 = create(:hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: '2000-01-01', household_id: e1.household_id)
      create(:hmis_hud_exit, enrollment: e2, client: e2.client, data_source: ds1, exit_date: '2001-01-01')
      input = merge_hud_values(
        test_input.merge(client_id: e2.client.id),
        'householdId' => e1.household_id,
        'relationshipToHoH' => Types::HmisSchema::Enums::Hud::RelationshipToHoH.key_for(2),
      )
      response, result = post_graphql(input: { input: input }) { mutation }
      errors = result.dig('data', 'submitForm', 'errors')
      expect(response.status).to eq(200), result&.inspect
      expect(errors).to be_empty
      household_size = result.dig('data', 'submitForm', 'record', 'householdSize')
      expect(household_size).to eq(2) # household size is 2 even though it contains 3 enrollments
    end

    it 'should warn if client already enrolled' do
      input = merge_hud_values(
        test_input.merge(client_id: e1.client.id, project_id: e1.project.id),
      )
      expect_error_message(input, fullMessage: Hmis::Hud::Validators::EnrollmentValidator.already_enrolled_full_message)
    end

    it 'should error if entry date is in the future' do
      input = merge_hud_values(
        test_input,
        'entryDate' => Date.tomorrow.strftime('%Y-%m-%d'),
      )
      expect_error_message(input, message: Hmis::Hud::Validators::EnrollmentValidator.future_message)
    end
  end

  describe 'SubmitForm for Enrollment updates' do
    let(:definition) { Hmis::Form::Definition.find_by(role: :ENROLLMENT) }
    let(:e1) { create :hmis_hud_enrollment, data_source: ds1 }
    let(:wip_e1) { create :hmis_hud_wip_enrollment, data_source: ds1 }
    let(:test_input) do
      {
        form_definition_id: definition.id,
        **mock_form_values_for_definition(definition),
        project_id: p1.id,
        client_id: c2.id,
        confirmed: false,
      }
    end

    it 'should save new enrollment as WIP' do
      record, _errors = submit_form(test_input)
      expect(record['inProgress']).to eq(true)
    end

    it 'should not change WIP status (WIP enrollment)' do
      input = test_input.merge(record_id: wip_e1.id)
      submit_form(input)
      wip_e1.reload
      expect(wip_e1.in_progress?).to eq(true)
    end

    it 'should not change WIP status (non-WIP enrollment)' do
      input = test_input.merge(record_id: e1.id)
      submit_form(input)
      e1.reload
      expect(e1.in_progress?).to eq(false)
    end
  end

  describe 'SubmitForm for Enrollment on project with ProjectAutoEnterConfig' do
    let(:definition) { Hmis::Form::Definition.find_by(role: :ENROLLMENT) }
    let!(:aec) { create :hmis_project_auto_enter_config, project: p1 }
    let(:test_input) do
      {
        form_definition_id: definition.id,
        **mock_form_values_for_definition(definition),
        project_id: p1.id,
        client_id: c1.id,
        confirmed: false,
      }
    end

    it 'should save new enrollment without WIP status' do
      record, errors = submit_form(test_input)
      expect(errors).to be_empty

      enrollment = Hmis::Hud::Enrollment.find_by(id: record['id'])
      expect(enrollment).to be_present
      expect(enrollment.in_progress?).to eq(false)
      expect(enrollment.intake_assessment).to be_present
      expect(enrollment.intake_assessment.assessment_date).to eq(enrollment.entry_date)
      expect(enrollment.intake_assessment.wip).to eq(false)
      expect(enrollment.intake_assessment.form_processor).to be_present
    end
  end

  describe 'SubmitForm for Create+Enroll' do
    let(:definition) { Hmis::Form::Definition.find_by(role: :NEW_CLIENT_ENROLLMENT) }
    let(:test_input) do
      {
        form_definition_id: definition.id,
        **mock_form_values_for_definition(definition),
        project_id: p2.id,
        confirmed: true,
      }
    end

    def merge_hud_values(input, *args)
      input.merge(hud_values: input[:hud_values].merge(*args))
    end

    it 'creates client and enrollment' do
      record, errors = submit_form(test_input)
      expect(errors).to be_empty
      expect(record).to be_present

      enrollment = Hmis::Hud::Enrollment.find(record['id'])
      expect(enrollment.client).to be_present
      expect(enrollment.client.first_name).to eq('First')
    end

    it 'validates client (invalid field)' do
      input = merge_hud_values(
        test_input,
        'Client.dobDataQuality' => 'INVALID',
      )
      _, errors = submit_form(input)
      expect(errors).to contain_exactly(include({ 'attribute' => 'dobDataQuality', 'type' => 'invalid' }))
    end

    it 'validates client (invalid DOB)' do
      input = merge_hud_values(
        test_input,
        'Client.dob' => '2200-01-01', # future dob is not valid
      )
      _, errors = submit_form(input)
      expect(errors).to contain_exactly(include({ 'attribute' => 'dob', 'type' => 'out_of_range' }))
    end
  end

  describe 'SubmitForm for creating a ReferralPosting' do
    let(:definition_json) do
      {
        "item": [
          {
            # Unit Type
            "type": 'CHOICE',
            "required": false,
            "link_id": 'referral_unit_type',
            "text": 'Unit Type',
            "pick_list_reference": 'AVAILABLE_UNIT_TYPES',
            "mapping": {
              "field_name": 'unitTypeId',
            },
          },
          {
            # Notes
            "type": 'TEXT',
            "required": false,
            "link_id": 'referral_resource_coordinator_notes',
            "text": 'Referral Notes',
            "mapping": {
              "field_name": 'resourceCoordinatorNotes',
            },
          },
          {
            # Custom Data Element
            "type": 'STRING',
            "required": false,
            "link_id": 'referral_custom_question',
            "mapping": {
              "custom_field_key": 'referral_custom_question',
            },
          },
        ],
      }
    end
    let!(:definition) { create :hmis_form_definition, role: :REFERRAL, definition: definition_json }
    # Custom Data Element definition on referral
    let!(:cded) { create :hmis_custom_data_element_definition, owner_type: 'HmisExternalApis::AcHmis::ReferralPosting', key: :referral_custom_question, data_source: ds1, field_type: :string }
    # Unit type to refer to
    let!(:unit_type) { create :hmis_unit_type }
    # Available unit to refer to in receiving project
    let!(:unit) { create :hmis_unit, project: p2, unit_type: unit_type }

    # "Source" household being referred from p1
    let!(:hoh) { create :hmis_hud_enrollment, data_source: ds1, project: p1 }
    let!(:other_member) { create :hmis_hud_enrollment, data_source: ds1, project: p1, household_id: hoh.household_id, relationship_to_hoh: 99 }

    let(:test_input) do
      {
        form_definition_id: definition.id,
        values: {},
        hud_values: {
          'unitTypeId' => unit_type.id.to_s,
          'resourceCoordinatorNotes' => 'note here',
          'referral_custom_question' => 'custom response',
        },
        enrollment_id: hoh.id,
        project_id: p2.id,
        confirmed: true,
      }
    end

    it 'creates referral posting with unit type, notes, and custom data element' do
      record, errors = submit_form(test_input)
      expect(errors).to be_empty
      expect(record).to be_present

      posting = HmisExternalApis::AcHmis::ReferralPosting.find(record['id'])
      # Validate ReferralPosting
      expect(posting.identifier).to be_nil
      expect(posting.unit_type_id).to eq(unit_type.id)
      expect(posting.project).to eq(p2)
      expect(posting.household_id).to be_nil # only gets filled when referral is accepted
      expect(posting.status).to eq('assigned_status')
      expect(posting.resource_coordinator_notes).to eq('note here')
      expect(posting.status_updated_by_id).to eq(hmis_user.id)
      # Validate Referral
      expect(posting.referral.service_coordinator).to eq(hmis_user.name)
      expect(posting.referral.enrollment).to eq(hoh)
      # Validate Household members
      expect(posting.referral.household_members.pluck(:client_id)).to contain_exactly(hoh.client.id, other_member.client.id)
      # Validate Custom Data Element
      expect(posting.custom_data_elements.count).to eq(1)
      expect(posting.custom_data_elements.first.value_string).to eq('custom response')
      expect(posting.custom_data_elements.first.data_element_definition).to eq(cded)
    end

    it 'fails if unit type does not exist in project' do
      unit.destroy!
      record, errors = submit_form(test_input)
      expect(errors).to contain_exactly(
        include('attribute' => 'unitTypeId', 'fullMessage' => 'Unit type is not available in the selected project'),
      )
      expect(record).to be_nil
      expect(HmisExternalApis::AcHmis::ReferralPosting.count).to eq(0)
    end
    it 'fails if unit type exists but is occupied' do
      create(:hmis_unit_occupancy, unit: unit)
      record, errors = submit_form(test_input)
      expect(errors).to contain_exactly(
        include('attribute' => 'unitTypeId', 'fullMessage' => 'Unit type is not available in the selected project'),
      )
      expect(record).to be_nil
      expect(HmisExternalApis::AcHmis::ReferralPosting.count).to eq(0)
    end
    it 'succeeds if optional fields are not included (unit type and notes)' do
      record, errors = submit_form(test_input.merge(hud_values: {}))
      expect(errors).to be_empty

      posting = HmisExternalApis::AcHmis::ReferralPosting.find(record['id'])
      expect(posting.referral.enrollment).to eq(hoh)
      expect(posting.project).to eq(p2)
      expect(posting.status).to eq('assigned_status')
    end

    context 'referral permissions' do
      before(:each) { access_control.destroy! } # remove blanket access

      [:can_manage_outgoing_referrals, :can_view_enrollment_details, :can_view_project].each do |permission|
        it "fails when referer lacks #{permission} in source project" do
          create_access_control(hmis_user, p1, without_permission: permission)
          expect_gql_error post_graphql(input: { input: test_input }) { mutation }, message: 'access denied'
        end
      end

      it 'succeeds when referer lacks access to receiving project' do
        # User has access to refer from p1, but no access to p2
        create_access_control(hmis_user, p1, with_permission: [:can_manage_outgoing_referrals, :can_view_project, :can_view_enrollment_details])
        expect(Hmis::Hud::Project.viewable_by(hmis_user).where(id: p2.id).exists?).to be false # confirm setup

        _, errors = submit_form(test_input)
        expect(errors).to be_empty
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
  c.include FormHelpers
end
