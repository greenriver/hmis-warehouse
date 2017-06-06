
class ProjectContactsController < ApplicationController
  before_action :require_can_view_projects!
  before_action :set_project
  before_action :set_project_contact, only: [:show, :edit, :update, :destroy]
  
  def index
    @contacts = @project.project_contacts
  end

  def new
    @contact = project_contact_source.new
  end

  def edit

  end

  def create
    @contact = project_contact_source.new(project_contact_params)
    @contact.project = @project
    begin
      @contact.save!(project_contact_params)
    rescue Exception => e
      flash[:error] = e
      render action: :new
      return
    end
    redirect_to action: :index
  end

  def update
    @contact.assign_attributes(project_contact_params)
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


  def project_contact_source
    GrdaWarehouse::WarehouseReports::ProjectContact
  end

  def project_source
    GrdaWarehouse::Hud::Project
  end

  def set_project
    @project = project_source.find(params[:project_id].to_i)
  end

  def set_project_contact
    @contact = project_contact_source.find(params[:id].to_i)
  end

  def project_contact_params
    params.require(:grda_warehouse_warehouse_reports_project_contact).
      permit(:email, :first_name, :last_name)
  end
end