###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, p1) }

  let!(:definition) { create :hmis_form_definition, identifier: 'client_detail_form', role: :CLIENT_DETAIL, version: 1 }
  let!(:form_rule) { create :hmis_form_instance, definition_identifier: 'client_detail_form', entity: nil, active: true }

  before(:each) do
    hmis_login(user)
  end

  describe 'client detail forms query' do
    let(:query) do
      <<~GRAPHQL
        query ClientDetailForms {
          clientDetailForms {
            id
            dataCollectedAbout
            definition {
              id
              identifier
              status
            }
          }
        }
      GRAPHQL
    end

    it 'resolves client detail forms' do
      response, result = post_graphql { query }
      expect(response.status).to eq(200), result.inspect
      forms = result.dig('data', 'clientDetailForms')
      expect(forms.size).to eq(1)
      expect(forms.first.dig('definition', 'id')).to eq(definition.id.to_s)
    end

    context 'when there is a draft or retired form (regression #6779)' do
      let!(:retired) { create :hmis_form_definition, identifier: 'client_detail_form', role: :CLIENT_DETAIL, status: 'retired', version: 0 }
      let!(:draft) { create :hmis_form_definition, identifier: 'client_detail_form', role: :CLIENT_DETAIL, status: 'draft', version: 2 }

      it 'only resolves published' do
        response, result = post_graphql { query }
        expect(response.status).to eq(200), result.inspect
        forms = result.dig('data', 'clientDetailForms')
        expect(forms.size).to eq(1)
        expect(forms.first.dig('definition', 'id')).to eq(definition.id.to_s)
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
