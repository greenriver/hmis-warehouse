###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeviseOktaSupport, :devise_only, type: :model do
  describe '.find_or_build_for_oauth' do
    let!(:user) { create(:user) }

    # Guards Devise's case_insensitive_keys, which find_for_authentication relies on now that
    # DeviseUser no longer overrides it to downcase the email.
    it 'finds the existing user when the email has different case' do
      found = User.find_or_build_for_oauth(email: user.email.upcase)

      expect(found).to eq(user)
    end
  end
end
