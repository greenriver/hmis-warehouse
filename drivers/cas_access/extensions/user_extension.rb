###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CasAccess
  module UserExtension
    extend ActiveSupport::Concern

    included do
      # a CAS user that matches exactly by email
      def cas_user
        @cas_user ||= CasAccess::User.find_by(email: email)
      end
    end
  end
end
