###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# app/graphql/types/json_object.rb
class Types::Base64 < Types::BaseScalar
  description 'A base64 encoded string'

  def self.coerce_input(input_value, _context)
    # Comes as a string, so just pass it
    input_value
  end

  def self.coerce_result(ruby_value, _context)
    # Just a string, so just pass it
    ruby_value
  end
end
