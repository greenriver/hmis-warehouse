###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module AuthMethod
  module_function

  def jwt?
    ENV.fetch('AUTH_METHOD', 'devise') == 'jwt'
  end

  def devise?
    !jwt?
  end
end
