###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# app/graphql/types/json_object.rb
class Types::JsonObject < Types::BaseScalar
  description 'Arbitrary JSON Type'

  def self.coerce_input(input_value, _context)
    # Comes as JSON, so just pass it
    input_value
  end

  def self.coerce_result(ruby_value, _context)
    # Just JSON, so just pass it
    ruby_value
  end
end
