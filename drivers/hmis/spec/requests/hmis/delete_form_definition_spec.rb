###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'DeleteFormDefinition mutation', type: :request do
  include_context 'hmis base setup'

  subject(:mutation) do
    <<~GRAPHQL
      mutation DeleteFormDefinition($id: ID!) {
        deleteFormDefinition(id: $id) {
          formDefinition {
            id
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_manage_forms]) }

  before(:each) do
    hmis_login(user)
  end

  it 'deletes draft that has no other versions (deletes form rules)' do
    draft_fd = create(:hmis_form_definition, role: :CUSTOM_ASSESSMENT, status: :draft)
    instance = create(:hmis_form_instance, definition: draft_fd, entity: nil)

    response, result = post_graphql(id: draft_fd.id) { mutation }
    expect(response.status).to eq(200), result.inspect
    # Deletes the draft
    expect(draft_fd.reload).to be_deleted
    # Deletes the instance
    expect { instance.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'deletes draft that has other versions (retains form rules and CDEDs)' do
    draft_fd = create(:hmis_form_definition, role: :CUSTOM_ASSESSMENT, status: :draft, version: 2)
    published_fd = create(:hmis_form_definition, role: :CUSTOM_ASSESSMENT, status: :published, identifier: draft_fd.identifier, version: 1)
    cded = create(:hmis_custom_data_element_definition, form_definition_identifier: published_fd.identifier)
    instance = create(:hmis_form_instance, definition: published_fd, entity: nil)
    # an assessment that has been submitted using the published version
    custom_assessment = create(:hmis_custom_assessment, definition: published_fd)

    response, result = post_graphql(id: draft_fd.id) { mutation }
    expect(response.status).to eq(200), result.inspect
    # Deletes the draft
    expect(draft_fd.reload).to be_deleted
    # Keeps the other version
    expect(published_fd.reload).not_to be_deleted
    # Keeps the instance
    expect(instance.reload).to be_present
    # Keeps the CDED
    expect(cded.reload).not_to be_deleted
    # Does not affect existing assessments
    expect(custom_assessment.reload.form_processor.definition).to eq(published_fd)
  end

  it 'errors if form is published' do
    published_fd = create(:hmis_form_definition, role: :CUSTOM_ASSESSMENT, status: :published)

    expect_gql_error post_graphql(id: published_fd.id) { mutation }, message: /can only delete draft forms/
  end
  it 'errors if form is retired' do
    published_fd = create(:hmis_form_definition, role: :CUSTOM_ASSESSMENT, status: :retired)

    expect_gql_error post_graphql(id: published_fd.id) { mutation }, message: /can only delete draft forms/
  end
  it 'errors if user lacks permission' do
    fd = create(:hmis_form_definition, role: :CUSTOM_ASSESSMENT, status: :draft)
    remove_permissions(access_control, :can_manage_forms)
    expect_access_denied post_graphql(id: fd.id) { mutation }
  end
  it 'errors if user lacks admin permission for disallowed form role' do
    fd = create(:hmis_form_definition, role: :CLIENT, status: :published)
    remove_permissions(access_control, :can_administrate_config)
    expect_access_denied post_graphql(id: fd.id) { mutation }
  end
end
