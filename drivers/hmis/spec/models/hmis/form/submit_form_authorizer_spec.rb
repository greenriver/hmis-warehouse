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

  describe '#authorized_to_create?' do
    subject(:authorizer) { described_class.new(user: user, definition: definition) }

    context 'Client' do
      let(:definition) { make_definition(owner_class: Hmis::Hud::Client) }
      let(:record) { Hmis::Hud::Client.new(data_source: data_source) }

      it 'returns true when user can create clients' do
        create_access_control(user, data_source, with_permission: [:can_view_clients, :can_edit_clients])
        expect(authorizer.authorized_to_create?(record)).to be true
      end

      it 'returns false when user cannot create clients' do
        create_access_control(user, data_source, with_permission: [:can_view_clients])
        expect(authorizer.authorized_to_create?(record)).to be false
      end
    end

    context 'Organization' do
      let(:definition) { make_definition(owner_class: Hmis::Hud::Organization) }
      let(:record) { Hmis::Hud::Organization.new(data_source: data_source) }

      it 'returns true when user can create organizations' do
        create_access_control(user, data_source, with_permission: [:can_view_project, :can_edit_organization])
        expect(authorizer.authorized_to_create?(record)).to be true
      end

      it 'returns false when user cannot create organizations' do
        expect(authorizer.authorized_to_create?(record)).to be false
      end
    end

    context 'Project' do
      let(:definition) { make_definition(owner_class: Hmis::Hud::Project) }
      let(:record) { Hmis::Hud::Project.new(organization: organization, data_source: data_source) }

      it 'returns true when user can create projects' do
        create_access_control(user, data_source, with_permission: [:can_view_project, :can_edit_project_details])
        expect(authorizer.authorized_to_create?(record)).to be true
      end

      it 'returns false when user cannot create projects' do
        create_access_control(user, data_source, with_permission: [:can_view_project])
        expect(authorizer.authorized_to_create?(record)).to be false
      end
    end

    context 'project-related records (Funder)' do
      let(:definition) { make_definition(owner_class: Hmis::Hud::Funder) }
      let(:record) { Hmis::Hud::Funder.new(project: project, data_source: data_source) }

      it 'returns true when user can edit project' do
        create_access_control(user, data_source, with_permission: [:can_view_project, :can_edit_project_details])
        expect(authorizer.authorized_to_create?(record)).to be true
      end

      it 'returns false when user cannot edit project' do
        create_access_control(user, data_source, with_permission: [:can_view_project])
        expect(authorizer.authorized_to_create?(record)).to be false
      end
    end

    context 'Enrollment (ENROLLMENT form role)' do
      let(:definition) { make_definition(owner_class: Hmis::Hud::Enrollment, role: 'ENROLLMENT') }
      let(:record) { Hmis::Hud::Enrollment.new(project: project, client: client, data_source: data_source) }

      it 'returns true when user can enroll clients' do
        create_access_control(user, data_source, with_permission: [:can_view_project, :can_view_enrollment_details, :can_edit_enrollments])
        expect(authorizer.authorized_to_create?(record)).to be true
      end

      it 'returns false when user cannot enroll clients' do
        create_access_control(user, data_source, with_permission: [:can_view_project, :can_view_clients])
        expect(authorizer.authorized_to_create?(record)).to be false
      end
    end

    context 'Enrollment (NEW_CLIENT_ENROLLMENT form role)' do
      let(:definition) { make_definition(owner_class: Hmis::Hud::Enrollment, role: 'NEW_CLIENT_ENROLLMENT') }
      let(:record) { Hmis::Hud::Enrollment.new(project: project, client: client, data_source: data_source) }

      it 'returns true when user can create and enroll new clients' do
        create_access_control(user, project, with_permission: [:can_view_project, :can_view_clients, :can_edit_clients, :can_view_enrollment_details, :can_edit_enrollments])
        expect(authorizer.authorized_to_create?(record)).to be true
      end

      it 'returns false when user cannot create clients' do
        create_access_control(user, project, with_permission: [:can_view_project, :can_view_clients, :can_view_enrollment_details, :can_edit_enrollments])
        expect(authorizer.authorized_to_create?(record)).to be false
      end

      context 'when user can create clients in a different project, but not this one' do
        let(:p2) { create(:hmis_hud_project, organization: organization, data_source: data_source) }
        before(:each) do
          create_access_control(user, project, with_permission: [:can_view_project, :can_view_clients, :can_view_enrollment_details, :can_edit_enrollments])
          create_access_control(user, p2, with_permission: [:can_view_project, :can_view_clients, :can_edit_clients])
        end

        it 'still returns false' do
          expect(authorizer.authorized_to_create?(record)).to be false
        end
      end

      it 'returns false when user cannot enroll clients' do
        create_access_control(user, project, with_permission: [:can_view_project, :can_view_clients, :can_edit_clients, :can_view_enrollment_details])
        expect(authorizer.authorized_to_create?(record)).to be false
      end
    end

    context 'enrollment-related records (CustomCaseNote)' do
      let!(:enrollment) { create(:hmis_hud_enrollment, client: client, project: project, data_source: data_source) }
      let(:definition) { make_definition(owner_class: Hmis::Hud::CustomCaseNote) }
      let(:record) { Hmis::Hud::CustomCaseNote.new(enrollment: enrollment, data_source: data_source) }

      it 'returns true when user can edit enrollments' do
        create_access_control(user, data_source, with_permission: [:can_view_project, :can_view_enrollment_details, :can_edit_enrollments])
        expect(authorizer.authorized_to_create?(record)).to be true
      end

      it 'returns false when user cannot edit enrollments' do
        create_access_control(user, data_source, with_permission: [:can_view_project, :can_view_enrollment_details])
        expect(authorizer.authorized_to_create?(record)).to be false
      end
    end

    context 'HmisService (Hud::Service)' do
      let!(:enrollment) { create(:hmis_hud_enrollment, client: client, project: project, data_source: data_source) }
      let(:definition) { make_definition(owner_class: Hmis::Hud::HmisService) }
      let(:record) { Hmis::Hud::Service.new(enrollment: enrollment, client: client, data_source: data_source) }

      it 'returns true when user can edit enrollments' do
        create_access_control(user, data_source, with_permission: [:can_view_project, :can_view_enrollment_details, :can_edit_enrollments])
        expect(authorizer.authorized_to_create?(record)).to be true
      end

      it 'returns false when user cannot edit enrollments' do
        create_access_control(user, data_source, with_permission: [:can_view_project, :can_view_enrollment_details])
        expect(authorizer.authorized_to_create?(record)).to be false
      end
    end

    context 'HmisService (Hud::CustomService)' do
      let!(:enrollment) { create(:hmis_hud_enrollment, client: client, project: project, data_source: data_source) }
      let(:definition) { make_definition(owner_class: Hmis::Hud::HmisService) }
      let(:record) { Hmis::Hud::CustomService.new(enrollment: enrollment, client: client, data_source: data_source) }

      it 'returns true when user can edit enrollments' do
        create_access_control(user, data_source, with_permission: [:can_view_project, :can_view_enrollment_details, :can_edit_enrollments])
        expect(authorizer.authorized_to_create?(record)).to be true
      end

      it 'returns false when user cannot edit enrollments' do
        create_access_control(user, data_source, with_permission: [:can_view_project, :can_view_enrollment_details])
        expect(authorizer.authorized_to_create?(record)).to be false
      end
    end

    context 'Hmis::File' do
      let(:definition) { make_definition(owner_class: Hmis::File) }
      let(:record) { Hmis::File.new(client: client) }

      it 'returns true when user can manage client files' do
        create_access_control(user, data_source, with_permission: [:can_view_clients, :can_view_any_nonconfidential_client_files, :can_manage_any_client_files])
        expect(authorizer.authorized_to_create?(record)).to be true
      end

      it 'returns false when user cannot manage client files' do
        create_access_control(user, data_source, with_permission: [:can_view_clients, :can_view_any_nonconfidential_client_files, :can_view_clients])
        expect(authorizer.authorized_to_create?(record)).to be false
      end
    end
  end

  describe '#authorized_to_edit?' do
    subject(:authorizer) { described_class.new(user: user, definition: definition) }

    context 'Client' do
      let(:definition) { make_definition(owner_class: Hmis::Hud::Client) }
      let(:record) { client }

      it 'returns true when user can edit clients' do
        create_access_control(user, data_source, with_permission: [:can_view_clients, :can_edit_clients])
        expect(authorizer.authorized_to_edit?(record)).to be true
      end

      it 'returns false when user cannot edit clients' do
        create_access_control(user, data_source, with_permission: [:can_view_clients])
        expect(authorizer.authorized_to_edit?(record)).to be false
      end
    end

    context 'Organization' do
      let(:definition) { make_definition(owner_class: Hmis::Hud::Organization) }
      let(:record) { organization }

      it 'returns true when user can edit organization' do
        create_access_control(user, data_source, with_permission: [:can_view_project, :can_edit_organization])
        expect(authorizer.authorized_to_edit?(record)).to be true
      end

      it 'returns false when user cannot edit organization' do
        create_access_control(user, data_source, with_permission: [:can_view_project])
        expect(authorizer.authorized_to_edit?(record)).to be false
      end
    end

    context 'Project' do
      let(:definition) { make_definition(owner_class: Hmis::Hud::Project) }
      let(:record) { project }

      it 'returns true when user can edit project' do
        create_access_control(user, data_source, with_permission: [:can_view_project, :can_edit_project_details])
        expect(authorizer.authorized_to_edit?(record)).to be true
      end

      it 'returns false when user cannot edit project' do
        create_access_control(user, data_source, with_permission: [:can_view_project])
        expect(authorizer.authorized_to_edit?(record)).to be false
      end
    end

    context 'project-related records (Funder)' do
      let!(:funder) { create(:hmis_hud_funder, project: project, data_source: data_source) }
      let(:definition) { make_definition(owner_class: Hmis::Hud::Funder) }
      let(:record) { funder }

      it 'returns true when user can edit project' do
        create_access_control(user, data_source, with_permission: [:can_view_project, :can_edit_project_details])
        expect(authorizer.authorized_to_edit?(record)).to be true
      end

      it 'returns false when user cannot edit project' do
        create_access_control(user, data_source, with_permission: [:can_view_project])
        expect(authorizer.authorized_to_edit?(record)).to be false
      end
    end

    context 'Enrollment' do
      let!(:enrollment) { create(:hmis_hud_enrollment, client: client, project: project, data_source: data_source) }
      let(:definition) { make_definition(owner_class: Hmis::Hud::Enrollment, role: 'ENROLLMENT') }
      let(:record) { enrollment }

      it 'returns true when user can edit enrollments' do
        create_access_control(user, data_source, with_permission: [:can_view_project, :can_view_enrollment_details, :can_edit_enrollments])
        expect(authorizer.authorized_to_edit?(record)).to be true
      end

      it 'returns false when user cannot edit enrollments' do
        create_access_control(user, data_source, with_permission: [:can_view_project, :can_view_enrollment_details])
        expect(authorizer.authorized_to_edit?(record)).to be false
      end
    end

    context 'Enrollment with NEW_CLIENT_ENROLLMENT form role' do
      let!(:enrollment) { create(:hmis_hud_enrollment, client: client, project: project, data_source: data_source) }
      let(:definition) { make_definition(owner_class: Hmis::Hud::Enrollment, role: 'NEW_CLIENT_ENROLLMENT') }
      let(:record) { enrollment }

      it 'raises because edit is not supported for this form role' do
        create_access_control(user, data_source, with_permission: [:can_view_project, :can_view_enrollment_details, :can_edit_enrollments])
        expect { authorizer.authorized_to_edit?(record) }.to raise_error(/Edit not supported for NEW_CLIENT_ENROLLMENT/)
      end
    end

    context 'enrollment-related records (Assessment)' do
      let!(:enrollment) { create(:hmis_hud_enrollment, client: client, project: project, data_source: data_source) }
      let!(:assessment) { create(:hmis_hud_assessment, client: client, enrollment: enrollment, data_source: data_source) }
      let(:definition) { make_definition(owner_class: Hmis::Hud::Assessment) }
      let(:record) { assessment }

      it 'returns true when user can edit enrollments' do
        create_access_control(user, data_source, with_permission: [:can_view_project, :can_view_enrollment_details, :can_edit_enrollments])
        expect(authorizer.authorized_to_edit?(record)).to be true
      end

      it 'returns false when user cannot edit enrollments' do
        create_access_control(user, data_source, with_permission: [:can_view_project, :can_view_enrollment_details])
        expect(authorizer.authorized_to_edit?(record)).to be false
      end
    end

    context 'HmisService (existing service)' do
      let!(:enrollment) { create(:hmis_hud_enrollment, client: client, project: project, data_source: data_source) }
      let!(:service) { create(:hmis_hud_service, enrollment: enrollment, client: client, data_source: data_source) }
      let(:definition) { make_definition(owner_class: Hmis::Hud::HmisService) }
      let(:record) { service }

      it 'returns true when user can edit enrollments' do
        create_access_control(user, data_source, with_permission: [:can_view_project, :can_view_enrollment_details, :can_edit_enrollments])
        expect(authorizer.authorized_to_edit?(record)).to be true
      end

      it 'returns false when user cannot edit enrollments' do
        create_access_control(user, data_source, with_permission: [:can_view_project, :can_view_enrollment_details])
        expect(authorizer.authorized_to_edit?(record)).to be false
      end
    end

    context 'Hmis::File' do
      let!(:file) { create(:file, :skip_validate, client: client, user: user) }
      let(:definition) { make_definition(owner_class: Hmis::File) }
      let(:record) { file }

      it 'returns true when user can manage client files' do
        create_access_control(user, data_source, with_permission: [:can_view_clients, :can_view_any_nonconfidential_client_files, :can_manage_any_client_files])
        expect(authorizer.authorized_to_edit?(record)).to be true
      end

      it 'returns false when user cannot manage client files' do
        create_access_control(user, data_source, with_permission: [:can_view_clients, :can_view_any_nonconfidential_client_files])
        expect(authorizer.authorized_to_edit?(record)).to be false
      end
    end
  end
end
