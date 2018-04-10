class Admin::AdministrativeEventsController < ApplicationController
  before_action :require_can_add_administrative_event!
  
  def index
    @events = administrative_event_source.all
  end

  def create
  end

  def destroy
    @event = administrative_event_source.find params[:id]
    @event.destroy
    redirect_to({action: :index}, notice: 'Administrative event deleted')
  end
  
  def administrative_event_source 
    GrdaWarehouse::AdministrativeEvent
  end
  
end
