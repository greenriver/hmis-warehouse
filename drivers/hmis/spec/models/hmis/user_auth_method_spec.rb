###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::User, type: :model do
  it_behaves_like 'an auth-method-aware user', :hmis_user, Hmis::User
end
