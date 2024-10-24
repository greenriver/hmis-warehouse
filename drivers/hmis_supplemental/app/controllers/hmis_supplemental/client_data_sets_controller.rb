###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# a "tab" on the client dashboard for viewing a data set.
# This controller is for both client and enrollment-based data sets
module HmisSupplemental
  class ClientDataSetsController < ApplicationController
    include ClientController
    include ClientPathGenerator
    include ClientDependentControllers

    before_action :require_can_view_clients!
    before_action :set_client

    def show
      @data_set = load_authorized_data_set
      @groups = []
      case @data_set.owner_type
      when 'client'
        @groups = source_clients.map do |client|
          {
            title: client.data_source.name,
            values: @data_set.field_values.for_owner(client).index_by(&:field_key),
          }
        end
      when 'enrollment'
        @groups = source_enrollments.map do |enrollment|
          {
            title: "#{enrollment.entry_date.to_fs} #{enrollment.project.name}",
            values: @data_set.field_values.for_owner(enrollment).index_by(&:field_key),
          }
        end
      end
    end

    protected

    def source_clients
      @client.source_clients.
        where(data_source_id: @data_set.data_source_id).
        source_visible_to(current_user).
        order(:id)
    end

    def source_enrollments
      @client.source_enrollments.
        visible_to(current_user).
        where(data_source_id: @data_set.data_source_id).
        order(entry_date: :desc, id: :desc).
        preload(:project)
    end

    def load_authorized_data_set
      data_set_scope.find(params[:data_set_id])
    end

    def client_groups
      # note: order is important here, source_visible_to appears to clobber the data source condition
      clients = @client.source_clients.
        source_visible_to(current_user).
        where(data_source_id: @data_set.data_source_id).
        order(:id)
      clients.map do |client|
        {
          title: client.data_source.name,
          values: @data_set.field_values.for_owner(@client).index_by(&:field_key),
        }
      end
    end

    def data_set_scope
      HmisSupplemental::DataSet.viewable_by(current_user)
    end

    def client_scope(id: nil)
      ::GrdaWarehouse::Hud::Client.destination_visible_to(current_user).where(id: id)
    end
  end
end
