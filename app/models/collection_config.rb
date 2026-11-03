###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Configuration for collection entity types
# Defines how each entity type (data sources, organizations, projects, etc.)
# is displayed and managed in collections
#
# Required fields: :key, :title, :source_class, :name_method, :collection_scope,
#                  :placeholder, :css_class, :partial_name
# Optional fields: :name_column, :extra_columns, :grouped, :array_format,
#                  :form_as, :form_group_method, :input_html_data
CollectionConfig = Struct.new(
  # Symbol - The entity type key (e.g., :data_sources, :organizations)
  # Used to reference collections and build form field names
  :key,

  # String - Display title for the entity type (e.g., "Data Sources", "Organizations")
  :title,

  # String - Fully-qualified class name of the source model (e.g., 'GrdaWarehouse::DataSource')
  :source_class,

  # Symbol or Proc - Method name or lambda to get the entity's display name
  # Symbol example: :name
  # Proc example: ->(org) { org.name(ignore_confidential_status: true) }
  :name_method,

  # Proc - Lambda that returns the collection of all available entities
  # Should return an ActiveRecord::Relation, Array, or Hash (for grouped collections)
  # Example: -> { GrdaWarehouse::DataSource.source.order(:name) }
  :collection_scope,

  # String - Placeholder text for form select inputs (e.g., "Data Source", "Organization")
  :placeholder,

  # String - CSS class names for the form input (e.g., 'jUserViewable jDataSources')
  :css_class,

  # String - Name of the partial template file (e.g., 'data_sources', 'organizations')
  # Resolves to app/views/admin/collections/entities/_<partial_name>.haml
  :partial_name,

  # String (optional) - Header text for the name column in entity tables
  # Defaults to 'Name' if not specified
  :name_column,

  # Array<Hash> (optional) - Additional columns to display in entity tables
  # Each hash should have :header (String) and :content (Proc) keys
  # :content is called with the entity plus the keywords group_name: (nil unless :grouped)
  # and preloaded: (the result of the column's optional :preload Proc, which runs once per
  # page so per-row values can be looked up instead of queried). Accept unused keywords with **.
  # Example: [{ header: 'Project Count', content: ->(entity, **) { entity.projects.count } }]
  # Example: [{ header: 'Count', preload: -> { Project.group(:OrganizationID).count },
  #             content: ->(entity, preloaded:, **) { preloaded[entity.OrganizationID] } }]
  :extra_columns,

  # Boolean (optional) - Whether the collection is grouped (e.g., projects grouped by organization)
  # When true, collection_scope should return a Hash with group names as keys
  :grouped,

  # Boolean (optional) - Whether the collection is in [name, id] array format
  # Used for collections that return simple [label, value] pairs instead of ActiveRecord objects
  :array_format,

  # Symbol (optional) - Form input type for SimpleForm (e.g., :grouped_select)
  # Specify for grouped collections to enable grouped select dropdowns in forms
  :form_as,

  # Symbol (optional) - Method to call on grouped collections to get array of entities
  # Typically :last when collection_scope returns { group_name => [entities] } hashes
  :form_group_method,

  # Hash or Proc (optional) - Additional data attributes to merge into input_html
  # Proc example: -> { { data: { unlimitable: [1, 2, 3].to_json } } }
  # Hash example: { data: { target: 'some-value' } }
  :input_html_data,
  keyword_init: true,
) do
  def collection_for(_collection = nil)
    collection_scope.call
  end

  def selected_ids(collection)
    collection&.public_send(key)&.map(&:id) || []
  end

  def entity_name(entity)
    if name_method.is_a?(Proc)
      name_method.call(entity)
    else
      entity.public_send(name_method)
    end
  end

  def name_column_header
    name_column || 'Name'
  end

  def extra_columns_config
    extra_columns || []
  end

  def preload_extra_columns
    extra_columns_config.map { |column| column[:preload]&.call }
  end

  def extra_column_value(column, entity, group_name:, preloaded:)
    column[:content].call(entity, group_name: group_name, preloaded: preloaded)
  end
end
