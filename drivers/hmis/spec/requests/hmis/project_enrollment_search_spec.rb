###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
      expect(response.status).to eq(200), result.inspect
      [e1, e2, e3].map(&:household_id).tap do |expected|
        expect(expected.size).to eq 3
        households = result.dig('data', 'project', 'households', 'nodes')
        expect(households.map { |r| r.fetch('id') }.sort).to eq expected.sort
      end
    end

    it 'filters households by search term' do
      filters = { searchTerm: search_term }
      response, result = post_graphql(id: p1.id, filters: filters) { query }
      expect(response.status).to eq(200), result.inspect
      [e2].map(&:household_id).tap do |expected|
        expect(expected.size).to eq 1
        households = result.dig('data', 'project', 'households', 'nodes')
        expect(households.map { |r| r.fetch('id') }).to eq expected
      end
    end

    it 'filters households by age' do
      filters = { "hohAgeRange": 'Ages25to34' }
      response, result = post_graphql(id: p1.id, filters: filters) { query }
      expect(response.status).to eq(200), result.inspect
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
        e4 = create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c3, entry_date: Date.current - 1.year)
        # Entered less than a year ago, annual is not due
        create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c3, entry_date: Date.current - 6.months)
        response, result = post_graphql(id: p1.id, filters: { "householdTasks": ['ANNUAL_DUE'] }) { query }
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'project', 'enrollments', 'nodes')).to contain_exactly(include('id' => e4.id.to_s))
      end

      it 'should filter annuals due excluding enrollments exited before the entry anniversary' do
        # Has exited, annual is not due
        e4 = create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c3, entry_date: Date.current - 3.years)
        create(:hmis_hud_exit, enrollment: e4, data_source: ds1, client: c3, user: u1, exit_date: Date.current - 6.months)
        # Has not exited, annual is due
        e5 = create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c3, entry_date: Date.current - 3.years)
        response, result = post_graphql(id: p1.id, filters: { "householdTasks": ['ANNUAL_DUE'] }) { query }
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'project', 'enrollments', 'nodes')).to contain_exactly(include('id' => e5.id.to_s))
      end

      it 'should filter annuals due excluding enrollments with recent annual assessments' do
        # Had an assessment 2 years ago, annual is due
        e4 = create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c3, entry_date: Date.current - 3.years)
        create(:hmis_custom_assessment, data_source: ds1, enrollment: e4, data_collection_stage: 5, assessment_date: Date.current - 2.years)
        # Had an assessment today, annual is not due
        e5 = create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c3, entry_date: Date.current - 3.year)
        create(:hmis_custom_assessment, data_source: ds1, enrollment: e5, data_collection_stage: 5, assessment_date: Date.current)
        # Annual not due yet this year, but assessment was not done last year, annual is due
        e6 = create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c3, entry_date: Date.current - 3.year + 60.days)
        create(:hmis_custom_assessment, data_source: ds1, enrollment: e6, data_collection_stage: 5, assessment_date: Date.current - 2.year + 60.days)
        # Annual not due yet this year, but assessment was done last year, annual is not due
        e7 = create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c3, entry_date: Date.current - 3.year + 60.days)
        create(:hmis_custom_assessment, data_source: ds1, enrollment: e7, data_collection_stage: 5, assessment_date: Date.current - 1.year + 60.days)

        response, result = post_graphql(id: p1.id, filters: { "householdTasks": ['ANNUAL_DUE'] }) { query }
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'project', 'enrollments', 'nodes')).to contain_exactly(include('id' => e4.id.to_s), include('id' => e6.id.to_s))
      end

      it 'should filter annuals due excluding household members with recent enrollments' do
        # Had an assessment 2 years ago, annual is due
        e4 = create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c3, entry_date: Date.current - 3.years)
        create(:hmis_custom_assessment, data_source: ds1, enrollment: e4, data_collection_stage: 5, assessment_date: Date.current - 2.years)
        # Had an assessment today, annual is not due
        e5 = create(:hmis_hud_enrollment, data_source: ds1, household_id: e4.household_id, project: p1, client: c3, entry_date: Date.current - 3.years)
        create(:hmis_custom_assessment, data_source: ds1, enrollment: e5, data_collection_stage: 5, assessment_date: Date.current)
        # Annual not due yet this year, but assessment was not done last year, annual is due
        e6 = create(:hmis_hud_enrollment, data_source: ds1, household_id: e4.household_id, project: p1, client: c3, entry_date: Date.current - 3.years)
        create(:hmis_custom_assessment, data_source: ds1, enrollment: e6, data_collection_stage: 5, assessment_date: Date.current)

        response, result = post_graphql(id: p1.id, filters: { "householdTasks": ['ANNUAL_DUE'] }) { query }
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'project', 'enrollments', 'nodes')).to contain_exactly(include('id' => e4.id.to_s))
      end

      it 'should ignore deleted annuals (regression test)' do
        en = create(:hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: Date.current - 1.year)
        create(:hmis_custom_assessment, data_collection_stage: 5, assessment_date: Date.current, date_deleted: Date.current, data_source: ds1, enrollment: en)

        response, result = post_graphql(id: p1.id, filters: { "householdTasks": ['ANNUAL_DUE'] }) { query }
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'project', 'enrollments', 'nodes')).to contain_exactly(include('id' => en.id.to_s))
      end

      # Run test for two dates, because they behave differently. The first will test the case where the most recent annual is due last year,
      # and the second will test the case where the most recent annual is due this year.
      [Time.local(2023, 4, 1), Time.local(2023, 11, 1)].each do |local_time|
        it "should base annual due date on the earliest entry date in the household (local date #{local_time.strftime('%Y-%m-%d')})" do
          travel_to local_time do
            # Entered 18 months ago (earliest entry in household)
            e1 = create(:hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: 18.months.ago)
            # Entered 14 months ago, with an irrelevant annual 2 months ago. (Annual due period is 6 months ago)
            e2 = create(:hmis_hud_enrollment, data_source: ds1, household_id: e1.household_id, project: p1, entry_date: 14.months.ago)
            create(:hmis_custom_assessment, data_source: ds1, enrollment: e2, data_collection_stage: 5, assessment_date: 2.months.ago)
            # Entered 14 months ago, with an irrelevant annual 8 months ago. (Annual due period is 6 months ago)
            e3 = create(:hmis_hud_enrollment, data_source: ds1, household_id: e1.household_id, project: p1, entry_date: 14.months.ago)
            create(:hmis_custom_assessment, data_source: ds1, enrollment: e3, data_collection_stage: 5, assessment_date: 8.months.ago)
            # Entered 1 month ago (not due for annual yet because entered after anniversary)
            _e4 = create(:hmis_hud_enrollment, data_source: ds1, household_id: e1.household_id, project: p1, entry_date: 1.month.ago)

            response, result = post_graphql(id: p1.id, filters: { "householdTasks": ['ANNUAL_DUE'] }) { query }
            expect(response.status).to eq(200), result.inspect

            expect(result.dig('data', 'project', 'enrollments', 'nodes')).to contain_exactly(
              include('id' => e1.id.to_s),
              include('id' => e2.id.to_s),
              include('id' => e3.id.to_s),
            )
          end
        end

        it "should exlude enrollments that have annuals during the due period (local date #{local_time.strftime('%Y-%m-%d')})" do
          travel_to local_time do
            # Entered ~2 years ago
            e1 = create(:hmis_hud_enrollment, entry_date: 18.months.ago, data_source: ds1, project: p1)

            # Valid annual
            create(:hmis_custom_assessment, assessment_date: e1.entry_date + 1.year - 1.week, data_source: ds1, enrollment: e1, data_collection_stage: 5)
            # Irrelevant annual that was conducted before the due period
            annual_outside_range = create(:hmis_custom_assessment, assessment_date: e1.entry_date + 6.months, data_source: ds1, enrollment: e1, data_collection_stage: 5)

            response, result = post_graphql(id: p1.id, filters: { "householdTasks": ['ANNUAL_DUE'] }) { query }
            expect(response.status).to eq(200), result.inspect
            expect(result.dig('data', 'project', 'enrollments', 'nodes')).to be_empty

            # Move extra annual to after the due period, confirm that enrollment is still excluded
            annual_outside_range.update(assessment_date: e1.entry_date + 16.months)

            response, result = post_graphql(id: p1.id, filters: { "householdTasks": ['ANNUAL_DUE'] }) { query }
            expect(response.status).to eq(200), result.inspect
            expect(result.dig('data', 'project', 'enrollments', 'nodes')).to be_empty
          end
        end
      end

      it 'should work correctly with other filters applied' do
        # Entered a year ago, annual is due
        e4 = create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c3, entry_date: Date.current - 1.year)
        # Entered less than a year ago, annual is not due
        create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: c3, entry_date: Date.current - 6.months)
        response, result = post_graphql(id: p1.id, filters: { "householdTasks": ['ANNUAL_DUE'], 'searchTerm': c3.last_name }) { query }
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'project', 'enrollments', 'nodes')).to contain_exactly(include('id' => e4.id.to_s))
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
