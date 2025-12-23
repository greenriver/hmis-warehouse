###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  class CollectionsController < ApplicationController
    include AjaxModalRails::Controller
    before_action :require_can_edit_collections!
    before_action :set_collection, only: [:show, :edit, :update, :destroy, :entities, :bulk_entities]
    before_action :set_entities, only: [:new, :edit, :create, :update, :entities]

    def index
      @collections = collection_scope.without_source_entity.order(:name)
      @collections = @collections.text_search(params[:q]) if params[:q].present?
      @pagy, @collections = pagy(@collections)
    end

    def show
    end

    def new
      @collection = collection_scope.new
    end

    def create
      @collection = collection_scope.new
      @collection.update(collection_params)
      @collection.set_viewables(viewable_params)
      if @collection.persisted?
        respond_with(@collection, location: admin_collection_path(@collection))
      else
        respond_with(@collection, location: admin_collections_path)
      end
    end

    def edit
    end

    def update
      @collection.update(collection_params)
      # Only update viewbles on legacy collections
      @collection.set_viewables(viewable_params) if @collection.legacy?
      @collection.save

      redirect_to({ action: :show }, notice: "Collection #{@collection.name} updated.")
    end

    def destroy
      @collection.destroy
      redirect_to({ action: :index }, notice: "Collection #{@collection.name} removed.")
    end

    def entities
      @modal_size = :lg
      entity_key = params[:entities]&.to_sym
      config = Admin::Collections::CONFIG[entity_key]
      raise ArgumentError, "Unknown entity type: #{entity_key.inspect}" unless config

      @entities = build_entity_config(config)
    end

    def bulk_entities
      ids = {}
      @collection.entity_types.keys.each do |entity_type|
        values = bulk_entities_params.to_h.with_indifferent_access[entity_type]
        ids[entity_type] ||= []
        # Prevent unsetting other entity types
        if entity_type.to_s == params[:entities]
          values.each do |id, checked|
            id = id.to_i
            ids[entity_type] << id if checked == '1'
          end
        else
          ids[entity_type] = @collection.send(entity_type).map(&:id)
        end
      end

      @collection.set_viewables(ids.with_indifferent_access)

      redirect_to({ action: :show }, notice: "Collection #{@collection.name} updated.")
    end

    private def collection_scope
      Collection.general
    end

    private def collection_params
      params.require(:collection).permit(
        :name,
        :description,
        :collection_type,
      )
    end

    private def viewable_params
      params.require(:collection).permit(
        data_sources: [],
        organizations: [],
        coc_codes: [],
        projects: [],
        project_access_groups: [],
        reports: [],
        cohorts: [],
        supplemental_data_sets: [],
        project_groups: [],
      )
    end

    private def bulk_entities_params
      params.require(:collection).permit(
        coc_codes: {},
        data_sources: {},
        organizations: {},
        projects: {},
        project_access_groups: {},
        reports: {},
        cohorts: {},
        supplemental_data_sets: {},
        project_groups: {},
      )
    end

    private def set_collection
      @collection = collection_scope.find(params[:id].to_i)
    end

    private def set_entities
      # Build entity configs using the configuration structure
      Admin::Collections::CONFIG.each do |key, config|
        instance_variable_set("@#{key}", build_entity_config(config))
      end

      # Legacy support for entity types not yet migrated
      @cocs = @coc_codes
    end

    private def build_entity_config(config)
      input_html_data = if config.input_html_data.is_a?(Proc)
        config.input_html_data.call
      else
        config.input_html_data || {}
      end

      {
        selected: config.selected_ids(@collection),
        collection: config.collection_for(@collection),
        placeholder: config.placeholder,
        multiple: true,
        input_html: {
          class: config.css_class,
          name: "collection[#{config.key}][]",
        }.merge(input_html_data),
      }.tap do |entity_config|
        entity_config[:as] = config.form_as if config.form_as
        entity_config[:group_method] = config.form_group_method if config.form_group_method
        entity_config[:label_method] = config.name_method if config.name_method.is_a?(Proc) && config.form_as == :grouped_select
      end
    end
  end
end
