###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../requests/hmis/login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.feature 'Intake Assessment for Household', type: :system do
  include_context 'hmis base setup'
  # could parse CAPYBARA_APP_HOST
  let!(:ds1) { GrdaWarehouse::DataSource.hmis.find_by(hmis: 'localhost') }
  let!(:c1) { create :hmis_hud_client, data_source: ds1, user: u1, first_name: 'Quentin', last_name: 'Coldwater' }
  let!(:c2) { create :hmis_hud_client, data_source: ds1, user: u1, first_name: 'Alice', last_name: 'Quinn' }
  let!(:unit1) { create :hmis_unit, project: p1, user: user, name: 'unit 1' }
  let!(:unit2) { create :hmis_unit, project: p1, user: user, name: 'unit 2' }
  let!(:access_control) { create_access_control(hmis_user, p1) }

  # Set up Rapid Re-Housing project (13) with funder 'HUD: CoC - Rapid Re-Housing' (3)
  # which should collect all fields (Income, Health Insurance, all disability fields, etc.)
  # need with_coc so enrollment isn't blocked by CoC prompt
  let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, project_type: 13, funders: [3], with_coc: true }

  let(:today) { Date.current }

  context 'An active project' do
    before(:each) do
      make_household(enrollment_factory: :hmis_hud_wip_enrollment)
      sign_in(hmis_user)

      click_link 'Projects'
      click_link p1.project_name
      click_link 'Enrollments'
    end

    def make_household(household_id: Hmis::Hud::Base.generate_uuid, enrollment_factory:)
      [
        [c1, { RelationshipToHoH: 1 }],
        [c2, { RelationshipToHoH: 99 }],
      ].each do |client, enrollment_attrs|
        enrollment_attrs.merge!(
          client: client,
          HouseholdID: household_id,
          project: p1,
          entry_date: today - 5.days,
          user: u1,
        )
        create(enrollment_factory, **enrollment_attrs)
      end
      Hmis::Hud::Household.where(household_id: household_id).first!
    end

    def complete_individual_assessment
      default_option = 'Client prefers not to answer'
      mui_select default_option, from: 'Prior Living Situation'
      mui_select default_option, from: 'Length of stay in prior living situation'
      mui_radio_choose default_option, from: 'Income from Any Source'
      mui_radio_choose default_option, from: 'Non-Cash Benefits from Any Source'
      mui_radio_choose default_option, from: 'Covered by Health Insurance'
      mui_table_select default_option, row: 'Overall Disabling Condition', column: 'Status'
      mui_select default_option, from: 'Survivor of Domestic Violence'
      click_button 'Save Assessment'
      assert_text(/Last saved [0-9] seconds? ago/)
    end

    # Helper to submit all in-progress intake assessments for a household from the Summary tab
    def submit_household_intakes(household_size:)
      assert_text 'Complete Entry'

      row_numbers = (1..household_size).to_a
      # Confirm all intakes are in progress
      row_numbers.each do |row|
        within(:xpath, "//table/tbody/tr[#{row}]") do
          assert_text('In Progress')
        end
      end

      with_hidden { check('select all') }

      click_button "Submit (#{household_size}) Intake Assessments"

      # Confirm warning modal about missing fields
      assert_text 'Ignore Warnings'
      click_button 'Confirm'
      assert_no_text 'Ignore Warnings'
    end

    context 'with wip household' do
      it 'persists entry date when saved as WIP and shows it when reopening' do
        hoh_enrollment = c1.enrollments.in_progress.sole
        new_entry_date = hoh_enrollment.entry_date - 3.days

        visit "/client/#{c1.id}/enrollments/#{hoh_enrollment.id}/intake"

        mui_expect_selected_tab('#tab-1')
        mui_date_select 'Entry Date', date: new_entry_date
        complete_individual_assessment

        expect(hoh_enrollment.reload.intake_assessment).to be_present
        expect(hoh_enrollment.intake_assessment.wip).to eq(true)
        expect(hoh_enrollment.intake_assessment.form_processor.values['entry_date']).to eq(new_entry_date.strftime('%Y-%m-%d'))

        visit "/client/#{c1.id}/enrollments/#{hoh_enrollment.id}/intake"

        mui_expect_selected_tab('#tab-1')
        expect(page).to have_field('Entry Date', with: new_entry_date.strftime('%m/%d/%Y'))
      end

      it 'updates HoH enrollment entry date when household intake is submitted' do
        hoh_enrollment = c1.enrollments.in_progress.sole
        hhm_enrollment = c2.enrollments.in_progress.sole

        old_entry_date = hoh_enrollment.entry_date
        new_entry_date = old_entry_date - 3.days

        visit "/client/#{c1.id}/enrollments/#{hoh_enrollment.id}/intake"

        mui_expect_selected_tab('#tab-1')
        mui_date_select 'Entry Date', date: new_entry_date
        complete_individual_assessment
        click_button 'Next'

        mui_expect_selected_tab('#tab-2')
        complete_individual_assessment # Fill out other fields for Non-HoH enrollment, but don't change the Entry Date
        click_button 'Next'

        mui_expect_selected_tab('#tab-summary')

        # Submit both intakes and wait for submission to complete
        submit_household_intakes(household_size: 2)

        # FIXME(#9121): there is a frontend bug causing the page to sometimes
        # navigate to the submitted HoH's assessment, instead of staying on the summary
        # tab. That needs to be fixed on the frontend. This test uses the below assertion
        # to wait for submission to complete (rather than asserting on the Summary Tab
        # showing submitted status) to get around that bug.
        page.driver.wait_for_network_idle
        expect(page).not_to have_button('Submit (2) Intake Assessments')

        # HoH enrollment entry date is updated
        expect(hoh_enrollment.reload.entry_date).to eq(new_entry_date.to_date)
        # Non-HoH enrollment entry date is not updated
        expect(hhm_enrollment.reload.entry_date).to eq(old_entry_date.to_date)
      end

      it 'can submit an intake assessment' do
        # Confirm setup:
        expect(c1.enrollments.in_progress.count).to eq(1)
        expect(c2.enrollments.in_progress.count).to eq(1)
        e1 = c1.enrollments.in_progress.first
        e2 = c2.enrollments.in_progress.first
        expect(e1.intake_assessment).to be_nil
        expect(e2.intake_assessment).to be_nil

        fill_in 'Search Clients', with: c1.last_name
        click_link c1.brief_name
        click_link 'Assessments'
        click_link 'Finish Intake'

        assert_text('Household Intake')
        assert_text(p1.project_name)
        assert_text(c2.brief_name)
        assert_text(c1.brief_name)

        # first assessment
        mui_expect_selected_tab('#tab-1')
        complete_individual_assessment
        click_button 'Next'

        # second assessment
        mui_expect_selected_tab('#tab-2')
        complete_individual_assessment
        click_button 'Next'

        mui_expect_selected_tab('#tab-summary')
        assert_text "Complete Entry to #{p1.project_name}"

        # Intakes are created as WIP
        expect(e1.reload.intake_assessment.wip).to eq(true)
        expect(e2.reload.intake_assessment.wip).to eq(true)

        # Submit both intakes and wait for submission to complete
        submit_household_intakes(household_size: 2)

        # Confirm all intakes are submitted
        [1, 2].each do |row|
          within(:xpath, "//table/tbody/tr[#{row}]") do
            assert_text('Submitted')
          end
        end

        # Enrollments are created as non-WIP
        expect(e1.reload.in_progress?).to eq(false)
        expect(e2.reload.in_progress?).to eq(false)

        # Intakes are non-WIP
        expect(e1.intake_assessment.wip).to eq(false)
        expect(e2.intake_assessment.wip).to eq(false)
      end
    end
  end
end
