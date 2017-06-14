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
    end
    
    def edit

    end

    def create
      @contact = contact_source.new(contact_params)
      @contact.entity_id = @entity.id
      begin
        @contact.save!(contact_params)
      rescue Exception => e
        flash[:error] = e
        render action: :new
        return
      end
      redirect_to action: :index
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
        flash[:error] = e
      end
      redirect_to action: :index
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