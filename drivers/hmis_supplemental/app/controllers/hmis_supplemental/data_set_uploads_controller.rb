###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Admin data sets
module HmisSupplemental
  class DataSetUploadsController < ApplicationController
    before_action :require_can_edit_users!

    def new
      @data_set = load_data_set
    end

    def create
      @data_set = load_data_set
      uploaded_file = params[:upload]

      if uploaded_file.present?
        content = uploaded_file.read
        HmisSupplemental::ImportJob.new.perform(
          data_set_id: @data_set.id,
          csv_string: content,
        )
        flash[:notice] = 'CSV imported'
      end
      render :new
    end

    protected

    def load_data_set
      data_set_scope.find(params[:data_set_id])
    end

    def data_set_scope
      HmisSupplemental::DataSet.order(:id)
    end
  end
end
