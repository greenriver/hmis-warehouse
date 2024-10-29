require 'rails_helper'
require_relative '../../requests/hmis/login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.feature 'Enrollment/household management', type: :system do
  include_context 'hmis base setup'
  # could parse CAPYBARA_APP_HOST
  let!(:ds1) { create(:hmis_data_source, hmis: 'localhost') }
  let!(:c1) { create :hmis_hud_client, data_source: ds1, user: u1, first_name: 'Quentin', last_name: 'Coldwater' }
  let!(:c2) { create :hmis_hud_client, data_source: ds1, user: u1, first_name: 'Alice', last_name: 'Quinn' }
  let!(:unit1) { create :hmis_unit, project: p1, user: user, name: 'unit 1' }
  let!(:unit2) { create :hmis_unit, project: p1, user: user, name: 'unit 2' }
  let!(:access_control) { create_access_control(hmis_user, p1) }
  # need with_coc so enrollment isn't blocked by CoC prompt
  # need funder so that certain form fields (Income, Health Insurance, etc.) show up for intakes in this project
  let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1, with_coc: true, funders: [20] }

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

    context 'with wip household' do
      it 'can submit an intake assessment' do
        # Confirm setup:
        expect(c1.enrollments.in_progress.count).to eq(1)
        expect(c2.enrollments.in_progress.count).to eq(1)
        e1 = c1.enrollments.in_progress.first
        e2 = c1.enrollments.in_progress.first
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
        complete_individual_assessment
        click_button 'Next'

        # second assessment
        complete_individual_assessment
        click_button 'Next'

        assert_text "Complete Entry to #{p1.project_name}"

        # Intakes are created as WIP
        expect(e1.reload.intake_assessment.wip).to eq(true)
        expect(e2.reload.intake_assessment.wip).to eq(true)

        with_hidden { check('select all') }

        row_numbers = [1, 2]
        row_numbers.each do |row|
          within(:xpath, "//table/tbody/tr[#{row}]") do
            assert_text('In Progress')
          end
        end
        click_button 'Submit (2) Intake Assessments'

        click_button 'Confirm'
        row_numbers.each do |row|
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
