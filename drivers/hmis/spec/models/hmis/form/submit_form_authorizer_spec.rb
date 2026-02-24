###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Form::SubmitFormAuthorizer, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let(:organization) { create(:hmis_hud_organization, data_source: data_source) }
  let(:project) { create(:hmis_hud_project, organization: organization, data_source: data_source) }
  let(:client) { create(:hmis_hud_client, data_source: data_source) }
  let(:user) { create(:hmis_user, data_source: data_source) }

  def make_definition(owner_class:, role: 'FORM')
    instance_double('Hmis::Form::Definition', owner_class: owner_class, role: role)
  end

  def make_input(**attrs)
    defaults = { record_id: nil, project_id: nil, client_id: nil, enrollment_id: nil, organization_id: nil, service_type_id: nil }
    OpenStruct.new(defaults.merge(attrs))
  end

  def authorized_record(definition:, input:)
    described_class.authorized_record(user: user, definition: definition, input: input)
  end

  # `with_permission` - permission(s) to grant
  # `returns_new` - for new-record cases, the expected class of the returned record
  # When `returns_new` is omitted, the examples expect `expected_record` to be defined as a fixture
  shared_examples 'authorized form submission' do |with_permission:, returns_new: nil|
    context 'with required permission' do
      before { create_access_control(user, data_source, with_permission: with_permission) }

      it 'returns authorized record' do
        result = authorized_record(definition: definition, input: input)
        if returns_new
          expect(result).to be_a(returns_new)
        else
          expect(result).to eq(expected_record)
        end
      end
    end

    it 'raises without permission' do
      expect { authorized_record(definition: definition, input: input) }.to raise_error(HmisErrors::ApiError)
    end
  end

  describe '.authorized_record' do
    context 'Client' do
      let(:definition) { make_definition(owner_class: Hmis::Hud::Client) }

      context 'new record' do
        let(:input) { make_input }

        it_behaves_like 'authorized form submission',
                        with_permission: [:can_view_clients, :can_edit_clients],
                        returns_new: Hmis::Hud::Client
      end

      context 'existing record' do
        let!(:enrollment) { create(:hmis_hud_enrollment, client: client, project: project, data_source: data_source) }
        let(:input) { make_input(record_id: client.id) }
        let(:expected_record) { client }

        it_behaves_like 'authorized form submission',
                        with_permission: [:can_view_clients, :can_edit_clients]
      end
    end

    context 'Organization' do
      let(:definition) { make_definition(owner_class: Hmis::Hud::Organization) }

      context 'new record' do
        let(:input) { make_input }

        it_behaves_like 'authorized form submission',
                        with_permission: [:can_view_project, :can_edit_organization],
                        returns_new: Hmis::Hud::Organization
      end

      context 'existing record' do
        let(:input) { make_input(record_id: organization.id) }
        let(:expected_record) { organization }

        it_behaves_like 'authorized form submission',
                        with_permission: [:can_view_project, :can_edit_organization]
      end
    end

    context 'Project' do
      let(:definition) { make_definition(owner_class: Hmis::Hud::Project) }

      context 'new record' do
        let(:input) { make_input(organization_id: organization.id) }

        it_behaves_like 'authorized form submission',
                        with_permission: [:can_view_project, :can_edit_project_details],
                        returns_new: Hmis::Hud::Project
      end

      context 'existing record' do
        let(:input) { make_input(record_id: project.id) }
        let(:expected_record) { project }

        it_behaves_like 'authorized form submission',
                        with_permission: [:can_view_project, :can_edit_project_details]
      end
    end

    context 'project-related records (Funder, Inventory, etc.)' do
      let(:definition) { make_definition(owner_class: Hmis::Hud::Funder) }

      context 'new record' do
        let(:input) { make_input(project_id: project.id) }

        it_behaves_like 'authorized form submission',
                        with_permission: [:can_view_project, :can_edit_project_details],
                        returns_new: Hmis::Hud::Funder
      end

      context 'existing record' do
        let!(:funder) { create(:hmis_hud_funder, project: project, data_source: data_source) }
        let(:input) { make_input(record_id: funder.id) }
        let(:expected_record) { funder }

        it_behaves_like 'authorized form submission',
                        with_permission: [:can_view_project, :can_edit_project_details]
      end
    end

    context 'Enrollment' do
      context 'new record (ENROLLMENT form role)' do
        let(:definition) { make_definition(owner_class: Hmis::Hud::Enrollment, role: 'ENROLLMENT') }
        let(:input) { make_input(project_id: project.id, client_id: client.id) }

        it_behaves_like 'authorized form submission',
                        with_permission: [:can_view_project, :can_view_enrollment_details, :can_edit_enrollments],
                        returns_new: Hmis::Hud::Enrollment
      end

      context 'new record (NEW_CLIENT_ENROLLMENT role, creates both enrollment and client)' do
        let(:definition) { make_definition(owner_class: Hmis::Hud::Enrollment, role: 'NEW_CLIENT_ENROLLMENT') }
        let(:input) { make_input(project_id: project.id) }

        it 'returns new enrollment when user can enroll and create clients' do
          create_access_control(user, project, with_permission: [:can_view_project, :can_view_clients, :can_edit_clients, :can_view_enrollment_details, :can_edit_enrollments])
          expect(authorized_record(definition: definition, input: input)).to be_a(Hmis::Hud::Enrollment)
        end

        it 'raises when user cannot create clients' do
          create_access_control(user, project, with_permission: [:can_view_project, :can_view_clients, :can_view_enrollment_details, :can_edit_enrollments])
          expect { authorized_record(definition: definition, input: input) }.to raise_error(HmisErrors::ApiError)
        end

        it 'raises when user cannot enroll clients' do
          create_access_control(user, project, with_permission: [:can_view_project, :can_view_clients, :can_edit_clients, :can_view_enrollment_details])
          expect { authorized_record(definition: definition, input: input) }.to raise_error(HmisErrors::ApiError)
        end
      end

      context 'existing record' do
        let!(:enrollment) { create(:hmis_hud_enrollment, client: client, project: project, data_source: data_source) }
        let(:definition) { make_definition(owner_class: Hmis::Hud::Enrollment, role: 'ENROLLMENT') }
        let(:input) { make_input(record_id: enrollment.id) }
        let(:expected_record) { enrollment }

        it_behaves_like 'authorized form submission',
                        with_permission: [:can_view_project, :can_view_enrollment_details, :can_edit_enrollments]
      end
    end

    context 'enrollment-related records (CaseNote, Event, etc.)' do
      let!(:enrollment) { create(:hmis_hud_enrollment, client: client, project: project, data_source: data_source) }

      context 'new CustomCaseNote' do
        let(:definition) { make_definition(owner_class: Hmis::Hud::CustomCaseNote) }
        let(:input) { make_input(enrollment_id: enrollment.id) }

        it_behaves_like 'authorized form submission',
                        with_permission: [:can_view_project, :can_view_enrollment_details, :can_edit_enrollments],
                        returns_new: Hmis::Hud::CustomCaseNote
      end

      context 'existing Assessment' do
        let!(:assessment) { create(:hmis_hud_assessment, client: client, enrollment: enrollment, data_source: data_source) }
        let(:definition) { make_definition(owner_class: Hmis::Hud::Assessment) }
        let(:input) { make_input(record_id: assessment.id) }
        let(:expected_record) { assessment }

        it_behaves_like 'authorized form submission',
                        with_permission: [:can_view_project, :can_view_enrollment_details, :can_edit_enrollments]
      end
    end

    context 'HmisService' do
      let!(:enrollment) { create(:hmis_hud_enrollment, client: client, project: project, data_source: data_source) }
      let(:definition) { make_definition(owner_class: Hmis::Hud::HmisService) }

      context 'new record with HUD service type (creates Hmis::Hud::Service)' do
        let(:custom_service_type) { create(:hmis_hud_custom_service_type, data_source: data_source) }
        let(:input) { make_input(enrollment_id: enrollment.id, service_type_id: custom_service_type.id) }

        it_behaves_like 'authorized form submission',
                        with_permission: [:can_view_project, :can_view_enrollment_details, :can_edit_enrollments],
                        returns_new: Hmis::Hud::Service
      end

      context 'new record with custom service type (creates Hmis::Hud::CustomService)' do
        let(:custom_service_type) { create(:hmis_custom_service_type, data_source: data_source) }
        let(:input) { make_input(enrollment_id: enrollment.id, service_type_id: custom_service_type.id) }

        it_behaves_like 'authorized form submission',
                        with_permission: [:can_view_project, :can_view_enrollment_details, :can_edit_enrollments],
                        returns_new: Hmis::Hud::CustomService
      end

      context 'new record without service_type_id' do
        let(:input) { make_input(enrollment_id: enrollment.id) }

        it 'raises when service_type_id is missing' do
          create_access_control(user, project, with_permission: [:can_view_project, :can_view_enrollment_details, :can_edit_enrollments])
          expect { authorized_record(definition: definition, input: input) }.to raise_error(RuntimeError, /service type/)
        end
      end

      context 'existing service record' do
        let!(:service) { create(:hmis_hud_service, enrollment: enrollment, client: client, data_source: data_source) }
        let(:hmis_service) { Hmis::Hud::HmisService.find_by(owner: service) }
        let(:input) { make_input(record_id: hmis_service.id) }
        let(:expected_record) { service }

        it_behaves_like 'authorized form submission',
                        with_permission: [:can_view_project, :can_view_enrollment_details, :can_edit_enrollments]
      end
    end

    context 'Hmis::File' do
      let!(:enrollment) { create(:hmis_hud_enrollment, client: client, project: project, data_source: data_source) }
      let(:definition) { make_definition(owner_class: Hmis::File) }

      context 'new record' do
        let(:input) { make_input(client_id: client.id) }

        it_behaves_like 'authorized form submission',
                        with_permission: [:can_view_clients, :can_view_any_nonconfidential_client_files, :can_manage_any_client_files],
                        returns_new: Hmis::File
      end

      context 'existing record' do
        let!(:file) { create(:file, :skip_validate, client: client, user: user) }
        let(:input) { make_input(record_id: file.id) }
        let(:expected_record) { file }

        it_behaves_like 'authorized form submission',
                        with_permission: [:can_view_clients, :can_view_any_nonconfidential_client_files, :can_manage_any_client_files]
      end
    end
  end
end
