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

    # @param permission [String]  can_administer_hmis
    def self.can(permission, field_name: nil, **field_attrs)
      field_name ||= "can_#{permission}"

      field field_name, Boolean, null: false, **field_attrs

      define_method(field_name) do
        return false unless current_user&.present?

        loader = current_user.entity_access_loader(object)
        if loader.is_a?(Symbol)
          # loader is an alias
          loader = current_user.entity_access_loader(load_ar_association(object, loader))
        end
        raise "missing loader for #{object.class}" unless loader

        dataloader.with(Sources::UserEntityAccessSource, current_user, loader).load([object, :"can_#{permission}"])
      end
    end
  end
end
