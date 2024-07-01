###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class BaseObject < GraphQL::Schema::Object
    include GraphqlApplicationHelper

    class_attribute :should_skip_activity_log, default: false
    def self.skip_activity_log
      self.should_skip_activity_log = true
    end

    edge_type_class(Types::BaseEdge)
    connection_type_class(Types::BaseConnection)
    field_class Types::BaseField

    def self.page_type
      @page_type ||= BasePaginated.build(self)
    end

    def self.array_page_type
      # Making this a separate attribute from page_type, as opposed to just detecting a scope vs. an array,
      # helps ensure that we won't accidentally cause slowness by resolving an array when we should use a scope.
      @array_page_type ||= ArrayPaginated.build(self)
    end

    def self.filter_options_type(name = nil, omit: [])
      raise 'Name must be supplied for filter options type if filter options are omitted' if name.nil? && omit.present?

      @filter_options = {} unless @filter_options.present?
      @filter_options[name] ||= BaseFilterOptions.build(self, name: name, omit: omit, &@available_filter_options_block)
    end

    def self.available_filter_options(&block)
      @available_filter_options_block = block
    end

    def self.audit_event_type(**args)
      @audit_event_type ||= BaseAuditEvent.build(self, **args)
    end

    def load_last_user_from_versions(object)
      refinement = GrdaWarehouse.paper_trail_versions.
        where.not(whodunnit: nil). # note, filter is okay here since it is constant with respect to object
        order(:created_at, :id).
        select(:id, :whodunnit, :item_id, :item_type, :user_id, :true_user_id) # select only fields we need for performance
      versions = load_ar_association(object, :versions, scope: refinement)
      latest_version = versions.last # db-ordered so we choose the last record
      return unless latest_version

      last_user_id = latest_version.clean_true_user_id || latest_version.clean_user_id
      return unless last_user_id

      load_ar_scope(scope: Hmis::User.with_deleted, id: last_user_id)
    end

    # Infers type and nullability from warehouse configuration
    def self.hud_field(name, type = nil, **kwargs)
      return field name, type, **kwargs unless configuration.present?

      config = configuration.transform_keys { |k| k.to_s.underscore }[name.to_s]

      if config.present? && !type.present?
        type = hud_to_gql_type_map[config[:type]]
        type = Float if config[:type] == :string && config[:check] == :money
      end

      raise "No type for #{name}" unless type.present?

      nullable = kwargs[:null].nil? && config.present? ? config[:null] : kwargs[:null]
      args = kwargs.except(:null)
      field name, type, null: nullable, **args
    end

    def self.configuration
      nil
    end

    def self.access_field(name = :access, class_name: nil, **field_attrs, &block)
      field(name, BaseAccess.build(self, class_name: class_name, &block), null: false, **field_attrs)

      define_method(name) do
        object
      end
    end

    def self.hud_to_gql_type_map
      {
        string: String,
        integer: Integer,
        datetime: GraphQL::Types::ISO8601DateTime,
        date: GraphQL::Types::ISO8601Date,
      }.freeze
    end

    # How should we log this field access? Return nil to skip. Override as needed
    # @param [String] field_name
    # @return [String, nil]
    def activity_log_field_name(_field_name)
      nil
    end

    # identify the current object
    def activity_log_object_identity
      return if self.class.should_skip_activity_log

      case object
      when ActiveRecord::Base, OpenStruct
        object.persisted? ? object.id : nil
      when Hash
        # relay mutations make a mess of things. Skip hash objects that appear to be "payload" generated types
        return nil if object.key?(:client_mutation_id)

        raise "Missing #{self.class.graphql_name}::object[:id] in #{object.inspect}" unless object.key?(:id)

        object.fetch[:id]
      end
    end
  end
end
