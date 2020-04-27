###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HMIS::Structure::Base
  extend ActiveSupport::Concern

  module ClassMethods
    def hmis_table_create!(version: nil)
      return if connection.table_exists?(table_name)

      connection.create_table table_name do |t|
        hmis_structure(version: version).each do |column, options|
          t.send(options[:type], column, options.except(:type))
        end
      end
    end

    def hmis_table_create_indices!(version: nil)
      hmis_indices(version: version).each do |columns, options|
        # enforce a short index name
        cols = columns.map { |c| "#{c[0..5]&.downcase}#{c[-4..-1]&.downcase}" }
        name = ([table_name] + cols).join('_')
        next if connection.index_exists?(table_name, columns, name: name)

        options ||= {}
        options = { name: name }.merge(options)
        connection.add_index table_name, columns, options
      end
    end
  end
end
