###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::AuthPolicies::SubmitFormAuthorizer, type: :model do
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

  def can_submit?(definition:, input:)
    described_class.authorized_record(user: user, definition: definition, input: input)
    true
  rescue HmisErrors::ApiError
    false
  end

  describe '.authorized_record' do
    context 'Client (new record)' do
      let(:definition) { make_definition(owner_class: Hmis::Hud::Client) }
      let(:input) { make_input }

      it 'returns record when user has can_edit_clients' do
        create_access_control(user, project, with_permission: [:can_view_clients, :can_edit_clients])
        expect(can_submit?(definition: definition, input: input)).to be true
      end

      it 'raises without can_edit_clients' do
        expect(can_submit?(definition: definition, input: input)).to be false
      end
    end

    context 'Client (existing record)' do
      let!(:enrollment) { create(:hmis_hud_enrollment, client: client, project: project, data_source: data_source) }
      let(:definition) { make_definition(owner_class: Hmis::Hud::Client) }
      let(:input) { make_input(record_id: client.id) }

      it 'returns record when user has can_edit_clients' do
        create_access_control(user, project, with_permission: [:can_view_clients, :can_edit_clients])
        expect(can_submit?(definition: definition, input: input)).to be true
      end

      it 'raises without can_edit_clients' do
        expect(can_submit?(definition: definition, input: input)).to be false
      end
    end

    context 'Organization (new record)' do
      let(:definition) { make_definition(owner_class: Hmis::Hud::Organization) }
      let(:input) { make_input }

      it 'returns record when user has can_edit_organization' do
        create_access_control(user, organization, with_permission: :can_edit_organization)
        expect(can_submit?(definition: definition, input: input)).to be true
      end

      it 'raises without can_edit_organization' do
        expect(can_submit?(definition: definition, input: input)).to be false
      end
    end

    context 'Project (new record)' do
      let(:definition) { make_definition(owner_class: Hmis::Hud::Project) }
      let(:input) { make_input(organization_id: organization.id) }

      it 'returns record when user has can_edit_project_details' do
        create_access_control(user, organization, with_permission: [:can_view_project, :can_edit_project_details])
        expect(can_submit?(definition: definition, input: input)).to be true
      end

      it 'raises without can_edit_project_details' do
        expect(can_submit?(definition: definition, input: input)).to be false
      end
    end

    context 'Project (existing record)' do
      let(:definition) { make_definition(owner_class: Hmis::Hud::Project) }
      let(:input) { make_input(record_id: project.id) }

      it 'returns record when user has can_edit_project_details' do
        create_access_control(user, project, with_permission: [:can_view_project, :can_edit_project_details])
        expect(can_submit?(definition: definition, input: input)).to be true
      end

      it 'raises without can_edit_project_details' do
        expect(can_submit?(definition: definition, input: input)).to be false
      end
    end

    context 'project-related records (Funder, Inventory, etc.)' do
      context 'new record' do
        let(:definition) { make_definition(owner_class: Hmis::Hud::Funder) }
        let(:input) { make_input(project_id: project.id) }

        it 'returns record when user has can_edit_project_details' do
          create_access_control(user, project, with_permission: [:can_view_project, :can_edit_project_details])
          expect(can_submit?(definition: definition, input: input)).to be true
        end

        it 'raises without can_edit_project_details' do
          expect(can_submit?(definition: definition, input: input)).to be false
        end
      end

      context 'existing record' do
        let!(:funder) { create(:hmis_hud_funder, project: project, data_source: data_source) }
        let(:definition) { make_definition(owner_class: Hmis::Hud::Funder) }
        let(:input) { make_input(record_id: funder.id) }

        it 'returns record when user has can_edit_project_details' do
          create_access_control(user, project, with_permission: [:can_view_project, :can_edit_project_details])
          expect(can_submit?(definition: definition, input: input)).to be true
        end

        it 'raises without can_edit_project_details' do
          expect(can_submit?(definition: definition, input: input)).to be false
        end
      end
    end

    context 'Enrollment (new record)' do
      let(:definition) { make_definition(owner_class: Hmis::Hud::Enrollment, role: 'ENROLLMENT') }
      let(:input) { make_input(project_id: project.id, client_id: client.id) }

      it 'returns record when user has can_edit_enrollments' do
        create_access_control(user, project, with_permission: [:can_view_project, :can_view_enrollment_details, :can_edit_enrollments])
        expect(can_submit?(definition: definition, input: input)).to be true
      end

      it 'raises without can_edit_enrollments' do
        expect(can_submit?(definition: definition, input: input)).to be false
      end
    end

    context 'Enrollment (existing record)' do
      let!(:enrollment) { create(:hmis_hud_enrollment, client: client, project: project, data_source: data_source) }
      let(:definition) { make_definition(owner_class: Hmis::Hud::Enrollment, role: 'ENROLLMENT') }
      let(:input) { make_input(record_id: enrollment.id) }

      it 'returns record when user has can_edit_enrollments' do
        create_access_control(user, project, with_permission: [:can_view_project, :can_view_enrollment_details, :can_edit_enrollments])
        expect(can_submit?(definition: definition, input: input)).to be true
      end

      it 'raises without can_edit_enrollments' do
        expect(can_submit?(definition: definition, input: input)).to be false
      end
    end

    context 'enrollment-related records (Service, CaseNote, Event, etc.)' do
      let!(:enrollment) { create(:hmis_hud_enrollment, client: client, project: project, data_source: data_source) }

      context 'new CustomCaseNote' do
        let(:definition) { make_definition(owner_class: Hmis::Hud::CustomCaseNote) }
        let(:input) { make_input(enrollment_id: enrollment.id) }

        it 'returns record when user has can_edit_enrollments' do
          create_access_control(user, project, with_permission: [:can_view_project, :can_view_enrollment_details, :can_edit_enrollments])
          expect(can_submit?(definition: definition, input: input)).to be true
        end

        it 'raises without can_edit_enrollments' do
          expect(can_submit?(definition: definition, input: input)).to be false
        end
      end

      context 'existing Assessment' do
        let!(:assessment) { create(:hmis_hud_assessment, client: client, enrollment: enrollment, data_source: data_source) }
        let(:definition) { make_definition(owner_class: Hmis::Hud::Assessment) }
        let(:input) { make_input(record_id: assessment.id) }

        it 'returns record when user has can_edit_enrollments' do
          create_access_control(user, project, with_permission: [:can_view_project, :can_view_enrollment_details, :can_edit_enrollments])
          expect(can_submit?(definition: definition, input: input)).to be true
        end

        it 'raises without can_edit_enrollments' do
          expect(can_submit?(definition: definition, input: input)).to be false
        end
      end
    end
  end
end
