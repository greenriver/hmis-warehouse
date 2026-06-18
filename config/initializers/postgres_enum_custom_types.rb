###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Rails.logger.debug "Running initializer in #{__FILE__}"

module ActiveRecord
  module ConnectionAdapters
    if const_defined?(:PostgreSQLAdapter)
      class PostgreSQLAdapter
        NATIVE_DATABASE_TYPES.merge!(
          record_type:  { name: 'character varying' },
        )
      end
    end
  end
end
