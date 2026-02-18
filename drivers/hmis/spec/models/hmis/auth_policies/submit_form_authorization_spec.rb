###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# todo @martha - this spec needs more review and comprehesiveness
require 'rails_helper'

RSpec.describe Hmis::AuthPolicies::SubmitFormAuthorization, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let(:organization) { create(:hmis_hud_organization, data_source: data_source) }
  let(:project) { create(:hmis_hud_project, organization: organization, data_source: data_source) }
  let(:client) { create(:hmis_hud_client, data_source: data_source) }
  let(:user) { create(:hmis_user, data_source: data_source) }

  def can_submit?(resource)
    described_class.can_submit?(user: user, resource: resource)
  end

  shared_examples 'allows when authorized' do |role, permission, &build_record|
    let(:record) { instance_exec(&build_record) }

    context "for #{role} form" do
      context 'with required permission' do
        before { create_access_control(user, project, with_permission: permission) }

        it 'returns true' do
          expect(can_submit?(record)).to be true
        end
      end

      context 'without required permission' do
        it 'returns false' do
          expect(can_submit?(record)).to be false
        end
      end
    end
  end

  describe '#authorized?' do
    context 'Client (new record)' do
      let(:record) { Hmis::Hud::Client.new(data_source_id: data_source.id) }

      it 'returns true when user has can_edit_clients' do
        create_access_control(user, project, with_permission: [:can_view_clients, :can_edit_clients])
        expect(can_submit?(record)).to be true
      end

      it 'returns false without can_edit_clients' do
        expect(can_submit?(record)).to be false
      end
    end

    context 'Client (existing record)' do
      let!(:enrollment) { create(:hmis_hud_enrollment, client: client, project: project, data_source: data_source) }

      it 'returns true when user has can_edit_clients for the client' do
        create_access_control(user, project, with_permission: [:can_view_clients, :can_edit_clients])
        expect(can_submit?(client)).to be true
      end

      it 'returns false without can_edit_clients' do
        expect(can_submit?(client)).to be false
      end
    end

    context 'Organization (new record)' do
      let(:record) { Hmis::Hud::Organization.new(data_source_id: data_source.id) }

      it 'returns true when user has can_edit_organization' do
        create_access_control(user, organization, with_permission: :can_edit_organization)
        expect(can_submit?(record)).to be true
      end

      it 'returns false without can_edit_organization' do
        expect(can_submit?(record)).to be false
      end
    end

    context 'Project (new record)' do
      let(:record) { Hmis::Hud::Project.new(data_source_id: data_source.id, organization: organization) }

      it 'returns true when user has can_edit_project_details' do
        create_access_control(user, organization, with_permission: [:can_view_project, :can_edit_project_details])
        expect(can_submit?(record)).to be true
      end

      it 'returns false without can_edit_project_details' do
        expect(can_submit?(record)).to be false
      end
    end

    context 'Project (existing record)' do
      it 'returns true when user has can_edit_project_details for the project' do
        create_access_control(user, project, with_permission: [:can_view_project, :can_edit_project_details])
        expect(can_submit?(project)).to be true
      end

      it 'returns false without can_edit_project_details' do
        expect(can_submit?(project)).to be false
      end
    end

    context 'project-related records (Funder, Inventory, etc.)' do
      context 'new record' do
        let(:record) { Hmis::Hud::Funder.new(project_id: project.project_id, data_source_id: data_source.id) }

        it 'returns true when user has can_edit_project_details for the project' do
          create_access_control(user, project, with_permission: [:can_view_project, :can_edit_project_details])
          expect(can_submit?(record)).to be true
        end

        it 'returns false without can_edit_project_details' do
          expect(can_submit?(record)).to be false
        end
      end

      context 'existing record' do
        let!(:funder) { create(:hmis_hud_funder, project: project, data_source: data_source) }

        it 'returns true when user has can_edit_project_details for the project' do
          create_access_control(user, project, with_permission: [:can_view_project, :can_edit_project_details])
          expect(can_submit?(funder)).to be true
        end

        it 'returns false without can_edit_project_details' do
          expect(can_submit?(funder)).to be false
        end
      end
    end

    context 'Enrollment (new record)' do
      let(:record) do
        Hmis::Hud::Enrollment.new(
          project_id: project.project_id,
          project_pk: project.id,
          personal_id: client.personal_id,
          data_source_id: data_source.id,
        )
      end

      it 'returns true when user has can_edit_enrollments for the project' do
        create_access_control(user, project, with_permission: [:can_view_project, :can_view_enrollment_details, :can_edit_enrollments])
        expect(can_submit?(record)).to be true
      end

      it 'returns false without can_edit_enrollments' do
        expect(can_submit?(record)).to be false
      end
    end

    context 'Enrollment (existing record)' do
      let!(:enrollment) { create(:hmis_hud_enrollment, client: client, project: project, data_source: data_source) }

      it 'returns true when user has can_edit_enrollments for the enrollment project' do
        create_access_control(user, project, with_permission: [:can_view_project, :can_view_enrollment_details, :can_edit_enrollments])
        expect(can_submit?(enrollment)).to be true
      end

      it 'returns false without can_edit_enrollments' do
        expect(can_submit?(enrollment)).to be false
      end
    end

    context 'enrollment-related records (Service, CaseNote, Event, etc.)' do
      let!(:enrollment) { create(:hmis_hud_enrollment, client: client, project: project, data_source: data_source) }

      context 'new CustomCaseNote' do
        let(:record) do
          Hmis::Hud::CustomCaseNote.new(
            enrollment_id: enrollment.enrollment_id,
            personal_id: enrollment.personal_id,
            data_source_id: data_source.id,
          )
        end

        it 'returns true when user has can_edit_enrollments' do
          create_access_control(user, project, with_permission: [:can_view_project, :can_view_enrollment_details, :can_edit_enrollments])
          expect(can_submit?(record)).to be true
        end

        it 'returns false without can_edit_enrollments' do
          expect(can_submit?(record)).to be false
        end
      end

      context 'existing Assessment' do
        let!(:assessment) { create(:hmis_hud_assessment, client: client, enrollment: enrollment, data_source: data_source) }

        it 'returns true when user has can_edit_enrollments' do
          create_access_control(user, project, with_permission: [:can_view_project, :can_view_enrollment_details, :can_edit_enrollments])
          expect(can_submit?(assessment)).to be true
        end

        it 'returns false without can_edit_enrollments' do
          expect(can_submit?(assessment)).to be false
        end
      end
    end
  end
end
