###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MaYyaReport Client Classification', type: :model do
  let(:user) { create(:user) }
  let(:report) { MaYyaReport::Report.new(user_id: user.id) }
  let(:filter) do
    ::Filters::FilterBase.new(
      user_id: user.id,
      start: Date.new(2024, 1, 1),
      end: Date.new(2024, 12, 31),
      enforce_one_year_range: false,
    )
  end

  before do
    allow(report).to receive(:filter).and_return(filter)
  end

  describe 'client classification in report cells' do
    let!(:project) { create(:hud_project, project_type: 1) } # ES
    let!(:data_source) { create(:grda_warehouse_data_source) }
    let!(:organization) { create(:hud_organization, data_source: data_source) }

    before do
      project.update!(organization: organization, data_source: data_source)
    end

    describe 'Section A1: Street Outreach/Collaboration' do
      context 'A1a: Outreach contacts with homeless YYA' do
        let!(:client) { create(:hud_client, data_source: data_source) }
        let!(:enrollment) { create(:hud_enrollment, client: client, project: project, data_source: data_source, entry_date: Date.new(2024, 6, 1)) }

        it 'includes clients enrolled in street outreach who are currently homeless' do
          # Create a client record that matches A1a criteria
          client_record = MaYyaReport::Client.create!(
            client_id: client.id,
            service_history_enrollment_id: 1,
            entry_date: Date.new(2024, 6, 1),
            enrolled_in_street_outreach: true,
            currently_homeless: true,
            at_risk_of_homelessness: false,
            age: 20,
            gender: 1,
          )

          # Create a client that should NOT match (not enrolled in street outreach)
          non_matching_client = MaYyaReport::Client.create!(
            client_id: client.id + 1,
            service_history_enrollment_id: 2,
            entry_date: Date.new(2024, 6, 1),
            enrolled_in_street_outreach: false,
            currently_homeless: true,
            at_risk_of_homelessness: false,
            age: 20,
            gender: 1,
          )

          # Test the calculation logic
          calculators = report.send(:calculators)
          calculation = calculators[:A1a]

          expect(calculation).to be_present

          # Execute the query and verify results
          matching_clients = MaYyaReport::Client.where(calculation)
          expect(matching_clients).to include(client_record)
          expect(matching_clients).not_to include(non_matching_client)

          # Verify SQL contains expected conditions
          sql = calculation.to_sql
          expect(sql).to include('enrolled_in_street_outreach')
          expect(sql).to include('currently_homeless')
        end
      end

      context 'A1b: Outreach contacts with at-risk YYA' do
        it 'includes clients referred from outreach project who are at-risk' do
          # Create a client that matches A1b criteria
          matching_client = MaYyaReport::Client.create!(
            client_id: 123,
            service_history_enrollment_id: 1,
            entry_date: Date.new(2024, 6, 1),
            referral_source: 7, # Outreach Project
            at_risk_of_homelessness: true,
            currently_homeless: false,
            age: 19,
            gender: 0,
          )

          # Create a client that should NOT match (different referral source)
          non_matching_client = MaYyaReport::Client.create!(
            client_id: 124,
            service_history_enrollment_id: 2,
            entry_date: Date.new(2024, 6, 1),
            referral_source: 1, # Not outreach
            at_risk_of_homelessness: true,
            currently_homeless: false,
            age: 19,
            gender: 0,
          )

          calculators = report.send(:calculators)
          calculation = calculators[:A1b]

          expect(calculation).to be_present

          # Execute the query and verify results
          matching_clients = MaYyaReport::Client.where(calculation)
          expect(matching_clients).to include(matching_client)
          expect(matching_clients).not_to include(non_matching_client)

          # Verify SQL contains expected conditions
          sql = calculation.to_sql
          expect(sql).to include('referral_source')
          expect(sql).to include('at_risk_of_homelessness')
        end
      end
    end

    describe 'Section A2: Referrals Received' do
      context 'A2a: Initial contacts with homeless YYA' do
        it 'includes homeless clients with initial contact, excluding outreach' do
          # Create a client that matches A2a criteria
          matching_client = MaYyaReport::Client.create!(
            client_id: 456,
            service_history_enrollment_id: 1,
            entry_date: Date.new(2024, 6, 1),
            initial_contact: true,
            currently_homeless: true,
            enrolled_in_street_outreach: false,
            referral_source: 1, # Not outreach
            age: 22,
            gender: 1,
          )

          # Create a client that should NOT match (enrolled in street outreach)
          non_matching_client = MaYyaReport::Client.create!(
            client_id: 457,
            service_history_enrollment_id: 2,
            entry_date: Date.new(2024, 6, 1),
            initial_contact: true,
            currently_homeless: true,
            enrolled_in_street_outreach: true, # should be excluded from A2a
            referral_source: 7, # Outreach
            age: 22,
            gender: 1,
          )

          calculators = report.send(:calculators)
          calculation = calculators[:A2a]

          expect(calculation).to be_present

          # Execute the query and verify results
          matching_clients = MaYyaReport::Client.where(calculation)
          expect(matching_clients).to include(matching_client)
          expect(matching_clients).not_to include(non_matching_client)

          # Verify SQL contains expected conditions
          sql = calculation.to_sql
          expect(sql).to include('initial_contact')
          expect(sql).to include('currently_homeless')
          expect(sql).to include('enrolled_in_street_outreach')
        end
      end
    end

    describe 'Section D1: Age and Gender Demographics' do
      context 'D1a: Under 18' do
        it 'includes prevention clients under 18' do
          # Create a client that matches D1a criteria (under 18, at-risk)
          matching_client = MaYyaReport::Client.create!(
            client_id: 789,
            service_history_enrollment_id: 1,
            entry_date: Date.new(2024, 6, 1),
            at_risk_of_homelessness: true,
            age: 17,
            gender: 0,
          )

          # Create a client that should NOT match (18 or older)
          non_matching_client = MaYyaReport::Client.create!(
            client_id: 790,
            service_history_enrollment_id: 2,
            entry_date: Date.new(2024, 6, 1),
            at_risk_of_homelessness: true,
            age: 18, # Not under 18
            gender: 0,
          )

          calculators = report.send(:calculators)
          calculation = calculators[:D1a]

          expect(calculation).to be_present

          # Execute the query and verify results
          matching_clients = MaYyaReport::Client.where(calculation)
          expect(matching_clients).to include(matching_client)
          expect(matching_clients).not_to include(non_matching_client)

          # Verify SQL contains expected conditions
          sql = calculation.to_sql
          expect(sql).to include('age')
          expect(sql).to include('at_risk_of_homelessness')
        end
      end

      context 'D1b: Gender - Man' do
        it 'includes prevention clients who identify as man' do
          # Create a client that matches D1b criteria (man, at-risk)
          matching_client = MaYyaReport::Client.create!(
            client_id: 101,
            service_history_enrollment_id: 1,
            entry_date: Date.new(2024, 6, 1),
            at_risk_of_homelessness: true,
            age: 20,
            gender: 1, # Man
          )

          # Create a client that should NOT match (woman)
          non_matching_client = MaYyaReport::Client.create!(
            client_id: 103,
            service_history_enrollment_id: 2,
            entry_date: Date.new(2024, 6, 1),
            at_risk_of_homelessness: true,
            age: 20,
            gender: 0, # Woman
          )

          calculators = report.send(:calculators)
          calculation = calculators[:D1b]

          expect(calculation).to be_present

          # Execute the query and verify results
          matching_clients = MaYyaReport::Client.where(calculation)
          expect(matching_clients).to include(matching_client)
          expect(matching_clients).not_to include(non_matching_client)

          # Verify SQL contains expected conditions
          sql = calculation.to_sql
          expect(sql).to include('gender')
          expect(sql).to include('at_risk_of_homelessness')
        end
      end

      context 'D1d: Gender - Transgender' do
        it 'includes prevention clients who identify as transgender' do
          # Create a client that matches D1d criteria (transgender, at-risk)
          matching_client = MaYyaReport::Client.create!(
            client_id: 102,
            service_history_enrollment_id: 1,
            entry_date: Date.new(2024, 6, 1),
            at_risk_of_homelessness: true,
            age: 21,
            gender: 5, # Transgender
          )

          # Create a client that should NOT match (not transgender)
          non_matching_client = MaYyaReport::Client.create!(
            client_id: 104,
            service_history_enrollment_id: 2,
            entry_date: Date.new(2024, 6, 1),
            at_risk_of_homelessness: true,
            age: 21,
            gender: 1, # Man (not transgender)
          )

          calculators = report.send(:calculators)
          calculation = calculators[:D1d]

          expect(calculation).to be_present

          # Execute the query and verify results
          matching_clients = MaYyaReport::Client.where(calculation)
          expect(matching_clients).to include(matching_client)
          expect(matching_clients).not_to include(non_matching_client)

          # Verify SQL contains expected conditions
          sql = calculation.to_sql
          expect(sql).to include('gender')
          expect(sql).to include('= 5') # Transgender code
        end
      end
    end

    describe 'Section E1: Homeless Demographics - Age and Gender' do
      context 'E1a: Under 18 homeless' do
        it 'includes homeless clients under 18' do
          # Create a client that matches E1a criteria (under 18, homeless)
          matching_client = MaYyaReport::Client.create!(
            client_id: 201,
            service_history_enrollment_id: 1,
            entry_date: Date.new(2024, 6, 1),
            currently_homeless: true,
            age: 16,
            gender: 0,
          )

          # Create a client that should NOT match (18 or older)
          non_matching_client = MaYyaReport::Client.create!(
            client_id: 202,
            service_history_enrollment_id: 2,
            entry_date: Date.new(2024, 6, 1),
            currently_homeless: true,
            age: 18, # Not under 18
            gender: 0,
          )

          calculators = report.send(:calculators)
          calculation = calculators[:E1a]

          expect(calculation).to be_present

          # Execute the query and verify results
          matching_clients = MaYyaReport::Client.where(calculation)
          expect(matching_clients).to include(matching_client)
          expect(matching_clients).not_to include(non_matching_client)

          # Verify SQL contains expected conditions
          sql = calculation.to_sql
          expect(sql).to include('age')
          expect(sql).to include('currently_homeless')
        end
      end
    end

    describe 'Section D4/E4: Other Demographics' do
      context 'D4b/E4b: LGBTQ+ clients' do
        it 'includes clients with LGBTQ+ sexual orientation' do
          # Create a client that matches D4b criteria (LGBTQ+ sexual orientation)
          matching_client = MaYyaReport::Client.create!(
            client_id: 301,
            service_history_enrollment_id: 1,
            entry_date: Date.new(2024, 6, 1),
            at_risk_of_homelessness: true,
            sexual_orientation: 2, # Gay
            gender: 1,
            age: 23,
          )

          # Create a client that should NOT match (straight, non-transgender)
          non_matching_client = MaYyaReport::Client.create!(
            client_id: 303,
            service_history_enrollment_id: 2,
            entry_date: Date.new(2024, 6, 1),
            at_risk_of_homelessness: true,
            sexual_orientation: 1, # Straight
            gender: 1, # Man (not transgender or questioning)
            age: 23,
          )

          calculators = report.send(:calculators)
          calculation = calculators[:D4b]

          expect(calculation).to be_present

          # Execute the query and verify results
          matching_clients = MaYyaReport::Client.where(calculation)
          expect(matching_clients).to include(matching_client)
          expect(matching_clients).not_to include(non_matching_client)

          # Verify SQL contains expected conditions
          sql = calculation.to_sql
          expect(sql).to include('sexual_orientation')
          expect(sql).to include('gender')
        end

        it 'includes clients with transgender gender identity' do
          # Create a client that matches D4b criteria (transgender gender)
          matching_client = MaYyaReport::Client.create!(
            client_id: 302,
            service_history_enrollment_id: 1,
            entry_date: Date.new(2024, 6, 1),
            at_risk_of_homelessness: true,
            sexual_orientation: 1, # Straight
            gender: 5, # Transgender
            age: 24,
          )

          # Create a client that should NOT match (not LGBTQ+)
          non_matching_client = MaYyaReport::Client.create!(
            client_id: 304,
            service_history_enrollment_id: 2,
            entry_date: Date.new(2024, 6, 1),
            at_risk_of_homelessness: true,
            sexual_orientation: 1, # Straight
            gender: 1, # Man (not transgender or questioning)
            age: 24,
          )

          calculators = report.send(:calculators)
          calculation = calculators[:D4b]

          expect(calculation).to be_present

          # Execute the query and verify results
          # exercises LGBTQ+ identification logic (gender = 5 for transgender)
          matching_clients = MaYyaReport::Client.where(calculation)
          expect(matching_clients).to include(matching_client)
          expect(matching_clients).not_to include(non_matching_client)
        end
      end

      context 'D4a/E4a: Pregnant or Custodial Parenting' do
        it 'includes pregnant clients' do
          # Create a client that matches D4a criteria (pregnant)
          matching_client = MaYyaReport::Client.create!(
            client_id: 401,
            service_history_enrollment_id: 1,
            entry_date: Date.new(2024, 6, 1),
            at_risk_of_homelessness: true,
            pregnant: 1, # Yes
            due_date: Date.new(2024, 8, 1),
            household_ages: [20],
            age: 20,
            gender: 0,
          )

          # Create a client that should NOT match (not pregnant, no minors in household)
          non_matching_client = MaYyaReport::Client.create!(
            client_id: 403,
            service_history_enrollment_id: 2,
            entry_date: Date.new(2024, 6, 1),
            at_risk_of_homelessness: true,
            pregnant: 0, # No
            due_date: nil,
            household_ages: [20], # Only adults
            age: 20,
            gender: 0,
          )

          calculators = report.send(:calculators)
          calculation = calculators[:D4a]

          expect(calculation).to be_present

          # Execute the query and verify results
          matching_clients = MaYyaReport::Client.where(calculation)
          expect(matching_clients).to include(matching_client)
          expect(matching_clients).not_to include(non_matching_client)

          # Verify SQL contains expected conditions
          sql = calculation.to_sql
          expect(sql).to include('pregnant')
          expect(sql).to include('due_date')
        end

        it 'includes custodial parents (household with someone under 18)' do
          # Create a client that matches D4a criteria (custodial parent)
          matching_client = MaYyaReport::Client.create!(
            client_id: 402,
            service_history_enrollment_id: 1,
            entry_date: Date.new(2024, 6, 1),
            at_risk_of_homelessness: true,
            pregnant: 0, # No
            household_ages: [22, 16], # Adult with minor
            age: 22,
            gender: 0,
          )

          # Create a client that should NOT match (no minors in household, not pregnant)
          non_matching_client = MaYyaReport::Client.create!(
            client_id: 404,
            service_history_enrollment_id: 2,
            entry_date: Date.new(2024, 6, 1),
            at_risk_of_homelessness: true,
            pregnant: 0, # No
            household_ages: [22, 20], # Only adults
            age: 22,
            gender: 0,
          )

          calculators = report.send(:calculators)
          calculation = calculators[:D4a]

          expect(calculation).to be_present

          # Execute the query and verify results
          # exercises custodial parent query for households with minors
          matching_clients = MaYyaReport::Client.where(calculation)
          expect(matching_clients).to include(matching_client)
          expect(matching_clients).not_to include(non_matching_client)
        end
      end
    end

    describe 'Section F1: Prevention Outcomes' do
      context 'F1a: Prevention clients who remained housed' do
        it 'includes prevention clients who remained housed during reporting period' do
          # Create a client that matches F1a criteria (remained housed)
          matching_client = MaYyaReport::Client.create!(
            client_id: 501,
            service_history_enrollment_id: 1,
            entry_date: Date.new(2024, 6, 1),
            at_risk_of_homelessness: true,
            latest_homeless_cls_in_range: Date.new(2023, 12, 15), # Before entry
            age: 19,
            gender: 1,
          )

          # Create a client that should NOT match (became homeless during period)
          non_matching_client = MaYyaReport::Client.create!(
            client_id: 502,
            service_history_enrollment_id: 2,
            entry_date: Date.new(2024, 6, 1),
            at_risk_of_homelessness: true,
            latest_homeless_cls_in_range: Date.new(2024, 8, 1), # During reporting period
            age: 19,
            gender: 1,
          )

          calculators = report.send(:calculators)
          calculation = calculators[:F1a]

          expect(calculation).to be_present

          # Execute the query and verify results
          # exercises prevention_remained_housed_clause
          matching_clients = MaYyaReport::Client.where(calculation)
          expect(matching_clients).to include(matching_client)
          expect(matching_clients).not_to include(non_matching_client)
        end
      end
    end

    describe 'Section F2: Rehousing Outcomes' do
      context 'F2a: Transitioned to stabilized housing' do
        it 'includes homeless clients who became housed' do
          # Create a client that matches F2a criteria (became housed)
          matching_client = MaYyaReport::Client.create!(
            client_id: 601,
            service_history_enrollment_id: 1,
            entry_date: Date.new(2024, 3, 1),
            currently_homeless: true,
            latest_homeless_entry_date: Date.new(2024, 3, 1),
            permanent_exit_date: Date.new(2024, 8, 1),
            age: 21,
            gender: 0,
          )

          # Create a client that should NOT match (still homeless)
          non_matching_client = MaYyaReport::Client.create!(
            client_id: 602,
            service_history_enrollment_id: 2,
            entry_date: Date.new(2024, 3, 1),
            currently_homeless: true,
            latest_homeless_entry_date: Date.new(2024, 3, 1),
            permanent_exit_date: nil, # Still homeless
            age: 21,
            gender: 0,
          )

          calculators = report.send(:calculators)
          calculation = calculators[:F2a]

          expect(calculation).to be_present

          # Execute the query and verify results
          # exercises became_housed_clause
          matching_clients = MaYyaReport::Client.where(calculation)
          expect(matching_clients).to include(matching_client)
          expect(matching_clients).not_to include(non_matching_client)
        end
      end
    end
  end

  describe 'complex client scenarios' do
    it 'verifies homeless client appears in correct cells and not in prevention cells' do
      # Client who is homeless, LGBTQ+, under 18, and transgender
      complex_homeless_client = MaYyaReport::Client.create!(
        client_id: 999,
        service_history_enrollment_id: 1,
        entry_date: Date.new(2024, 6, 1),
        currently_homeless: true,
        at_risk_of_homelessness: false,
        enrolled_in_street_outreach: true,
        initial_contact: true,
        age: 17,
        gender: 5, # Transgender
        sexual_orientation: 3, # Lesbian
        race: 3, # African American
        ethnicity: 1, # Hispanic
        mental_health_disorder: true,
        substance_use_disorder: false,
        physical_disability: false,
        developmental_disability: true,
        pregnant: 0,
        employed: false,
        former_foster_ward: true,
        health_insurance: true,
      )

      calculators = report.send(:calculators)

      # Should appear in homeless-specific cells (test a subset that should match)
      homeless_cells_to_test = [:A1a, :E1a, :E1d] # Street outreach + under 18 homeless + transgender homeless

      aggregate_failures 'homeless client in homeless cells' do
        homeless_cells_to_test.each do |cell_key|
          calculation = calculators[cell_key]
          expect(calculation).to be_present, "Expected calculation for #{cell_key} to be present"

          matching_clients = MaYyaReport::Client.where(calculation)
          expect(matching_clients).to(
            include(complex_homeless_client),
            "Expected homeless client to appear in #{cell_key} but it didn't",
          )
        end
      end

      # Should NOT appear in prevention-only cells
      prevention_cells = [:D1a, :D1d, :TotalYYAServedPrevention]

      aggregate_failures 'homeless client not in prevention cells' do
        prevention_cells.each do |cell_key|
          calculation = calculators[cell_key]

          matching_clients = MaYyaReport::Client.where(calculation)
          expect(matching_clients).not_to(
            include(complex_homeless_client),
            "Expected homeless client NOT to appear in prevention cell #{cell_key} but it did",
          )
        end
      end
    end

    it 'verifies prevention client appears in correct cells and not in homeless cells' do
      # Client who is at-risk (prevention), LGBTQ+, under 18, and transgender
      complex_prevention_client = MaYyaReport::Client.create!(
        client_id: 998,
        service_history_enrollment_id: 2,
        entry_date: Date.new(2024, 6, 1),
        currently_homeless: false,
        at_risk_of_homelessness: true,
        enrolled_in_street_outreach: false,
        initial_contact: false,
        age: 17,
        gender: 5, # Transgender
        sexual_orientation: 3, # Lesbian
        race: 3, # African American
        ethnicity: 1, # Hispanic
        mental_health_disorder: true,
        substance_use_disorder: false,
        physical_disability: false,
        developmental_disability: true,
        pregnant: 0,
        employed: false,
        former_foster_ward: true,
        health_insurance: true,
      )

      calculators = report.send(:calculators)

      # Should appear in prevention-specific cells
      prevention_cells = [:D1a, :D1d] # Under 18 prevention + transgender prevention

      aggregate_failures 'prevention client in prevention cells' do
        prevention_cells.each do |cell_key|
          calculation = calculators[cell_key]
          expect(calculation).to be_present, "Expected calculation for #{cell_key} to be present"

          matching_clients = MaYyaReport::Client.where(calculation)
          expect(matching_clients).to(
            include(complex_prevention_client),
            "Expected prevention client to appear in #{cell_key} but it didn't",
          )
        end
      end

      # Should NOT appear in homeless-specific cells (test a subset)
      homeless_only_cells = [:A1a, :E1a, :E1d] # Street outreach + homeless demographics

      aggregate_failures 'prevention client not in homeless cells' do
        homeless_only_cells.each do |cell_key|
          calculation = calculators[cell_key]

          matching_clients = MaYyaReport::Client.where(calculation)
          expect(matching_clients).not_to(
            include(complex_prevention_client),
            "Expected prevention client NOT to appear in homeless cell #{cell_key} but it did",
          )
        end
      end
    end
  end
end
