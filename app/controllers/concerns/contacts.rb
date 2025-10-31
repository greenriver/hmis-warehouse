###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Contacts
  extend ActiveSupport::Concern

  included do
    before_action :require_can_view_imports!
    before_action :set_entity
    before_action :set_contact, only: [:show, :edit, :update, :destroy]
    before_action :load_alert_definitions, only: [:new, :edit]

    def index
      @contacts = @entity.contacts
    end

    def new
      @contact = contact_source.new
      render layout: false if params[:layout] == 'false'
    end

    def edit
    end

    def create
      @contact = contact_source.new(
        contact_params.merge(
          entity_id: @entity.id,
          entity_type: @entity.class.name,
        ),
      )
      @contact.save
      respond_with(@contact, location: contacts_location)
    end

    def update
      @contact.update!(contact_params)
      respond_with(@contact, location: contacts_location)
    end

    def destroy
      @contact.destroy
      respond_with(@contact, location: contacts_location)
    end

    def contact_params
      params.require(:contact).
        permit(
          :user_id,
          alert_definition_ids: [],
        )
    end

    def set_contact
      @contact = contact_source.where(entity_id: @entity.id).find(params[:id].to_i)
    end

    def contacts_location
      polymorphic_path([contact_path_base, :contacts])
    end

    def load_alert_definitions
      # Load non-system alerts grouped by category for organization/project contacts
      @alert_definitions_by_category = GrdaWarehouse::AlertDefinition.
        active.
        where.not(category: 'system').
        order(:category, :name).
        group_by(&:category)
    end
  end
end
