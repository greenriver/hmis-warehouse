###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class BaseAccess < BaseObject
    def self.create(node_class, class_name: nil, &block)
      Class.new(self) do
        graphql_name(class_name || "#{node_class.graphql_name}Access")
        instance_eval(&block) if block

        field :id, ID, null: false

        def id
          [object.respond_to?(:id) ? object.id : nil, current_user&.id].compact.join(':')
        end
      end
    end

    def self.can(permission, field_name: nil, method_name: nil, root: false, **field_attrs)
      field_name ||= "can_#{permission}"

      field field_name, Boolean, null: false, **field_attrs

      define_method(field_name) do
        return false unless current_user&.present?

        method_name ||= root ? "can_#{permission}?" : "can_#{permission}_for?"
        return false unless current_user.respond_to?(method_name)
        return current_user.send(method_name) if root

        current_user.send(method_name, object)
      end
    end
  end
end
