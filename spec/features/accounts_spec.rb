# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Accounts', type: :feature do
  let(:user) { create(:user) }

  before(:each) do
    visit new_user_session_path
  end

  feature 'Logging In' do
    scenario 'with wrong password' do
      fill_in 'Email', with: 'noreply@example.com'
      fill_in 'Password', with: 'password'
      click_button 'Sign In'
      expect(page).to have_content 'Invalid Email or password'
    end

    scenario 'with correct password' do
      fill_in 'Email', with: user.email
      fill_in 'Password', with: user.password
      click_button 'Sign In'
      expect(page).to have_content 'Sign Out'
    end

    feature 'Devise lockable' do
      scenario 'account locks after maximum failed attempts' do
        # Account should lock after a certain number of failed attempts

        Devise.maximum_attempts.times do
          fill_in 'Email', with: user.email
          fill_in 'Password', with: 'password'
          click_button 'Sign In'
        end
        fill_in 'Email', with: user.email
        fill_in 'Password', with: user.password
        click_button 'Sign In'
        expect(page).to have_content 'Your account is locked.'
      end

      scenario 'account remains locked up until the lockout time is reached' do
        # Jump forward the to just before the account should be unlocked, it should still be locked

        Devise.maximum_attempts.times do
          fill_in 'Email', with: user.email
          fill_in 'Password', with: 'password'
          click_button 'Sign In'
        end
        travel_to(Time.now + Devise.unlock_in - 1.minute) do
          fill_in 'Email', with: user.email
          fill_in 'Password', with: user.password
          click_button 'Sign In'
          expect(page).to have_content 'Your account is locked.'
        end
      end

      scenario 'account is unlocked after time passes' do
        # Jump forward the necessary amount of time and verify that the account is unlocked

        Devise.maximum_attempts.times do
          fill_in 'Email', with: user.email
          fill_in 'Password', with: 'password'
          click_button 'Sign In'
        end
        travel_to(Time.now + Devise.unlock_in) do
          fill_in 'Email', with: user.email
          fill_in 'Password', with: user.password
          click_button 'Sign In'
          expect(page).to have_content 'Sign Out'
        end
      end
    end

    feature 'Devise expireable password' do
      scenario 'after expiring password with password expiration disabled' do
        Rails.configuration.devise.expire_password_after = false
        user.force_password_reset!
        fill_in 'Email', with: user.email
        fill_in 'Password', with: user.password
        click_button 'Sign In'
        expect(page).to have_content 'Sign Out'
      end

      scenario 'without expiring password with password expiration enabled manual' do
        Rails.configuration.devise.expire_password_after = true
        fill_in 'Email', with: user.email
        fill_in 'Password', with: user.password
        click_button 'Sign In'
        expect(page).to have_content 'Sign Out'
      end

      scenario 'after expiring password with password expiration enabled manual' do
        Rails.configuration.devise.expire_password_after = true
        user.force_password_reset!
        fill_in 'Email', with: user.email
        fill_in 'Password', with: user.password
        click_button 'Sign In'
        expect(page).to have_content 'Password Expired'
      end

      scenario 'without expiring password with password expiration enabled time-based' do
        Rails.configuration.devise.expire_password_after = 1.weeks
        fill_in 'Email', with: user.email
        fill_in 'Password', with: user.password
        click_button 'Sign In'
        expect(page).to have_content 'Sign Out'
      end

      scenario 'time-expiring password with password expiration enabled time-based' do
        Rails.configuration.devise.expire_password_after = 1.weeks
        fill_in 'Email', with: user.email
        fill_in 'Password', with: user.password
        travel_to Time.current + 2.weeks do
          click_button 'Sign In'
          expect(page).to have_content 'Password Expired'
        end
      end

      scenario 'after expiring password with password expiration enabled time-based' do
        Rails.configuration.devise.expire_password_after = 1.weeks
        user.force_password_reset!
        fill_in 'Email', with: user.email
        fill_in 'Password', with: user.password
        click_button 'Sign In'
        expect(page).to have_content 'Password Expired'
      end
    end
  end
end
