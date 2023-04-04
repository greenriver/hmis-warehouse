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
  include_context 'file upload setup'

  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, relationship_to_ho_h: 1, household_id: '1', user: u1 }
  let!(:f1) { create :file, client: c1, enrollment: e1, blob: blob, user_id: hmis_user.id, tags: [tag] }
  let(:u2) { create(:user) }

  let(:mutation) do
    <<~GRAPHQL
      mutation DeleteClientFile($fileId: ID!) {
        deleteClientFile(input: { fileId: $fileId }) {
          file {
            #{scalar_fields(Types::HmisSchema::File)}
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  before(:each) do
    hmis_login(user)
    assign_viewable(edit_access_group, o1.as_warehouse, hmis_user)
  end

  def call_mutation(file_id)
    response, result = post_graphql(file_id: file_id) { mutation }
    expect(response.status).to eq 200
    file = result.dig('data', 'deleteClientFile', 'file')
    errors = result.dig('data', 'deleteClientFile', 'errors')
    [file, errors]
  end

  describe 'deletion tests' do
    it 'should delete the file correctly' do
      file_id = f1.id
      file, errors = call_mutation(file_id)
      expect(errors).to be_empty
      expect(file).to be_present
      expect(Hmis::File.all).not_to include(have_attributes(id: file_id))
    end

    it 'should throw error if not allowed to manage files' do
      remove_permissions(hmis_user, :can_manage_any_client_files, :can_manage_own_client_files)
      file_id = f1.id
      file, errors = call_mutation(file_id)
      expect(file).to be_nil
      expect(errors).to contain_exactly(include('type' => 'not_allowed'))
      expect(Hmis::File.all).to include(have_attributes(id: file_id))
    end

    it 'should throw error if only allowed to manage own files and trying to delete file that is not their own' do
      remove_permissions(hmis_user, :can_manage_any_client_files)
      file_id = f1.id
      f1.update(user_id: u2.id)
      file, errors = call_mutation(file_id)
      expect(file).to be_nil
      expect(errors).to contain_exactly(include('type' => 'not_allowed'))
      expect(Hmis::File.all).to include(have_attributes(id: file_id))
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
