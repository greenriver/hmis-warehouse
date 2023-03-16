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
  let!(:f1) do
    file = Hmis::File.new(
      name: blob.filename,
      client_id: c1.id,
      enrollment_id: e1.id,
      effective_date: Date.today,
      expiration_date: Date.tomorrow,
      user_id: hmis_user.id,
      confidential: true,
      visible_in_window: false,
    )
    file.tag_list.add([tag.id])
    file.client_file.attach(blob)
    file.save!

    file
  end

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
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
