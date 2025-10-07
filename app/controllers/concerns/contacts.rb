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
      @contact = contact_source.new(contact_params.merge(entity_id: @entity.id))
      @contact.save
      respond_with(@contact, location: contacts_location)
    end

    def update
      @contact.assign_attributes(contact_params)
      @contact.save
      respond_with(@contact, location: contacts_location)
    end

    def destroy
      @contact.destroy
      respond_with(@contact, location: contacts_location)
    end

    def contact_params
      params.require(:contact).
        permit(:user_id)
    end

    def set_contact
      @contact = contact_source.where(entity_id: @entity.id).find(params[:id].to_i)
    end

    def contacts_location
      polymorphic_path([contact_path_base, :contacts])
    end
  end
end
