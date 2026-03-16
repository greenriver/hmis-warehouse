# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  let!(:hmis_data_source) { create(:hmis_primary_data_source) }
  let!(:non_hmis_data_source) { create(:source_data_source) }

  let(:old_email) { 'old@example.com' }
  let(:old_first_name) { 'John' }
  let(:old_last_name) { 'Doe' }

  let!(:user) { create(:user, email: old_email, first_name: old_first_name, last_name: old_last_name) }
  let!(:hmis_hud_user) { create(:hmis_hud_user, user_email: old_email, user_first_name: old_first_name, user_last_name: old_last_name, data_source: hmis_data_source, date_updated: 2.weeks.ago) }
  let!(:other_hud_user) { create(:hud_user, user_email: old_email, user_first_name: old_first_name, user_last_name: old_last_name, data_source: non_hmis_data_source) }

  let(:new_email) { 'new@example.com' }
  let(:new_first_name) { 'Jane' }
  let(:new_last_name) { 'Smith' }

  it 'updates user names' do
    expect do
      user.first_name = new_first_name
      user.last_name = new_last_name
      user.save!
      hmis_hud_user.reload
      other_hud_user.reload
    end.to change(hmis_hud_user, :user_first_name).to(new_first_name).
      and change(hmis_hud_user, :user_last_name).to(new_last_name).
      and not_change(hmis_hud_user, :user_email).from(old_email). # Email was not changed
      and not_change(other_hud_user, :user_first_name). # Does not change non-HMIS HUD user record
      and not_change(other_hud_user, :user_last_name).
      and not_change(other_hud_user, :user_email)
  end

  it 'updates user emails' do
    expect do
      user.email = new_email
      user.save!
      user.confirm
      hmis_hud_user.reload
      other_hud_user.reload
    end.to change(hmis_hud_user, :user_email).to(new_email).
      and not_change(hmis_hud_user, :user_first_name).
      and not_change(other_hud_user, :user_email) # Does not change non-HMIS HUD user record
  end

  it 'updates both name and email' do
    expect do
      user.email = new_email
      user.first_name = new_first_name
      user.last_name = new_last_name
      user.save!
      user.confirm
      hmis_hud_user.reload
      other_hud_user.reload
    end.to change(hmis_hud_user, :user_email).to(new_email).
      and change(hmis_hud_user, :user_first_name).to(new_first_name).
      and change(hmis_hud_user, :user_last_name).to(new_last_name).
      and not_change(other_hud_user, :user_email)
  end
end
