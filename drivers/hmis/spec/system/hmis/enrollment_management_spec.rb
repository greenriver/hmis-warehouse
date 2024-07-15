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

  def submit_enrollment_form(entry_date:, relationship_to_hoh: 'Self (HoH)', coc_code: nil)
    mui_date_select 'Entry Date', date: entry_date
    mui_select relationship_to_hoh, from: 'Relationship to HoH'
    mui_select coc_code, from: 'Enrollment CoC' if coc_code
    click_button 'Enroll'
  end

  def search_for_client(client)
    fill_in 'Search Clients', with: client.last_name
    click_button 'Search'
  end

  context 'An active project with CoC' do
    before(:each) do
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
        assert_no_selector "[role='dialog']" # wait for dialog to close
      end.to change(c1.enrollments, :count).by(1)
      assert_text(c1.brief_name)

      # add client 2 to household
      search_for_client(c2)
      click_button('Add to Household')
      household = c1.households.where(earliest_entry: entry_date).first!
      expect do
        submit_enrollment_form(entry_date: entry_date, relationship_to_hoh: 'Other relative')
        assert_no_selector "[role='dialog']" # wait for dialog to close
      end.to change(household.enrollments.where(personal_id: c2.personal_id), :count).by(1)
      # should see both clients
      assert_text(c1.brief_name)
      assert_text(c2.brief_name)
    end

    it 'shows error when the user tries to submit an invalid date' do
      click_link 'Add Enrollment'
      search_for_client(c1)
      click_button('Enroll Client')
      entry_date = today + 2.days # invalid date - in the future
      submit_enrollment_form(entry_date: entry_date)
      assert_text('Please fix outstanding errors')
      assert_text('Entry date cannot be in the future')
      expect(c1.enrollments.count).to eq(0)
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
        assert_text(c2.brief_name) # non-HoH
        assert_text(c1.brief_name) # HoH

        # These radio selects need better a11y
        find("[aria-label='HoH status for #{c2.brief_name}']", visible: false).click
        assert_text("Head of Household will change from #{c1.brief_name} to #{c2.brief_name}")
        expect do
          click_button('Confirm')
          expect(find("[aria-label='HoH status for #{c1.brief_name}']", visible: false)).not_to be_checked
          expect(find("[aria-label='HoH status for #{c2.brief_name}']", visible: false)).to be_checked
        end.to change(c2.enrollments.where(relationship_to_hoh: 1), :count).by(1)
      end

      it 'can remove a non-HoH member' do
        expect do
          click_button "aria-label='Remove #{c2.brief_name}'" # no confirmation here, since enrollment is WIP
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
        assert_no_selector "[role='dialog']" # wait for dialog to close

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

  context 'An active project with multiple CoCs' do
    let!(:pc1) { create :hmis_hud_project_coc, data_source: ds1, project: p1, coc_code: 'CO-500', user: u1 }

    before(:each) do
      sign_in(hmis_user)
      click_link 'Projects'
      click_link p1.project_name
      click_link 'Enrollments'
    end

    it 'can enroll a household member' do
      click_link 'Add Enrollment'
      search_for_client(c1)
      click_button('Enroll Client')
      entry_date = today - 2.days
      expect do
        submit_enrollment_form(entry_date: entry_date, coc_code: pc1.coc_code)
        assert_no_selector "[role='dialog']" # wait for dialog to close
      end.to change(c1.enrollments, :count).by(1)
      assert_text(c1.brief_name)
    end
  end
end
