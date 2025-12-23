###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class BaseUnion < GraphQL::Schema::Union
    edge_type_class(Types::BaseEdge)
    connection_type_class(Types::BaseConnection)
  end
end
