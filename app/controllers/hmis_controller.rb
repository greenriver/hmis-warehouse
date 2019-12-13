###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class HmisController < ApplicationController
  # Permission notes: This is limited to people who can upload HMIS data
  # and further limited to the data sources someone can edit.  This means
  # the user must be granted explicit access to a data source and already
  # has access to the source data.
  before_action :require_can_upload_hud_zips!
  before_action :set_item, only: [:show]

  include ArelHelper

  def index
    if searched?
      @type = params[:search].try(:[], :type)
      @id = params[:search].try(:[], :id)
    end

    @results = load_results
  end

  def show
    @type = params[:type] if valid_class(params[:type]).present?
  end

  private def searched?
    @searched = params[:search].present?
  end
  helper_method :searched?

  private def load_results
    return [] unless @searched

    # whitelist the passed in class
    @klass = valid_class(params[:search].try(:[], :type))
    return [] unless @klass.present?
    return [] unless params[:search][:id].present?

    # can't force to_i since this might be a string
    @query = params[:search][:id]
    # long string searches against integers make postgres unhappy
    # limit the search to the HUD key if the search isn't an integer
    if @query.to_i == @query
      item_scope.where(
        @klass.arel_table[:id].eq(@query).
        or(@klass.arel_table[@klass.hud_key].eq(@query)),
      )
    else
      item_scope.where(@klass.arel_table[@klass.hud_key].eq(@query))
    end
  end

  private def valid_class(type)
    return nil unless type.present?

    GrdaWarehouse::Hud.class_from_csv_name(type)
  end

  private def set_item
    @klass = valid_class(params[:type])
    return nil unless @klass.present?

    @item = item_scope.find(params[:id].to_i)
  end

  private def item_scope
    @klass.joins(:data_source).
      merge(GrdaWarehouse::DataSource.editable_by(current_user).source)
  end
end
