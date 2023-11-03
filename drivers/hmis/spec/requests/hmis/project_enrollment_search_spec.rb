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
  let(:search_term) { 'Foobarbaz' }
  let!(:access_control) { create_access_control(hmis_user, p1) }
  let!(:c1) { create :hmis_hud_client, data_source: ds1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }

  let!(:c2) { create :hmis_hud_client, data_source: ds1, last_name: search_term }
  let!(:e2) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c2 }

  let!(:c3) { create :hmis_hud_client, data_source: ds1, DOB: Date.current - 30.years }
  let!(:e3) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c3 }

  # canary
  let!(:p_canary) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
  let!(:e_canary) { create :hmis_hud_enrollment, data_source: ds1, project: p_canary, client: c1 }

  before(:each) do
    hmis_login(user)
  end

  describe 'project households query' do
    let(:query) do
      <<~GRAPHQL
        query TestQuery($id: ID!, $filters: HouseholdFilterOptions!) {
          project(id: $id) {
            id
            households(limit: 10, offset: 0, filters: $filters) {
              nodesCount
              nodes {
                id
              }
            }
          }
        }
      GRAPHQL
    end

    it 'filters households by all statuses' do
      filters = { "status": ['INCOMPLETE', 'ACTIVE', 'EXITED'] }
      response, result = post_graphql(id: p1.id, filters: filters) { query }
      expect(response.status).to eq 200
      [e1, e2, e3].map(&:household_id).tap do |expected|
        expect(expected.size).to eq 3
        households = result.dig('data', 'project', 'households', 'nodes')
        expect(households.map { |r| r.fetch('id') }.sort).to eq expected.sort
      end
    end

    it 'filters households by search term' do
      filters = { searchTerm: search_term }
      response, result = post_graphql(id: p1.id, filters: filters) { query }
      expect(response.status).to eq 200
      [e2].map(&:household_id).tap do |expected|
        expect(expected.size).to eq 1
        households = result.dig('data', 'project', 'households', 'nodes')
        expect(households.map { |r| r.fetch('id') }).to eq expected
      end
    end

    it 'filters households by age' do
      filters = { "hohAgeRange": 'Ages25to34' }
      response, result = post_graphql(id: p1.id, filters: filters) { query }
      expect(response.status).to eq 200
      [e3].map(&:household_id).tap do |expected|
        expect(expected.size).to eq 1
        households = result.dig('data', 'project', 'households', 'nodes')
        expect(households.map { |r| r.fetch('id') }).to eq expected
      end
    end
  end

  describe 'project enrollments query' do
    let(:query) do
      <<~GRAPHQL
        query TestQuery($id: ID!, $filters: EnrollmentsForProjectFilterOptions!) {
          project(id: $id) {
            id
            enrollments(limit: 10, offset: 0, filters: $filters) {
              nodesCount
              nodes {
                id
              }
            }
          }
        }
      GRAPHQL
    end

    describe 'household tasks filter' do
      it 'should filter annuals due by first anniversary' do
        # Entered a year ago, annual is due
        e4 = create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c3, entry_date: Date.today - 1.year)
        # Entered less than a year ago, annual is not due
        create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c3, entry_date: Date.today - 6.months)
        response, result = post_graphql(id: p1.id, filters: { "householdTasks": ['ANNUAL_DUE'] }) { query }
        expect(response.status).to eq 200
        expect(result.dig('data', 'project', 'enrollments', 'nodes')).to contain_exactly(include('id' => e4.id.to_s))
      end

      it 'should filter annuals due excluding enrollments exited before the entry anniversary' do
        # Exited before the entry anniversary, annual is not due
        e4 = create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c3, entry_date: Date.today - 3.years)
        create(:hmis_hud_exit, enrollment: e4, data_source: ds1, client: c3, user: u1, exit_date: Date.today - 6.months)
        # Exited after the entry anniversary, annual is due
        e5 = create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c3, entry_date: Date.today - 3.years)
        create(:hmis_hud_exit, enrollment: e5, data_source: ds1, client: c3, user: u1).update(exit_date: Date.today + 2.months)
        response, result = post_graphql(id: p1.id, filters: { "householdTasks": ['ANNUAL_DUE'] }) { query }
        expect(response.status).to eq 200
        expect(result.dig('data', 'project', 'enrollments', 'nodes')).to contain_exactly(include('id' => e5.id.to_s))
      end

      it 'should filter annuals due excluding enrollments with recent annual assessments' do
        # Had an assessment 2 years ago, annual is due
        e4 = create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c3, entry_date: Date.today - 3.years)
        create(:hmis_custom_assessment, data_source: ds1, enrollment: e4, data_collection_stage: 5, assessment_date: Date.today - 2.years)
        # Had an assessment today, annual is not due
        e5 = create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c3, entry_date: Date.today - 3.year)
        create(:hmis_custom_assessment, data_source: ds1, enrollment: e5, data_collection_stage: 5, assessment_date: Date.today)

        response, result = post_graphql(id: p1.id, filters: { "householdTasks": ['ANNUAL_DUE'] }) { query }
        expect(response.status).to eq 200
        expect(result.dig('data', 'project', 'enrollments', 'nodes')).to contain_exactly(include('id' => e4.id.to_s))
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
