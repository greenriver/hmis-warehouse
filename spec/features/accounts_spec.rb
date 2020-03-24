require 'rails_helper'

RSpec.feature 'Accounts', type: :feature do
  let(:user) { create(:user) }

  before(:each) do
    visit new_user_session_path
  end

  feature 'Logging In' do
    scenario 'with wrong password' do
      fill_in 'Email', with: 'noreply@example.com'
      fill_in 'Password', with: 'password'
      click_button 'Log in'
      expect(page).to have_content 'Invalid Email or password'
    end

    scenario 'with correct password' do
      fill_in 'Email', with: user.email
      fill_in 'Password', with: user.password
      click_button 'Log in'
      expect(page).to_not have_content 'Sign In'
    end

    feature 'Devise lockable' do
      scenario 'account locks after maximum failed attempts' do
        # Account should lock after a certain number of failed attempts

        Devise.maximum_attempts.times do
          fill_in 'Email', with: user.email
          fill_in 'Password', with: 'password'
          click_button 'Log in'
        end
        fill_in 'Email', with: user.email
        fill_in 'Password', with: user.password
        click_button 'Log in'
        expect(page).to have_content 'Your account is locked.'
      end

      scenario 'account remains locked up until the lockout time is reached' do
        # Jump forward the to just before the account should be unlocked, it should still be locked

        Devise.maximum_attempts.times do
          fill_in 'Email', with: user.email
          fill_in 'Password', with: 'password'
          click_button 'Log in'
        end
        Timecop.travel(Time.now + Devise.unlock_in - 1.minute) do
          fill_in 'Email', with: user.email
          fill_in 'Password', with: user.password
          click_button 'Log in'
          expect(page).to have_content 'Your account is locked.'
        end
      end

      scenario 'account is unlocked after time passes' do
        # Jump forward the necessary amount of time and verify that the account is unlocked

        Devise.maximum_attempts.times do
          fill_in 'Email', with: user.email
          fill_in 'Password', with: 'password'
          click_button 'Log in'
        end
        Timecop.travel(Time.now + Devise.unlock_in) do
          fill_in 'Email', with: user.email
          fill_in 'Password', with: user.password
          click_button 'Log in'
          expect(page).to_not have_content 'Sign In'
        end
      end
    end
  end
end
