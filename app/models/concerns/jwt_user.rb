###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module JwtUser
  extend ActiveSupport::Concern

  class_methods do
    def find_or_create_from_jwt(jwt_helper)
      allow_create = AppConfigProperty.find_by(key: 'idp/auto_create_user')&.value == 'true'
      Idp::UserProvisioner.call(jwt_helper: jwt_helper, user_class: self, allow_create: allow_create, learn: true)
    end

    def find_from_jwt(jwt_helper)
      Idp::UserProvisioner.call(jwt_helper: jwt_helper, user_class: self, allow_create: false, learn: false)
    end
  end
end
