###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'
  before(:each) { hmis_login(user) }

  let!(:access_control) { create_access_control(hmis_user, ds1) }

  let!(:app_user) { create(:user) }
  let!(:hud_user) { create(:hmis_hud_user, data_source: ds1, user_email: app_user.email.downcase) }

  let!(:system_user) { Hmis::User.system_user }
  let!(:system_hud_user) { Hmis::Hud::User.system_user(data_source_id: ds1.id) }

  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1 }

  let(:enrollment_assessments_query) do
    <<~GRAPHQL
      query GetEnrollmentAssessments($id: ID!) {
        enrollment(id: $id) {
          assessments {
            nodes {
              id
              user {
                id
                email
              }
              createdBy {
                id
                email
              }
            }
          }
        }
      }
    GRAPHQL
  end

  describe 'user and createdBy fields' do
    context 'when updated_by_hud_user and created_by_hud_user are set' do
      let!(:assessment) { create(:hmis_custom_assessment, data_source: ds1, enrollment: e1, updated_by_hud_user: hud_user, created_by_hud_user: system_hud_user) }

      it 'resolves user and createdBy from table columns, even when papertrail versions are blank' do
        # check that papertrail is blank
        expect(PaperTrail::Version.where(item_type: assessment.class.sti_name, item_id: assessment.id)).to be_empty

        response, result = post_graphql(id: e1.id.to_s) { enrollment_assessments_query }
        expect(response.status).to eq(200), result.inspect

        node = result.dig('data', 'enrollment', 'assessments', 'nodes', 0)
        expect(node['user']).to be_present
        expect(node['user']['id']).to eq(app_user.id.to_s)
        expect(node['user']['email']).to eq(app_user.email)
        expect(node['createdBy']).to be_present
        expect(node['createdBy']['id']).to eq(system_user.id.to_s)
        expect(node['createdBy']['email']).to eq(system_user.email)
      end
    end

    shared_examples 'falls back to papertrail for user and createdBy' do
      it 'falls back to papertrail for user and createdBy' do
        response, result = post_graphql(id: e1.id.to_s) { enrollment_assessments_query }
        expect(response.status).to eq(200), result.inspect

        node = result.dig('data', 'enrollment', 'assessments', 'nodes', 0)
        expect(node['createdBy']).to be_present
        expect(node['createdBy']['id']).to eq(app_user.id.to_s)
        expect(node['createdBy']['email']).to eq(app_user.email)
      end
    end

    context 'when hud user columns are nil' do
      before do
        PaperTrail.request(controller_info: { true_user_id: app_user.id, whodunnit: app_user.id }) do
          create(:hmis_custom_assessment, date_created: 2.days.ago, date_updated: 2.days.ago, data_source: ds1, enrollment: e1, updated_by_hud_user: nil, created_by_hud_user: nil)
        end
      end

      it_behaves_like 'falls back to papertrail for user and createdBy'
    end

    context 'when hud user exists, but does not map to an application user' do
      let!(:unmapped_hud_user) { create(:hmis_hud_user, data_source: ds1, user_email: 'nonexistent@example.com') }

      before do
        PaperTrail.request(controller_info: { true_user_id: app_user.id, whodunnit: app_user.id }) do
          create(:hmis_custom_assessment, date_created: 2.days.ago, date_updated: 2.days.ago, data_source: ds1, enrollment: e1, updated_by_hud_user: unmapped_hud_user, created_by_hud_user: unmapped_hud_user)
        end
      end

      it_behaves_like 'falls back to papertrail for user and createdBy'
    end
  end

  describe 'performance' do
    before do
      10.times.map do
        app_user = create(:user)
        hud_user = create(:hmis_hud_user, data_source: ds1, user_email: app_user.email.downcase)
        create(:hmis_custom_assessment, data_source: ds1, enrollment: e1, updated_by_hud_user: hud_user, created_by_hud_user: hud_user)
      end
    end

    it 'does not produce n+1 queries for user and createdBy across multiple assessments' do
      expect do
        response, result = post_graphql(id: e1.id.to_s) { enrollment_assessments_query }
        expect(response.status).to eq(200), result.inspect
        nodes = result.dig('data', 'enrollment', 'assessments', 'nodes')
        expect(nodes.size).to eq(10)
        expect(nodes.map { |n| n.dig('user', 'id') }).to all(be_present)
        expect(nodes.map { |n| n.dig('createdBy', 'id') }).to all(be_present)
      end.to make_database_queries(count: 15..25)
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
