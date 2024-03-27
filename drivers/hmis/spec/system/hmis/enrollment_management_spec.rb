require 'rails_helper'
require_relative '../../requests/hmis/login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.feature 'Enrollment/household management', type: :system do
  include_context 'hmis base setup'
  # could parse CAPYBARA_APP_HOST
  let!(:ds1) { create(:hmis_data_source, hmis: 'localhost') }
  let!(:c1) { create :hmis_hud_client, data_source: ds1, user: u1, first_name: 'Quentin', last_name: 'Coldwater' }
  let!(:c2) { create :hmis_hud_client, data_source: ds1, user: u1, first_name: 'Alice', last_name: 'Quinn' }
  let!(:access_control) { create_access_control(hmis_user, p1) }
  # need with_coc so enrollment isn't blocked by CoC prompt
  let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1, with_coc: true }

  let(:today) { Date.current }

  context 'An active project' do
    before(:each) do
      sign_in(hmis_user)
      click_link 'Projects'
      click_link p1.project_name
      click_link 'Enrollments'
    end

    def submit_enrollment_form(entry_date:, relationship_to_hoh: 'Self (HoH)')
      mui_date_select 'Entry Date', date: entry_date
      mui_select relationship_to_hoh, from: 'Relationship to HoH'
      click_button 'Enroll'
    end

    def search_for_client(client)
      fill_in 'Search Clients', with: client.last_name
      click_button 'Search'
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
        # create(:hmis_hud_enrollment, **enrollment_attrs)
        create(enrollment_factory, **enrollment_attrs)
      end
      Hmis::Hud::Household.where(household_id: household_id).first!
    end

    it 'can enroll multiple household members' do
      click_link 'Add Enrollment'
      search_for_client(c1)
      click_button('Enroll Client')
      entry_date = today - 2.days
      expect do
        submit_enrollment_form(entry_date: entry_date)
      end.to change(c1.enrollments, :count).by(1)
      assert_text(c1.brief_name)

      # add client 2 to household
      search_for_client(c2)
      click_button('Add to Household')
      household = c1.households.where(earliest_entry: entry_date).first!
      expect do
        submit_enrollment_form(entry_date: entry_date, relationship_to_hoh: 'Other relative')
      end.to change(household.enrollments.where(personal_id: c2.personal_id), :count).by(1)
      # should see both clients
      assert_text(c1.brief_name)
      assert_text(c2.brief_name)
    end

    context 'with wip household' do
      before(:each) do
        make_household(enrollment_factory: :hmis_hud_wip_enrollment)
        fill_in 'Search Clients', with: c1.last_name
        click_link c1.brief_name
        click_link 'Household'
        click_link 'Manage Household'
      end

      it 'can change relationship to HoH' do
        assert_text(c2.brief_name)
        assert_text(c1.brief_name)

        # choose second row. These radio selects need better a11y
        # find(:xpath, "//table/tbody/tr[2]/td/*[normalize-space()='HoH']").click
        within(:xpath, '//table/tbody/tr[2]') do
          with_hidden { choose('HoH') }
        end
        assert_text("Head of Household will change from #{c1.brief_name} to #{c2.brief_name}")
        expect do
          click_button('Confirm')
          within(:xpath, '//table/tbody/tr[2]') do
            with_hidden { expect(page).to have_checked_field('HoH') }
          end
        end.to change(c2.enrollments.where(relationship_to_hoh: 1), :count).by(1)
      end

      it 'can change remove a non-HoH member' do
        expect do
          within(:xpath, '//table/tbody/tr[2]') do
            click_button('Remove') # no confirmation here
          end
          assert_no_text(c2.brief_name)
        end.to change(c2.enrollments, :count).by(-1)
      end
    end

    context 'with exited household' do
      before(:each) do
        household = make_household(enrollment_factory: :hmis_hud_enrollment)
        household.enrollments.each do |enrollment|
          exit = create(
            :hmis_hud_exit,
            PersonalID: enrollment.client.personal_id,
            EnrollmentID: enrollment.enrollment_id,
            data_source: ds1,
            user: u1,
          )
          # override garbage factory exit date
          exit.update!(exit_date: today - 4.days)
        end
      end

      it 'shows previously active members on a new enrollment' do
        entry_date = today - 2.days
        click_link 'Add Enrollment'
        search_for_client(c1)
        click_button('Enroll Client')
        submit_enrollment_form(entry_date: entry_date)

        # now we have to go back and find the enrollment again to see prev members
        click_link 'Enrollments', match: :first
        assert_text(c1.brief_name)
        click_link c1.brief_name, match: :first
        click_link 'Household'
        click_link 'Manage Household'

        # should see client 2
        assert_text('Previously Associated Members')
        assert_text(c2.brief_name)
        assert_text('Add to Household')
      end
    end
  end
end
