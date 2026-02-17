###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# @see docs/features/hmis-supplemental.md

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
      @groups = authorized_groups
      not_authorized! unless @groups.present?
    end

    def authorized_groups
      case @data_set.owner_type
      when 'client'
        source_clients.map do |client|
          {
            title: client.data_source.name,
            values: @data_set.field_values.for_owner(client).index_by(&:field_key),
          }
        end
      when 'enrollment'
        source_enrollments.map do |enrollment|
          {
            title: "#{enrollment.entry_date.to_fs} #{enrollment.project.name}",
            values: @data_set.field_values.for_owner(enrollment).index_by(&:field_key),
          }
        end
      end
    end

    protected

    def source_clients
      # order is important here, source_visible_to appears to clobber the data source condition
      results = @client.source_clients.
        source_visible_to(current_user).
        where(data_source_id: @data_set.data_source_id).
        order(:id)
      results.to_a.filter do |source_client|
        current_user.policy_for(source_client).can_view_supplemental_data?
      end
    end

    def source_enrollments
      results = @client.source_enrollments.
        visible_to(current_user).
        where(data_source_id: @data_set.data_source_id).
        order(entry_date: :desc, id: :desc).
        preload(:project, :client)
      results.to_a.filter do |enrollment|
        current_user.policy_for(enrollment.client).can_view_supplemental_data?
      end
    end

    def load_authorized_data_set
      data_set_scope.find(params[:data_set_id])
    end

    def data_set_scope
      HmisSupplemental::DataSet.viewable_by(current_user)
    end

    def client_scope(id: nil)
      ::GrdaWarehouse::Hud::Client.destination_visible_to(current_user).where(id: id)
    end
  end
end
