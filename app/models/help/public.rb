###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

require 'aws-sdk-dynamodb'

module Help
  class Public < ::ModelForm
    def connection
      YAML.load(ERB.new(File.read(Rails.root.join('config', 'aws_dynamo_db.yml'))).result)[Rails.env]&.with_indifferent_access
    end

    def setup
      @db = Aws::DynamoDB::Resource.new(connection)
      @db.tables.each do |t|
        puts "Name:    #{t.name}"
        puts "#Items:  #{t.item_count}"
      end

      unless @db.tables.map(&:name).include?('help')
        params = {
          table_name: 'help',
          key_schema: [
            {
              attribute_name: 'year',
              key_type: 'HASH', # Partition key
            },
            {
              attribute_name: 'title',
              key_type: 'RANGE', # Sort key
            },
          ],
          attribute_definitions: [
            {
              attribute_name: 'year',
              attribute_type: 'N',
            },
            {
              attribute_name: 'title',
              attribute_type: 'S',
            },

          ],
          provisioned_throughput: {
            read_capacity_units: 10,
            write_capacity_units: 10,
          },
        }

        begin
          result = dynamodb.create_table(params)

          puts 'Created table. Status: ' +
               result.table_description.table_status
        rescue Aws::DynamoDB::Errors::ServiceError => error
          puts 'Unable to create table:'
          puts error.message
        end
      end
    end
  end
end
