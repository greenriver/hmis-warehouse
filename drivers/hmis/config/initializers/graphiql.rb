###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

if Rails.env.development?
  Rails.configuration.to_prepare do
    # For GraphiQL, sign the current user in as an HMIS user
    GraphiQL::Rails::EditorsController.class_eval do
      before_action do
        sign_in(:hmis_user, current_user)
      end
    end
  end
end
