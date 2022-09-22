###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class BaseObject < GraphQL::Schema::Object
    edge_type_class(Types::BaseEdge)
    connection_type_class(Types::BaseConnection)
    field_class Types::BaseField

    def current_user
      context[:current_user]
    end

    def self.page_type
      @page_type ||= BasePaginated.create(self)
    end

    def self.yes_no_missing_field(name, description = nil, **kwargs)
      field name, Boolean, description, **kwargs
    end

    def resolve_yes_no_missing(value, yes_value: 1, no_value: 0, null_value: 99)
      case value
      when yes_value
        true
      when no_value
        false
      when null_value
        nil
      end
    end

    def load_ar_association(object, association, scope: nil)
      dataloader.with(Sources::ActiveRecordAssociation, association, scope).load(object)
    end
  end
end
