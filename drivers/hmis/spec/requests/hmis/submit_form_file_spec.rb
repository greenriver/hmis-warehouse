# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'
require_relative '../../support/submit_form_spec_helpers'
require_relative 'submit_form_spec'

RSpec.describe 'SubmitForm for File', type: :request do
  include_context 'hmis base setup'
  include_context 'file upload setup'

  let!(:access_control) { create_access_control(hmis_user, ds1) }
  before(:each) { hmis_login(user) }

  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, user: u1, entry_date: '2020-01-01' }
  let!(:file1) { create :file, client: c1, blob: blob, user_id: hmis_user.id, tags: [tag] }

  let(:definition) { Hmis::Form::Definition.find_by(role: :FILE) }
  let(:hud_values) do
    {
      'confidential' => false,
      'enrollmentId' => nil,
      'tags' => [tag.id.to_s],
      'fileBlobId' => blob.signed_id,
    }
  end
  let(:input) do
    {
      form_definition_id: definition.id,
      client_id: c1.id,
      hud_values: hud_values,
      values: hud_values_to_values_by_link_id(hud_values),
    }
  end

  it_behaves_like 'submit form creates form processor'
  it_behaves_like 'submit form fails when required field is missing'
  it_behaves_like 'submit form fails when form definition is draft'

  it 'creates a new file' do
    record, = submit_form(input)
    file = Hmis::File.find(record['id'])
    expect(file.confidential).to eq(false)
    expect(file.tags).to eq([tag])
  end

  it 'persists submitted form values to an existing file' do
    expect do
      submit_form(input.merge(record_id: file1.id, hud_values: hud_values.merge('enrollmentId' => e1.id)))
      file1.reload
    end.to change(file1, :enrollment).from(nil).to(e1)
  end

  # file.user is a special case, so use a special test instead of shared example used by the other submit_form tests
  it 'updates user correctly' do
    record, = submit_form(input.merge(record_id: file1.id))
    record = definition.owner_class.find(record['id'])

    expect(record.user).to eq(hmis_user)
    expect(record.updated_by).to eq(hmis_user)

    # update file to pretend it was created by a different user
    record.update(user_id: 999, updated_by_id: nil)

    next_input = input.merge(record_id: record.id)
    record, = submit_form(next_input)
    record = definition.owner_class.find(record['id'])

    expect(record.user_id).to eq(999) # unchanged
    expect(record.updated_by).to eq(hmis_user) # changed to user who most recently edited
  end

  describe 'permissions' do
    context 'when user lacks both file management permissions (even if they can still view the file)' do
      before { remove_permissions(access_control, :can_manage_any_client_files, :can_manage_own_client_files) }

      it 'returns access denied for create' do
        expect_gql_error submit_form(input, expect_raise: true), message: /not authorized/
      end

      it 'returns access denied for update' do
        expect_gql_error submit_form(input.merge(record_id: file1.id), expect_raise: true), message: /not authorized/
      end
    end

    context 'when user has only can_manage_own_client_files' do
      before { remove_permissions(access_control, :can_manage_any_client_files) }

      it 'allows creating a new file' do
        record, = submit_form(input)
        file = Hmis::File.find(record['id'])
        expect(file.user_id).to eq(hmis_user.id)
      end

      it 'allows updating own file' do
        expect do
          submit_form(input.merge(record_id: file1.id, hud_values: hud_values.merge('enrollmentId' => e1.id)))
          file1.reload
        end.to change(file1, :enrollment_id).to(e1.id)
      end

      it "returns access denied when updating another user's file" do
        other_hmis_user = create(:user).related_hmis_user(ds1)
        file_owned_by_other = create(:file, client: c1, user: other_hmis_user, blob: blob, tags: [tag])
        expect_gql_error submit_form(input.merge(record_id: file_owned_by_other.id), expect_raise: true), message: /not authorized/
      end
    end

    context 'when user has can_manage_any_client_files' do
      it "allows updating any file (including another user's file)" do
        other_hmis_user = create(:user).related_hmis_user(ds1)
        file_owned_by_other = create(:file, client: c1, user: other_hmis_user, blob: blob, tags: [tag])

        expect do
          submit_form(input.merge(record_id: file_owned_by_other.id, hud_values: hud_values.merge('enrollmentId' => e1.id)))
          file_owned_by_other.reload
        end.to change(file_owned_by_other, :enrollment_id).to(e1.id)
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
  c.include FormHelpers
  c.include SubmitFormSpecHelpers
end
