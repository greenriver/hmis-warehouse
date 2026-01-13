###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Basic Authentication Flow', type: :rails_system do
  include_context 'RailsSystemHelper'

  let(:user) { create(:user, first_name: 'Test', last_name: 'User') }

  before(:all) do
    puts "Using Capybara driver: #{Capybara.default_driver}"
    puts "Rails environment: #{Rails.env}"
    puts "Assets compile: #{Rails.application.config.assets.compile}"
    puts "Assets check precompiled: #{Rails.application.config.assets.check_precompiled_asset}"
    puts 'Looking for esbuild assets in:'
    puts "  - app/assets/builds/: #{Dir.glob('app/assets/builds/application_esbuild.*')}"
    puts "  - public/assets/: #{Dir.glob('public/assets/application_esbuild*')}"
  end

  describe 'User sign in process' do
    it 'allows user to sign in with valid credentials' do
      visit root_path

      # Should redirect to sign in page if not authenticated
      expect(page).to have_content('Sign In')

      # Fill in credentials
      fill_in 'Email', with: user.email
      fill_in 'Password', with: RAILS_SYSTEM_DEFAULT_PASSWORD
      click_button 'Sign In'

      # Should see a link to open the account menu
      expect(page).to have_content('Account')
      page.click_link('Account')
      # Should be signed in and see user's name
      expect(page).to have_content(user.first_name)
      expect(current_path).not_to eq(path_for_sign_in)
    end

    it 'shows error with invalid credentials' do
      visit path_for_sign_in

      fill_in 'Email', with: user.email
      fill_in 'Password', with: 'wrongpassword'
      click_button 'Sign In'

      # Should see error message and stay on sign in page
      expect(page).to have_content('Invalid')
      expect(current_path).to eq(path_for_sign_in)
    end
  end

  describe 'Navigation after sign in' do
    it 'shows user is authenticated' do
      result = sign_in_user(user)
      expect(result).to be_truthy
    end

    it 'allows user to visit root page' do
      sign_in_user(user)
      visit root_path
      expect(page).not_to have_content('Sign In')
    end
  end

  describe 'Sign out process' do
    it 'allows user to sign out' do
      sign_in_user(user)
      sign_out_user

      # Should be redirected to sign in page
      expect(page).to have_content('Sign In')
    end
  end
end
