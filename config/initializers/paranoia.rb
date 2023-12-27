###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# allows globally disabling the paranoia gem
if ENV['DANGEROUSLY_DISABLE_SOFT_DELETION'] == '1'
  Rails.logger.info('globally disabling paranoia')
  module PatchDisableParanoia
    extend ActiveSupport::Concern

    prepended do
      def self.acts_as_paranoid(_options = {})
        return
      end
    end
  end

  ActiveRecord::Base.prepend(PatchDisableParanoia)
end
