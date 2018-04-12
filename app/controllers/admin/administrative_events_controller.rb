class Admin::AdministrativeEventsController < ApplicationController
  before_action :require_can_add_administrative_event!
  
  def index
    @events = administrative_event_source.all
  end

  def create
    @event = administrative_event_source.create(administrative_event_params.merge({
      user_id: current_user.id,
      date: Date.today.to_s,
    }))

    if @event.save
      redirect_to admin_administrative_events_path
    else
      render :new
    end
    
  end
  
  def new
    @event = administrative_event_source.new 
  end

  def destroy
    @event = administrative_event_source.find params[:id]
    @event.destroy
    redirect_to({action: :index}, notice: 'Administrative event deleted')
  end
  
  def administrative_event_source 
    GrdaWarehouse::AdministrativeEvent
  end
  
  private
    def administrative_event_params
      params.require(:grda_warehouse_administrative_event).permit(
        :title, 
        :description,
      )
    end
  
end
