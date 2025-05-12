###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
  include_context 'hmis service setup'

  before(:each) do
    hmis_login(user)
  end

  let(:query) do
    <<~GRAPHQL
      query EnrollmentsWithLastContactDate(
        $clientId: ID!
      ) {
        client(id: $clientId) {
          enrollments {
            nodesCount
            nodes {
              id
              lastContact {
                contactDate
                contactType
              }
            }
          }
        }
      }
    GRAPHQL
  end

  let!(:access_control) { create_access_control(hmis_user, ds1) }

  let!(:today) { Date.current }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, client: c1, project: p1, entry_date: today - 1.year }

  def query_last_contact
    response, result = post_graphql(client_id: c1.id) { query }
    expect(response.status).to eq(200), result.inspect
    result.dig('data', 'client', 'enrollments', 'nodes', 0, 'lastContact')&.deep_symbolize_keys
  end

  describe 'resolving lastContact' do
    context 'when there is no last contact' do
      it 'returns nil' do
        expect(query_last_contact).to be_nil
      end
    end

    context 'when there are contacts of different types' do
      let!(:s1_bednight) { create(:hmis_hud_service_bednight, date_provided: today - 1.month, data_source: ds1, client: c1, enrollment: e1) }
      let!(:s2_custom) { create(:hmis_custom_service, date_provided: today - 2.months, custom_service_type: cst1, data_source: ds1, client: c1, enrollment: e1) }
      let!(:cls) { create(:hmis_current_living_situation, client: c1, enrollment: e1, information_date: today - 3.months) }
      let!(:assessment) { create(:hmis_custom_assessment, client: c1, enrollment: e1, assessment_date: today - 4.months) }
      let!(:case_note) { create(:hmis_hud_custom_case_note, client: c1, enrollment: e1, information_date: today - 5.months) }

      context 'and HUD service is the last contact' do
        it 'returns the HUD service date' do
          expect(query_last_contact).to match(
            a_hash_including(
              contactDate: s1_bednight.date_provided.strftime('%Y-%m-%d'),
              contactType: 'BED_NIGHT',
            ),
          )
        end
      end

      context 'and custom service is the last contact' do
        let!(:s2_custom) { create(:hmis_custom_service, date_provided: today - 1.week, custom_service_type: cst1, data_source: ds1, client: c1, enrollment: e1) }

        it 'returns the custom service date' do
          expect(query_last_contact).to match(
            a_hash_including(
              contactDate: s2_custom.date_provided.strftime('%Y-%m-%d'),
              contactType: 'SERVICE',
            ),
          )
        end
      end

      context 'when CLS is the last contact' do
        let!(:cls) { create(:hmis_current_living_situation, client: c1, enrollment: e1, information_date: today - 3.days) }

        it 'returns the correct type and date' do
          expect(query_last_contact).to match(
            a_hash_including(
              contactDate: cls.information_date.strftime('%Y-%m-%d'),
              contactType: 'CURRENT_LIVING_SITUATION',
            ),
          )
        end
      end

      context 'when custom assessment is the last contact' do
        let!(:assessment) { create(:hmis_custom_assessment, data_collection_stage: 5, client: c1, enrollment: e1, assessment_date: today - 2.days) }

        it 'returns the correct type and date' do
          expect(query_last_contact).to match(
            a_hash_including(
              contactDate: assessment.assessment_date.strftime('%Y-%m-%d'),
              contactType: 'ANNUAL_ASSESSMENT', # Specifies the custom assessment name
            ),
          )
        end
      end

      context 'when case note is the last contact' do
        let!(:case_note) { create(:hmis_hud_custom_case_note, client: c1, enrollment: e1, information_date: today - 4.days) }

        it 'returns the correct type and date' do
          expect(query_last_contact).to match(
            a_hash_including(
              contactDate: case_note.information_date.strftime('%Y-%m-%d'),
              contactType: 'CASE_NOTE',
            ),
          )
        end
      end

      it 'minimizes n+1' do
        10.times do
          enrollment = create :hmis_hud_enrollment, data_source: ds1, client: c1
          10.times do
            create(:hmis_hud_service_bednight, data_source: ds1, client: c1, enrollment: enrollment)
            create(:hmis_hud_custom_case_note, data_source: ds1, client: c1, enrollment: enrollment)
            create(:hmis_custom_assessment, data_source: ds1, client: c1, enrollment: enrollment)
            create(:hmis_current_living_situation, data_source: ds1, client: c1, enrollment: enrollment)
            create(:hmis_custom_service, data_source: ds1, client: c1, enrollment: enrollment)
          end
        end

        expect do
          response, result = post_graphql(client_id: c1.id) { query }
          expect(response.status).to eq(200), result.inspect
          enrollments = result.dig('data', 'client', 'enrollments', 'nodes').map(&:deep_symbolize_keys)
          expect(enrollments.map { |e| e[:lastContact] }.compact.size).to eq(enrollments.size)
        end.to make_database_queries(count: 10..30)
      end
    end

    context 'when the only contact is a service with no date' do
      let!(:s1_bednight) do
        # create directly, rather than using the factory, to get around ActiveRecord validations on date_provided
        service = Hmis::Hud::Service.new(
          client: c1,
          enrollment: e1,
          date_created: today,
          date_updated: today,
          date_provided: nil, # nil date provided is forbidden by ActiveRecord but allowed by database
          record_type: 200,
          type_provided: 200,
        )
        service.save!(validate: false)
      end

      it 'returns no last contact' do
        expect(query_last_contact).to be_nil
      end
    end

    context 'when there are some with and some without dates' do
      let!(:bed_night) { create(:hmis_hud_service_bednight, data_source: ds1, client: c1, enrollment: e1) }
      let!(:case_note) { create(:hmis_hud_custom_case_note, client: c1, enrollment: e1, information_date: nil) }

      it 'returns last contact with date' do
        expect(query_last_contact).to match(
          a_hash_including(
            contactDate: bed_night.date_provided.strftime('%Y-%m-%d'),
            contactType: 'BED_NIGHT',
          ),
        )
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
