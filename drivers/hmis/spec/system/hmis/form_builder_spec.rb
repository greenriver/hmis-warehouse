require 'rails_helper'
require_relative '../../requests/hmis/login_and_permissions'
require_relative '../../support/hmis_base_setup'

# Custom matcher for asserting order of text in Capybara page body, helpful for testing reordering of form items.
# https://stackoverflow.com/questions/64002940/is-it-possible-to-find-out-if-an-element-comes-before-the-second-element-in-capy
RSpec::Matchers.define :appear_before do |later_content|
  match do |earlier_content|
    page.body.index(earlier_content) < page.body.index(later_content)
  end
end

RSpec.feature 'HMIS Form Builder', type: :system do
  include_context 'hmis base setup'

  let!(:ds1) { create(:hmis_data_source, hmis: 'localhost') }
  let!(:access_control) { create_access_control(hmis_user, p1) }
  let!(:published) { create :custom_assessment_with_custom_fields_and_rules, title: 'System Test 1', identifier: 'system_test_1', data_source: ds1 }
  let!(:draft) { create :custom_assessment_with_custom_fields_and_rules, title: 'System Test 2', identifier: 'system_test_2', status: 'draft', data_source: ds1 }
  let!(:advanced_draft) { create :custom_assessment_with_field_rules_and_autofill, identifier: 'advanced_form', status: 'draft', data_source: ds1 }

  context 'Form builder happy path' do
    before(:each) do
      sign_in(hmis_user)
      disable_transitions
      visit '/admin/forms'
    end

    it 'creates a new form with a draft' do
      visit '/admin/forms'
      click_button 'New Form'

      assert_text 'Form Type'
      mui_select 'Custom assessment', from: 'Form Type'
      fill_in 'Form Title', with: 'System Test 3'
      fill_in 'Form Identifier', with: 'system_test_3'
      click_button 'Save'

      assert_text 'SELECTED FORM System Test 3'
      assert_text 'Edit Draft'
    end

    it 'creates a new draft' do
      visit '/admin/forms/system_test_1'
      click_button 'New Draft'

      assert_text 'EDITING DRAFT System Test 1'
    end

    context 'with an existing form draft' do
      before(:each) do
        visit "/admin/forms/system_test_2/#{draft.id}/edit"
      end

      it 'edits a form item' do
        find("button[aria-label='section_1 item actions']").click
        find("li[aria-label='edit section_1']").click
        assert_text 'EDIT FORM ITEM Test Custom Assessment'

        fill_in 'Group Label', with: 'A New Section Title'
        find("button[type='submit']").trigger('click') # for some reason, .trigger('click') works but .click does not?
        assert_text 'Group: A New Section Title'
      end

      it 'adds new items' do
        find("button[aria-label='Add Group item']").click
        assert_text 'ADD NEW FORM ITEM Group Item'
        assert_no_selector "[role='submit']" # can't submit without a Label
        fill_in 'Group Label', with: 'Brand New Group'
        find("button[type='submit']").trigger('click')
        assert_text 'Group: Brand New Group'

        find("button[aria-label='Add Display item']").click
        assert_text 'ADD NEW FORM ITEM Display Item'
        fill_in 'Display Text', with: 'This is a <b>displayable item</b>.'
        find("button[type='submit']").trigger('click')
        assert_text 'Display: This is a displayable item.'

        find("button[aria-label='Add Text item']").click
        assert_text 'ADD NEW FORM ITEM Text Item'
        find("input[name='text']").fill_in(with: 'What is the answer to this question?')
        find("button[type='submit']").trigger('click')
        assert_text 'Text: What is the answer to this question?'

        find("button[aria-label='Add Paragraph item']").click
        assert_text 'ADD NEW FORM ITEM Paragraph Item'
        find("input[name='text']").fill_in(with: 'What about this long paragraph?')
        find("button[type='submit']").trigger('click')
        assert_text 'Paragraph: What about this long paragraph?'

        draft.reload
        expect(draft.definition.dig('item', 1, 'text')).to eq('Brand New Group')
        expect(draft.definition.dig('item', 2, 'text')).to eq('This is a <b>displayable item</b>.')
        expect(draft.definition.dig('item', 3, 'text')).to eq('What is the answer to this question?')
        expect(draft.definition.dig('item', 4, 'text')).to eq('What about this long paragraph?')

        # todo @martha - add more item types
      end

      it 'reorders items' do
        assert_text 'Group: Test Custom Assessment'
        find("div[aria-label='item section_1']").click
        assert_text 'Date: Assessment Date'
        assert_text 'Text: Custom question 1'
        expect('Assessment Date').to appear_before('Custom question 1')

        find("button[aria-label='custom_question_1 move up']").trigger('click')
        expect('Custom question 1').to appear_before('Assessment Date')

        find("button[type='submit']").trigger('click')

        draft.reload
        expect(draft.definition.dig('item', 0, 'item', 0, 'text')).to eq('Custom question 1')
        expect(draft.definition.dig('item', 0, 'item', 1, 'text')).to eq('Assessment Date')

        # todo @martha - add more reorders. up/down into/out of groups
      end

      it 'deletes item' do
        assert_text 'Group: Test Custom Assessment'
        find("div[aria-label='item section_1']").click
        assert_text 'Date: Assessment Date'

        find("button[aria-label='custom_question_1 item actions']").click
        find("li[aria-label='delete custom_question_1']").click
        assert_no_text 'Custom question 1'

        find("button[type='submit']").trigger('click')

        draft.reload
        expect(draft.definition.dig('item', 0, 'item').size).to eq(1)
      end

      it 'publishes form' do
        assert_text 'Group: Test Custom Assessment'
        click_button 'Preview / Publish'
        assert_text 'PREVIEWING DRAFT System Test 2'
        click_button 'Publish'
        assert_text 'Are you sure you want to publish this form?'
        click_button 'Confirm'
        assert_text 'SELECTED FORM System Test 2'
        assert_text 'Status Published'
        draft.reload
        expect(draft.status).to eq('published')
      end
    end

    context 'with a draft that has advanced features and non-admin user' do
      before(:each) do
        remove_permissions(access_control, :can_administrate_config)
        visit "/admin/forms/advanced_form/#{advanced_draft.id}/edit"
      end

      it 'does not clobber custom rule or autofill' do
        find("div[aria-label='item section_1']").click
        assert_text 'Conditionally autofilled'
        find("button[aria-label='conditionally_autofilled item actions']").click
        find("li[aria-label='edit conditionally_autofilled']").click
        assert_text 'EDIT FORM ITEM Conditionally autofilled'
        assert_no_text 'Autofill Value 1' # Autofill condition exists, but this user can't see it
        assert_no_text 'some-particular-project-id' # Custom rule involving this project ID exists, but this user can't see it

        fill_in 'Helper Text', with: 'some helpful information'
        find("button[type='submit']").trigger('click')
        assert_text 'Text: Conditionally autofilled'

        advanced_draft.reload
        item = advanced_draft.definition.dig('item', 0, 'item', 2)
        autofill = item.dig('autofill_values', 0)

        expect(autofill.dig('value_code')).to eq('filled')
        expect(autofill.dig('autofill_when', 0, 'question')).to eq('yes_or_no')

        # todo @martha - this is a bug
        expect(item.dig('custom_rule', 'value')).to eq('some-particular-project-id')
      end
    end
  end
end
