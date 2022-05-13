###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Admin::AdministrativeEventsController < ApplicationController
  before_action :require_can_add_administrative_event!
  before_action :load_event, only: [:edit, :update, :destroy]

  def index
    @events = administrative_event_source.order(date: :desc)
    @pagy, @events = pagy(@events)
  end

  def create
    @event = administrative_event_source.create(
      administrative_event_params.merge(
        user_id: current_user.id,
      ),
    )
    respond_with(@event, location: admin_administrative_events_path)
  end

  def new
    @event = administrative_event_source.new
  end

  def edit
  end

  def update
    @event.update(administrative_event_params)
    respond_with(@event, location: admin_administrative_events_path)
  end

  def destroy
    @event.destroy
    respond_with(@event, location: admin_administrative_events_path)
  end

  def administrative_event_source
    GrdaWarehouse::AdministrativeEvent
  end

  def flash_interpolation_options
    { resource_name: 'Event' }
  end

  private

  def administrative_event_params
    params.require(:grda_warehouse_administrative_event).permit(
      :title,
      :description,
      :date,
    )
  end

  def load_event
    @event = administrative_event_source.find params[:id].to_i
  end
end
