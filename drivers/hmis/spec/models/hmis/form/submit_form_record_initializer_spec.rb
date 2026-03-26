###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Form::SubmitFormRecordInitializer, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let(:organization) { create(:hmis_hud_organization, data_source: data_source) }
  let(:project) { create(:hmis_hud_project, organization: organization, data_source: data_source) }
  let(:client) { create(:hmis_hud_client, data_source: data_source) }
  let(:user) { create(:hmis_user, data_source: data_source) }

  def make_input(**attrs)
    defaults = { record_id: nil, project_id: nil, client_id: nil, enrollment_id: nil, organization_id: nil, service_type_id: nil }
    OpenStruct.new(defaults.merge(attrs))
  end

  def build_record(owner_class:, input:)
    described_class.build(owner_class: owner_class, input: input, user: user)
  end

  shared_examples 'raises when required association not passed' do
    it 'raises when required association id is not passed' do
      expect { build_record(owner_class: owner_class, input: input_without_required) }.to raise_error(/cannot create/)
    end
  end

  shared_examples 'raises when required association passed but not viewable' do
    it 'raises when required association is passed but not viewable by user' do
      # User has no access control, so viewable_by returns nothing
      expect { build_record(owner_class: owner_class, input: input_with_required_id) }.to raise_error(/not authorized to view/i)
    end
  end

  shared_examples 'builds record when associations viewable' do |expected_class:, view_permission:|
    it 'succeeds when required associations are viewable' do
      create_access_control(user, data_source, with_permission: view_permission)
      result = build_record(owner_class: owner_class, input: input_with_required_id)
      expect(result).to be_a(expected_class)
      expect(result).to be_new_record
    end
  end

  describe 'input with record_id' do
    it 'raises and does not build when input has record_id' do
      input = make_input(record_id: 'some-id')
      expect { build_record(owner_class: Hmis::Hud::Client, input: input) }.to raise_error(/record_id/)
    end
  end

  describe '.build' do
    context 'Client' do
      let(:owner_class) { Hmis::Hud::Client }
      let(:input_without_required) { make_input }
      let(:input_with_required_id) { make_input }

      it_behaves_like 'builds record when associations viewable',
                      expected_class: Hmis::Hud::Client,
                      view_permission: [:can_view_clients]
    end

    context 'Organization' do
      let(:owner_class) { Hmis::Hud::Organization }
      let(:input_without_required) { make_input }
      let(:input_with_required_id) { make_input }

      it_behaves_like 'builds record when associations viewable',
                      expected_class: Hmis::Hud::Organization,
                      view_permission: [:can_view_project]
    end

    context 'Project' do
      let(:owner_class) { Hmis::Hud::Project }
      let(:input_without_required) { make_input }
      let(:input_with_required_id) { make_input(organization_id: organization.id) }

      it_behaves_like 'raises when required association not passed'
      it_behaves_like 'raises when required association passed but not viewable'
      it_behaves_like 'builds record when associations viewable',
                      expected_class: Hmis::Hud::Project,
                      view_permission: [:can_view_project]
    end

    context 'Enrollment' do
      let(:owner_class) { Hmis::Hud::Enrollment }
      let(:input_without_required) { make_input }
      let(:input_with_required_id) { make_input(project_id: project.id) }

      it_behaves_like 'raises when required association not passed'
      it_behaves_like 'raises when required association passed but not viewable'
      it_behaves_like 'builds record when associations viewable',
                      expected_class: Hmis::Hud::Enrollment,
                      view_permission: [:can_view_project, :can_view_clients]
    end

    context 'project-related (Funder)' do
      let(:owner_class) { Hmis::Hud::Funder }
      let(:input_without_required) { make_input }
      let(:input_with_required_id) { make_input(project_id: project.id) }

      it_behaves_like 'raises when required association not passed'
      it_behaves_like 'raises when required association passed but not viewable'
      it_behaves_like 'builds record when associations viewable',
                      expected_class: Hmis::Hud::Funder,
                      view_permission: [:can_view_project]
    end

    context 'enrollment-related (CustomCaseNote)' do
      let!(:enrollment) { create(:hmis_hud_enrollment, client: client, project: project, data_source: data_source) }
      let(:owner_class) { Hmis::Hud::CustomCaseNote }
      let(:input_without_required) { make_input }
      let(:input_with_required_id) { make_input(enrollment_id: enrollment.id) }

      it_behaves_like 'raises when required association not passed'
      it_behaves_like 'raises when required association passed but not viewable'
      it_behaves_like 'builds record when associations viewable',
                      expected_class: Hmis::Hud::CustomCaseNote,
                      view_permission: [:can_view_project, :can_view_enrollment_details]
    end

    context 'HmisService' do
      let!(:enrollment) { create(:hmis_hud_enrollment, client: client, project: project, data_source: data_source) }
      let(:owner_class) { Hmis::Hud::HmisService }

      context 'with HUD service type' do
        let(:custom_service_type) { create(:hmis_hud_custom_service_type, data_source: data_source) }
        let(:input_without_required) { make_input }
        let(:input_with_required_id) { make_input(enrollment_id: enrollment.id, service_type_id: custom_service_type.id) }

        it 'raises when enrollment not passed' do
          input = make_input(service_type_id: custom_service_type.id)
          expect { build_record(owner_class: owner_class, input: input) }.to raise_error(/without enrollment/)
        end

        it 'raises when service_type_id not passed' do
          create_access_control(user, data_source, with_permission: [:can_view_project, :can_view_enrollment_details])
          input = make_input(enrollment_id: enrollment.id)
          expect { build_record(owner_class: owner_class, input: input) }.to raise_error(/service type/)
        end

        it_behaves_like 'raises when required association passed but not viewable'
        it_behaves_like 'builds record when associations viewable',
                        expected_class: Hmis::Hud::Service,
                        view_permission: [:can_view_project, :can_view_enrollment_details]
      end

      context 'with custom service type' do
        let(:custom_service_type) { create(:hmis_custom_service_type, data_source: data_source) }
        let(:input_with_required_id) { make_input(enrollment_id: enrollment.id, service_type_id: custom_service_type.id) }

        it 'succeeds and returns CustomService when enrollment and service_type viewable' do
          create_access_control(user, data_source, with_permission: [:can_view_project, :can_view_enrollment_details])
          result = build_record(owner_class: owner_class, input: input_with_required_id)
          expect(result).to be_a(Hmis::Hud::CustomService)
          expect(result).to be_new_record
        end
      end
    end

    context 'Hmis::File' do
      let(:owner_class) { Hmis::File }
      let(:input_without_required) { make_input }
      let(:input_with_required_id) { make_input(client_id: client.id) }

      it_behaves_like 'raises when required association not passed'
      it_behaves_like 'raises when required association passed but not viewable'
      it_behaves_like 'builds record when associations viewable',
                      expected_class: Hmis::File,
                      view_permission: [:can_view_clients]
    end
  end
end
