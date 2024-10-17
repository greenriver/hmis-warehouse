#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

require 'rails_helper'
require_relative '../../requests/hmis/login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.feature 'Hmis Form behavior for HUD elements', type: :system do
  include_context 'hmis base setup'
  let!(:ds1) { create(:hmis_data_source, hmis: 'localhost') }
  let!(:c1) { create :hmis_hud_client, data_source: ds1, user: u1, first_name: 'Marlon', last_name: 'Harris' }
  let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1, with_coc: true, funders: [20] }
  let!(:e1) { create :hmis_hud_wip_enrollment, data_source: ds1, project: p1, client: c1 }
  let!(:access_control) { create_access_control(hmis_user, p1) }

  let(:today) { Date.current }

  before(:each) do
    sign_in(hmis_user)
    visit "/client/#{c1.id}/enrollments/#{e1.id}/intake"
  end

  def save_ignoring_warnings
    first(:button, 'Submit').click
    assert_text 'Ignore Warnings'
    click_button 'Confirm'
    e1.reload
  end

  describe 'enrollment coc' do
    it 'auto-selects CoC on intake' do
      expect(mui_select_value_for('CoC Code for Client Location')).to eq('XX-500 - Test CoC')
    end
  end

  describe 'prior living situation' do
    context 'with a SO, ES, or SH project' do
      it 'renders the prior living situation, version A' do
        assert_text 'Where did the client spend the night before project entry?'

        # All of these are visible on page load - there are no conditionals in this version
        assert_text 'Length of stay in prior living situation'
        assert_text 'Approximate date this episode of homelessness started'
        assert_text 'number of times the client has been on the streets'
        assert_text 'Total number of months homeless'

        # Temporarily make selection that doesn't indicate rental subsidy
        mui_select 'Emergency shelter, including hotel or motel paid for with emergency shelter voucher, or Host Home shelter', from: 'Prior Living Situation'
        assert_no_text 'Rental subsidy type' # Rental subsidy type is not asked. This is the only conditional in the simpler version
        # Now select to indicate rental subsidy
        mui_select 'Rental by client, with ongoing housing subsidy', from: 'Prior Living Situation'
        assert_text 'Rental subsidy type'
        mui_select 'Permanent Supportive Housing', from: 'Rental subsidy type'

        # Fill in the rest of the prior living situation info
        mui_select 'One night or less', from: 'Length of stay in prior living situation'
        mui_date_select 'Approximate date this episode of homelessness started', date: today - 2.days
        mui_select 'One time', from: /Regardless of where they stayed the night before/
        mui_select '3', from: /Total number of months homeless/

        # Submit the intake and check the changes on the enrollment
        expect do
          save_ignoring_warnings
        end.to change(e1, :living_situation).to(435).
          and change(e1, :rental_subsidy_type).to(439).
          and change(e1, :length_of_stay).to(10).
          and change(e1, :date_to_street_essh).to(today - 2.days).
          and change(e1, :times_homeless_past_three_years).to(1).
          and change(e1, :months_homeless_past_three_years).to(103)
      end
    end

    context 'with another project type' do
      let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, project_type: 2, with_coc: true }

      it 'renders the prior living situation, version B' do
        assert_text 'Where did the client spend the night before project entry?'

        # These aren't visible on pageload since we are in the conditional version
        assert_no_text 'Length of stay'
        assert_no_text 'Approximate date this episode of homelessness started'
        assert_no_text 'number of times the client has been on the streets'
        assert_no_text 'Total number of months homeless'
        assert_no_text 'Rental subsidy type'
      end

      it 'displays correct options and saves correctly when PLS is homeless situation' do
        mui_select 'Safe Haven', from: 'Prior Living Situation'
        assert_text 'Approximate date this episode of homelessness started'
        assert_text 'number of times the client has been on the streets'
        assert_text 'Total number of months homeless'

        mui_date_select 'Approximate date this episode of homelessness started', date: today - 4.weeks
        mui_select 'Four or more times', from: /Regardless of where they stayed the night before/
        mui_select 'More than 12 months', from: /Total number of months homeless/

        expect do
          save_ignoring_warnings
        end.to change(e1, :living_situation).to(118).
          and change(e1, :date_to_street_essh).to(today - 4.weeks).
          and change(e1, :times_homeless_past_three_years).to(4).
          and change(e1, :months_homeless_past_three_years).to(113)
      end

      it 'displays correct options and saves correctly when PLS is institutional' do
        mui_select 'Psychiatric hospital or other psychiatric facility', from: 'Prior Living Situation'
        assert_text 'Length of stay in prior living situation'

        # Temporarily select 90+ days indicates 'break' in chronic homelessness
        mui_select '90 days or more but less than one year', from: 'Length of stay in prior living situation'
        assert_text 'Client does not meet the HUD definition of chronic at entry.'

        mui_select 'One month or more, but less than 90 days', from: 'Length of stay in prior living situation'
        assert_no_text 'Client does not meet the HUD definition of chronic at entry.'
        assert_text 'On the night before entering the Institutional/Temporary/Permanent/Other housing situation, did the client stay on the streets, ES or SH?'

        # Temporarily select YES to night-before question, to confirm form logic
        mui_radio_choose 'Yes', from: 'On the night before entering the Institutional/Temporary/Permanent/Other housing situation, did the client stay on the streets, ES or SH?'
        assert_no_text 'Client does not meet the HUD definition of chronic homelessness.'
        assert_text 'Approximate date this episode of homelessness started'
        assert_text 'number of times the client has been on the streets'
        assert_text 'Total number of months homeless'

        # Submit with non-chronic client
        mui_radio_choose 'No', from: 'On the night before entering the Institutional/Temporary/Permanent/Other housing situation, did the client stay on the streets, ES or SH?'
        assert_text 'Client does not meet the HUD definition of chronic homelessness.'

        expect do
          save_ignoring_warnings
        end.to change(e1, :living_situation).to(204).
          and change(e1, :los_under_threshold).to(1)
      end
    end
  end

  describe 'income' do
    context 'with project type of ES and none of the funder rules met' do
      let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1, funders: [] }

      it 'does not collect income' do
        assert_no_text 'Income from Any Source'

        expect do
          save_ignoring_warnings
        end.not_to change(e1.income_benefits, :count)
      end
    end

    context 'with PSH project type' do
      let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, project_type: 3, with_coc: true }
      let!(:f1) { create :hmis_hud_funder, data_source: ds1, project: p1 }

      it 'hides income table when No is selected' do
        assert_text 'Income from Any Source'
        assert_text 'Income Sources and Monthly Total'
        mui_radio_choose 'No', from: 'Income from Any Source'
        assert_no_text 'Income Sources and Monthly Total'

        expect do
          save_ignoring_warnings
        end.to change(e1.income_benefits, :count).by(1)

        expect(e1.income_benefits.sole.income_from_any_source).to eq(0)
      end

      it 'autoselects Yes when income is entered in table' do
        fill_in 'Earned Income (i.e., employment income)', with: '200'
        expect(mui_radio_value_for('Income from Any Source')).to eq('YES')
      end

      it 'correctly sums all income sources in the total row' do
        fill_in 'Earned Income (i.e., employment income)', with: '200'
        fill_in 'Supplemental Security Income (SSI)', with: '100'
        fill_in 'Temporary Assistance for Needy Families (TANF)', with: '100'
        fill_in 'Other source', with: '100'
        expect(find('[data-testid="inputSum"]').text).to eq('$500.00')

        expect do
          save_ignoring_warnings
        end.to change(e1.income_benefits, :count).by(1)

        expect(e1.income_benefits.sole.total_monthly_income).to eq(500)
      end

      it 'does not collect SOAR question' do
        assert_no_text 'Connection with SOAR'
      end

      context 'when SOAR should be collected' do
        let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, project_type: 13, with_coc: true } # 13 = PH - Rapid Re-Housing
        let!(:f1) { create :hmis_hud_funder, data_source: ds1, project: p1, funder: 33 } # VA SSVF

        it 'collects SOAR question' do
          assert_text 'Connection with SOAR'
          fill_in 'Earned Income (i.e., employment income)', with: '200'
          mui_select 'Yes', from: 'Connection with SOAR'

          expect do
            save_ignoring_warnings
          end.to change(e1.income_benefits, :count).by(1)

          expect(e1.income_benefits.sole.total_monthly_income).to eq(200)
          expect(e1.income_benefits.sole.connection_with_soar).to eq(1)
        end
      end
    end
  end

  describe 'benefits' do
    let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, project_type: 3, with_coc: true }
    let!(:f1) { create :hmis_hud_funder, data_source: ds1, project: p1 }

    it 'hides health insurance table when No is selected' do
      assert_text 'Covered by Health Insurance'
      assert_text 'Select Insurance Provider(s)'
      mui_radio_choose 'No', from: 'Covered by Health Insurance'
      assert_no_text 'Select Insurance Provider(s)'

      expect do
        save_ignoring_warnings
      end.to change(e1.income_benefits, :count).by(1)

      expect(e1.income_benefits.sole.insurance_from_any_source).to eq(0)
    end

    it 'autoselects Yes when any health insurance provider is selected in table' do
      find('[aria-label="Veteran\'s Health Administration (VHA)"]').check
      find('[aria-label="Medicare"]').check
      expect(mui_radio_value_for('Covered by Health Insurance')).to eq('YES')

      expect do
        save_ignoring_warnings
      end.to change(e1.income_benefits, :count).by(1)

      expect(e1.income_benefits.sole.insurance_from_any_source).to eq(1)
      expect(e1.income_benefits.sole.vha_services).to eq(1)
      expect(e1.income_benefits.sole.medicare).to eq(1)
    end
  end

  describe 'disabilities' do
    context 'with project type of ES and no funders' do
      let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1, funders: [] }

      it 'renders limited disability component, only collecting overall disabling condition' do
        assert_text 'Disabling Condition'
        assert_no_text 'The following questions help determine if there are additional housing services or benefits available for the client.'
        expect(mui_select_value_for('Disabling Condition')).to eq('Data not collected')
      end

      it 'saves overall disabling condition as yes' do
        mui_select('Yes', from: 'Disabling Condition')

        expect do
          save_ignoring_warnings
        end.to change(e1, :disabling_condition).to(1)
      end

      it 'saves overall disabling condition as no' do
        mui_select('No', from: 'Disabling Condition')

        expect do
          save_ignoring_warnings
        end.to change(e1, :disabling_condition).to(0)
      end
    end

    context 'with project that collects granular disability info' do
      it 'renders full disability component' do
        assert_text 'Overall Disabling Condition'
        assert_text 'The following questions help determine if there are additional housing services or benefits available for the client.'
        assert_text 'Physical Disability' # etc.
        click_link 'Disability' # scrolls Disability into view
        expect(mui_table_value_for(row: 'Overall Disabling Condition', column: 'Status')).to eq('Data not collected')
      end

      it 'updates overall Disabling Condition when you select Yes' do
        mui_table_select('Yes', row: 'Physical Disability', column: 'Status')
        mui_table_select('Yes', row: 'Physical Disability', column: 'Disabling Condition')
        expect(mui_table_value_for(row: 'Overall Disabling Condition', column: 'Status')).to eq('Yes')

        expect do
          save_ignoring_warnings
        end.to change(e1, :disabling_condition).to(1)
        expect(e1.disabilities.where(disability_type: 5).sole.indefinite_and_impairs).to eq(1)
      end

      it 'updates overall Disabling Condition when you select an always-disabling condition' do
        mui_table_select('Yes', row: 'Developmental Disability', column: 'Status')
        expect(mui_table_value_for(row: 'Overall Disabling Condition', column: 'Status')).to eq('Yes')

        expect do
          save_ignoring_warnings
        end.to change(e1, :disabling_condition).to(1)
      end
    end

    context 'with project that is HOPWA funded' do
      let!(:p1) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1, with_coc: true, funders: [19] }

      it 'includes HOPWA specific questions' do
        click_link 'Disability' # scrolls Disability into view
        mui_table_select('Yes', row: 'HIV/AIDS', column: 'Status')
        assert_text 'HOPWA Questions'
        mui_select 'Yes', from: 'T-Cell (CD4) Count Available'
        fill_in 'T-Cell Count', with: 200
        mui_radio_choose 'Medical Report', from: 'How was the information obtained?'
        mui_select 'Available', from: 'Viral Load Information Available'
        fill_in 'Viral Load Count', with: 200

        # special-case since there are now 2 elements with the same aria label
        within all('[aria-label="How was the information obtained?"]')[1] do
          choose('Medical Report')
        end

        mui_select 'Yes', from: 'Has the participant been prescribed anti-retroviral drugs?'

        expect do
          save_ignoring_warnings
        end.to change(e1.disabilities.where(disability_type: 8), :count).from(0).to(1)

        disability = e1.disabilities.where(disability_type: 8).sole
        expect(disability.t_cell_count_available).to eq(1)
        expect(disability.t_cell_count).to eq(200)
        expect(disability.t_cell_source).to eq(1)
        expect(disability.viral_load_available).to eq(1)
        expect(disability.viral_load).to eq(200)
        expect(disability.viral_load_source).to eq(1)
        expect(disability.anti_retroviral).to eq(1)
      end
    end
  end
end
