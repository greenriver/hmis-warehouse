###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class BaseEnum < GraphQL::Schema::Enum
    def self.to_enum_key(value)
      value.to_s.underscore.upcase.gsub(/\W+/, '_')
    end
  end
end
