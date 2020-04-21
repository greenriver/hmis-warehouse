###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Hmis::Structure::Base
  extend ActiveSupport::Concern
  included do
    def self.as_hmis_table_create(table_name:, version: nil)
      create_table table_name do |t|
        hmis_structure(version: version).each do |_column, options|
          t.send(options[:type], options.execept(:type))
        end
      end
    end

    def self.as_create_indices(table_name:, version: nil)
      hmis_indices(version: version).map do |columns|
        # enforce a short index name
        name = columns.map { |c| c[0..7].downcase }.join('_')
        add_index table_name, columns, name: name
      end
    end
  end
end
