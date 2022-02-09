###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
      @contact = contact_source.new(contact_params)
      @contact.entity_id = @entity.id
      begin
        @contact.save!(contact_params)
      rescue Exception => e
        @error = e
        flash[:error] = e
        render action: :new
        return
      end
      respond_to do |format|
        format.html do
          if @error.present?
            flash[:error] = e
            render action: :new
            return
          end
          redirect_to action: :index
        end
        format.js do
        end
      end
    end

    def update
      @contact.assign_attributes(contact_params)
      begin
        @contact.save!
      rescue Exception => e
        flash[:error] = e
        @contact.validate
        render action: :edit
        return
      end
      redirect_to action: :index
    end

    def destroy
      begin
        @contact.destroy!
      rescue Exception => e
        @error = e
        flash[:error] = e
      end
      respond_to do |format|
        format.html do
          flash[:error] = e if @error.present?
          redirect_to action: :index
        end
        format.js do
        end
      end
    end

    def contact_params
      params.require(:contact).
        permit(:email, :first_name, :last_name)
    end

    def set_contact
      @contact = contact_source.where(entity_id: @entity.id).find(params[:id].to_i)
    end
  end
end
