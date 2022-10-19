module Types::Concerns::HmisTypeUtil
  extend ActiveSupport::Concern

  TYPE_MAP = {
    string: String,
    integer: Integer,
    datetime: GraphQL::Types::ISO8601DateTime,
    date: GraphQL::Types::ISO8601Date,
  }.freeze

  class_methods do
    def hmis_type_map
      {
        string: String,
        integer: Integer,
        datetime: GraphQL::Types::ISO8601DateTime,
        date: GraphQL::Types::ISO8601Date,
      }.freeze
    end
  end
end
