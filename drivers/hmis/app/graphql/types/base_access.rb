###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class BaseAccess < BaseObject
    def self.build(node_class, class_name: nil, &block)
      Class.new(self) do
        graphql_name(class_name || "#{node_class.graphql_name}Access")
        instance_eval(&block) if block

        field :id, ID, null: false

        def id
          [object.respond_to?(:id) ? object.id : nil, current_user&.id].compact.first
        end
      end
    end

    def self.root_can(permission, **field_attrs)
      field permission, Boolean, null: false, **field_attrs
      define_method(permission) do
        current_user.send(permission) || false
      end
    end

    # @param permission [Symbol] permission name, i.e :can_administer_hmis
    # @param field_name [Symbol] graphql field name
    def self.can(permission, field_name: nil, **field_attrs)
      field_name ||= "can_#{permission}"

      field field_name, Boolean, null: false, **field_attrs

      define_method(field_name) do
        current_permission?(permission: "can_#{permission}", entity: object)
      end
    end
  end
end
