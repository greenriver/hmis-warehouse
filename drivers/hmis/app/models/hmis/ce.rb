###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Ce
  def self.table_name_prefix
    'ce_'
  end

  def self.configuration
    # don't memoize this as we're in a class context here
    Hmis::Ce::Configuration.new
  end
end
