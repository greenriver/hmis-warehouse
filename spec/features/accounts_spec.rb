require 'rails_helper'

RSpec.feature "Accounts", type: :feature do

  let(:user) { create(:user) }

  before(:each) do
    visit root_path
  end

  feature 'Logging In' do
    scenario "with wrong password" do
      click_link 'Sign In'
      fill_in 'Email', with: 'noreply@example.com'
      fill_in 'Password', with: 'password'
      click_button 'Log in'
      expect( page ).to have_content 'Invalid email or password'
    end

    scenario "with correct password" do
      click_link 'Sign In'
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'abcd1234'
      click_button 'Log in'
      expect( page ).to have_content 'You have successfully signed in.'
    end
    
    scenario "Devise lockable" do
      #Account should lock after a certain number of failed attemps
      click_link 'Sign In'
      Devise.maximum_attempts.times do
        fill_in 'Email', with: user.email
        fill_in 'Password', with: 'password'
        click_button 'Log in'
      end    
      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'abcd1234'
      click_button 'Log in'
      expect( page ).to have_content  'Your account is locked.'
      
      #Jump forward the necessary amount of time and verify that the account is unlocked
      Timecop.travel(Time.now + Devise.unlock_in) do 
        fill_in 'Email', with: user.email
        fill_in 'Password', with: 'abcd1234'
        click_button 'Log in'
        expect( page ).to have_content  'You have successfully signed in.'
      end
    end
  end

end
