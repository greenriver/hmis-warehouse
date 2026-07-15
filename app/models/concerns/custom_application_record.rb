###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module CustomApplicationRecord
  extend ActiveSupport::Concern

  included do
    include Efind
    include ArelHelper
    # NOTE: filter_attributes is set once on ActiveRecord::Base in
    # config/initializers/filter_parameter_logging.rb (not per-model here) to avoid
    # Rails 8.1's filter_attributes= repeatedly appending to config.filter_parameters.
  end

  class_methods do
    def find_safely(tainted_id)
      safe_id = begin
        Integer(tainted_id)
      rescue ArgumentError, TypeError
        nil
      end
      raise(ActiveRecord::RecordNotFound, "#{sti_name} Record not found for ID: #{tainted_id}") unless safe_id

      find(safe_id)
    end

    def replace_scope(name, body, &block)
      singleton_class.undef_method name
      scope name, body, &block
    end

    def vacuum_table(full_with_lock: false)
      opts = 'FULL' if full_with_lock
      connection.exec_query("VACUUM #{opts} #{connection.quote_table_name(table_name)}")
    end

    # helper for rails db setup scripts
    def load_db_if_empty(&block)
      if connection.table_exists?(:schema_migrations)
        puts "Refusing to load the #{connection.current_database} database since there are tables present. This is not an error."
        return
      end

      # disconnect the connection pool as we are about to drop the database
      connection_pool.disconnect!
      block.call
    end
  end
end
