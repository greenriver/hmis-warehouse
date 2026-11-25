###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Required training in sandbox mode', type: :request do
  let!(:role) { create(:admin_role, training_required: true) }
  let(:user) { create(:user) }
  let(:lms) { instance_double(Talentlms::Facade, any_training_required?: true) }

  before do
    user.legacy_roles << role
    allow(Talentlms::Facade).to receive(:new).and_return(lms)
    sign_in user
  end

  it 'redirects a user with required training outside sandbox mode' do
    get root_path

    expect(response).to redirect_to(user_training_path)
  end

  it 'does not consult TalentLMS or redirect to training in sandbox mode' do
    with_sandbox_mode do
      get root_path
      follow_redirect!
    end

    expect(Talentlms::Facade).not_to have_received(:new)
    expect(request.path).not_to eq(user_training_path)
    expect(response).to have_http_status(:ok)
  end

  it 'redirects /user_training away without consulting TalentLMS in sandbox mode' do
    with_sandbox_mode do
      get user_training_path
    end

    expect(response).to have_http_status(:redirect)
    expect(response.location).not_to end_with(user_training_path)
    expect(Talentlms::Facade).not_to have_received(:new)
  end

  it 'consults TalentLMS for /user_training outside sandbox mode' do
    get user_training_path

    expect(Talentlms::Facade).to have_received(:new).with(user)
  end
end
