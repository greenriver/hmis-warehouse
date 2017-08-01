require 'rails_helper'

RSpec.feature "Accounts", type: :feature do

  let(:user) { create(:user) }

  before(:each) do
    visit root_path
  end

  feature 'Accessing My Account' do
    scenario "with wrong password" do
      click_link 'Sign In'
      fill_in 'Email', with: 'noreply@example.com'
      fill_in 'Password', with: 'password'
      click_button 'Log in'
      expect( page ).to have_content 'Invalid email or password'
    end
  end

end
