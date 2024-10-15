#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

require 'rails_helper'
require_relative '../../requests/hmis/login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.feature 'Hmis Form behavior', type: :system do
  include_context 'hmis base setup'
  let!(:ds1) { create(:hmis_data_source, hmis: 'localhost') }

  let!(:c1) { create :hmis_hud_client, data_source: ds1, user: u1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }
  let!(:definition) { create :hmis_form_definition, title: 'A special assessment', role: 'CUSTOM_ASSESSMENT', data_source: ds1 }
  let!(:access_control) { create_access_control(hmis_user, p1) }

  let(:today) { Date.current }

  before(:each) do
    sign_in(hmis_user)
    visit "/client/#{c1.id}/enrollments/#{e1.id}/assessments/new/#{definition.id}"
    mui_date_select 'Assessment Date', date: today
  end

  describe 'required and warn_if_empty' do
    before(:each) do
      assert_text "Back to #{c1.full_name}"
      assert_text definition.title
    end

    it 'does not let you submit without required fields' do
      mui_date_select 'Assessment Date', date: nil
      click_button 'Submit'
      assert_text 'Please fix outstanding errors'
      assert_text 'The Required Field must exist'
      assert_text 'Assessment Date must exist'
    end

    it 'warns you of empty fields that have warn_if_empty, but still lets you submit' do
      fill_in 'A required field', with: 'tomatoes'
      click_button 'Submit'
      assert_text 'Please confirm the following warnings.'
      assert_text '1 field was left empty'
      click_button 'Confirm'
      assert_text "#{c1.full_name} Assessments"
      expect(all('tbody tr').count).to eq(1)
      expect(all('tbody tr').first.text).to match(/A special assessment/)
    end
  end

  describe 'bounds' do
    let!(:definition) { create :custom_assessment_with_bounds, data_source: ds1 }

    it 'enforces error-level date bound' do
      mui_date_select 'Date with Bounds', date: (today + 3.days).to_date
      assert_text 'Must be in range'
      click_button 'Submit'
      # TODO(#6713) - bound is not enforced, add assert here when we have client-side validation
      # assert_text 'Please fix outstanding errors'
    end

    it 'warns about warning-level date bound' do
      mui_date_select 'Date with Bounds', date: (today - 3.days).to_date
      assert_text 'Must be in range'
      click_button 'Submit'
      assert_text "#{c1.full_name} Assessments" # Still lets you submit
    end

    it 'enforces number max bound' do
      fill_in 'How many?', with: '200'
      find('#how_many').native.send_keys(:tab) # tab to blur
      assert_text 'Must be less than or equal to 10'
      click_button 'Submit'
      # TODO(#6713) - bound is not enforced
      # assert_text 'Please fix outstanding errors'
    end

    it 'enforces number min bound' do
      fill_in 'How many?', with: '-20'
      find('#how_many').native.send_keys(:tab) # tab to blur
      assert_text 'Must be greater than or equal to 3'
      click_button 'Submit'
      # TODO(#6713) - bound is not enforced
      # assert_text 'Please fix outstanding errors'
    end

    it 'enforces string max bound (field character count)' do
      fill_in 'Why?', with: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.'
      expect(find('#why').value).to eq('Lorem ipsu') # Cuts off anything longer than 10 characters
      assert_no_text 'dolor sit amet'
    end

    # TODO(#6539) - min bound doesn't currently work
    # it 'enforces string min bound (field character count)' do
    #   fill_in 'Why?', with: 'a'
    #   find('#why').native.send_keys(:tab) # tab to blur
    #   click_button 'Submit'
    #   assert_text 'Please fix outstanding errors'
    # end
  end

  describe 'behavior of conditionals (enable_when)' do
    let!(:definition) { create :custom_assessment_with_conditionals, data_source: ds1 }

    it 'hides when boolean condition is not met, and shows when met' do
      assert_no_text 'Conditional on boolean'
      find('[data-testid="option-false"]').click
      assert_no_text 'Conditional on boolean'
      find('[data-testid="option-true"]').click
      assert_text 'Conditional on boolean'
      fill_in 'Conditional on boolean', with: 'This can only be filled when true'
      click_button 'Submit'
      assert_text "#{c1.full_name} Assessments"
      cded = Hmis::Hud::CustomDataElementDefinition.where(key: 'conditional_boolean').sole
      expect(Hmis::Hud::CustomDataElement.of_type(cded).sole.value).to eq('This can only be filled when true')
    end

    it 'hides when date comparison condition is not met, and shows when met' do
      # 3-in-1 test - tests answerDate, greater-than operator, and compareQuestion
      assert_no_text 'Conditional on date'
      mui_date_select 'Date to compare', date: (today - 2.days).to_date
      assert_no_text 'Conditional on date'
      mui_date_select 'Date to compare', date: (today + 2.days).to_date
      assert_text 'Conditional on date'
      fill_in 'Conditional on date', with: 'compare date is greater than assessment date!'
    end

    it 'hides when multi-part condition is not fully met, and shows when met' do
      assert_no_text 'Conditional on date AND boolean'
      mui_date_select 'Date to compare', date: (today - 2.days).to_date
      assert_no_text 'Conditional on date AND boolean'
      find('[data-testid="option-false"]').click
      assert_text 'Conditional on date AND boolean'
      fill_in 'Conditional on date AND boolean', with: 'compare date and yes/no answers both exist'
    end

    it 'hides when local constant condition is not met, and shows when met' do
      assert_no_text 'Conditional on local constant'

      ex = e1.build_exit
      ex.exit_date = today
      ex.user = Hmis::Hud::User.from_user(hmis_user)
      ex.destination = 99
      ex.save!

      refresh
      assert_text 'Conditional on local constant'
      fill_in 'Conditional on local constant', with: 'client has an exit date'
    end

    it 'hides when answer code condition is not met, and shows when met' do
      assert_no_text 'Conditional on answer code'
      mui_select 'Rental by client, no ongoing housing subsidy', from: 'Prior Living Situation'
      assert_no_text 'Conditional on answer code'
      mui_select 'Rental by client, with ongoing housing subsidy', from: 'Prior Living Situation'
      assert_text 'Conditional on answer code'
      fill_in 'Conditional on answer code', with: 'answer code matches condition'
    end

    it 'hides when answer codes condition is not met, and shows when met' do
      assert_no_text 'Conditional on multiple answer codes'
      mui_select 'Rental by client, with ongoing housing subsidy', from: 'Prior Living Situation'
      assert_no_text 'Conditional on multiple answer codes'
      mui_select 'Safe Haven', from: 'Prior Living Situation'
      assert_text 'Conditional on multiple answer codes'
      fill_in 'Conditional on multiple answer codes', with: 'any answer code matches condition'
      mui_select 'Staying or living in a family member’s room, apartment, or house', from: 'Prior Living Situation'
      assert_text 'Conditional on multiple answer codes'
      expect(find('#conditional_answer_codes').value).to eq('any answer code matches condition')
    end

    it 'hides when answer group code condition is not met, and shows when met' do
      assert_no_text 'Conditional on answer group code'
      mui_select 'Rental by client, with ongoing housing subsidy', from: 'Prior Living Situation'
      assert_no_text 'Conditional on answer group code'
      mui_select 'Jail, prison or juvenile detention facility', from: 'Prior Living Situation'
      assert_text 'Conditional on answer group code'
      fill_in 'Conditional on answer group code', with: 'answer group code matches condition'
      mui_select 'Long-term care facility or nursing home', from: 'Prior Living Situation'
      assert_text 'Conditional on answer group code'
      expect(find('#conditional_answer_group_code').value).to eq('answer group code matches condition')
    end
  end

  describe 'autofill' do
    let!(:definition) { create :custom_assessment_with_field_rules_and_autofill, data_source: ds1 }

    it 'autofills when condition is met' do
      autofilled_field = find('#conditionally_autofilled')
      expect(autofilled_field.value).to eq('')
      find('[data-testid="option-true"]').click
      expect(autofilled_field.value).to eq('filled')
      click_button 'Submit'
      assert_text "#{c1.full_name} Assessments"
      cded = Hmis::Hud::CustomDataElementDefinition.where(key: 'conditionally_autofilled').sole
      expect(Hmis::Hud::CustomDataElement.of_type(cded).sole.value).to eq('filled')
    end

    it 'autofills a formula' do
      autofilled_field = find('#autofilled_formula')
      expect(autofilled_field.value).to eq('')
      fill_in 'Value 1', with: 10
      expect(autofilled_field.value).to eq('')
      fill_in 'Value 2', with: 2
      expect(autofilled_field.value).to eq('34')
      click_button 'Submit'
      assert_text "#{c1.full_name} Assessments"
      cded = Hmis::Hud::CustomDataElementDefinition.where(key: 'autofilled_formula').sole
      expect(Hmis::Hud::CustomDataElement.of_type(cded).sole.value).to eq(34)
    end
  end

  describe 'behavior of initial' do
    let!(:definition) { create :custom_assessment_with_initial_values, data_source: ds1 }

    it 'fills in initial value' do
      expect(find('#how_many').value).to eq('22')
      expect(find('#how_much').value).to eq('33')
      click_button 'Submit'

      cded = Hmis::Hud::CustomDataElementDefinition.where(key: 'how_many').sole
      expect(Hmis::Hud::CustomDataElement.of_type(cded).sole.value).to eq(22)

      cded = Hmis::Hud::CustomDataElementDefinition.where(key: 'how_much').sole
      expect(Hmis::Hud::CustomDataElement.of_type(cded).sole.value).to eq(33)
    end

    it 'behaves correctly with overwrite and initial' do
      fill_in 'How many?', with: 44
      fill_in 'How much?', with: 55
      click_button 'Submit'

      # it saved the overwritten values
      cded = Hmis::Hud::CustomDataElementDefinition.where(key: 'how_many').sole
      expect(Hmis::Hud::CustomDataElement.of_type(cded).sole.value).to eq(44)

      cded = Hmis::Hud::CustomDataElementDefinition.where(key: 'how_much').sole
      expect(Hmis::Hud::CustomDataElement.of_type(cded).sole.value).to eq(55)

      click_link 'Initial Values Assessment'
      find('[data-testid="unlockAssessmentButton"]').trigger(:click)

      expect(find('#how_many').value).to eq('22') # this one overwrites
      expect(find('#how_much').value).to eq('55') # this one only fills in the initial value if empty
    end

    it 'fills initial local constants correctly' do
      expect(Date.strptime(find('#date_with_initial_value').value, '%m/%d/%Y')).to eq(today)
      mui_date_select 'Date with initial value', date: (today - 2.days).to_date
      click_button 'Submit'
      cded = Hmis::Hud::CustomDataElementDefinition.where(key: 'date_with_initial_value').sole
      expect(Hmis::Hud::CustomDataElement.of_type(cded).sole.value).to eq(today - 2.days)
    end
  end
end
