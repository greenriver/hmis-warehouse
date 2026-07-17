###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module AuthMethod
  module_function

  def jwt?
    # Temporarily force jwt for staging
    # FIXME: do not merge to the staging branch with this change
    return ENV.fetch('AUTH_METHOD', 'jwt') == 'jwt' if Rails.env.staging?

    ENV.fetch('AUTH_METHOD', 'devise') == 'jwt'
  end

  def devise?
    !jwt?
  end
end
