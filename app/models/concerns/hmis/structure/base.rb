###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HMIS::Structure::Base
  extend ActiveSupport::Concern

  module ClassMethods
    def hmis_table_create!(version: nil, constraints: true, types: true)
      return if connection.table_exists?(table_name)

      connection.create_table table_name do |t|
        hmis_structure(version: version).each do |column, options|
          type = if types
            options[:type]
          else
            :string
          end
          if constraints
            t.send(type, column, options.except(:type))
          else
            t.send(type, column)
          end
        end
      end
    end

    def hmis_table_create_indices!(version: nil)
      hmis_indices(version: version).each do |columns, _|
        # enforce a short index name
        # cols = columns.map { |c| "#{c[0..5]&.downcase}#{c[-4..]&.downcase}" }
        # name = ([table_name[0..4]+table_name[-4..]] + cols).join('_')
        name = table_name + '-' + SecureRandom.alphanumeric(4)
        next if connection.index_exists?(table_name, columns, name: name)

        connection.add_index table_name, columns, name: name
      end
    end
  end
end
