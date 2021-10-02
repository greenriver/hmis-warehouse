###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
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
      @type = params.dig(:search, :type)
      @id = params.dig(:search, :id)
      @data_source_id = params.dig(:search, :data_source_id)
    end

    @results = load_results
  end

  def show
    @type = params[:type] if valid_class(params[:type]).present?
    @data_source = @item.data_source
    return unless RailsDrivers.loaded.include?(:hmis_csv_importer)

    @importer = HmisCsvImporter::Importer::ImporterLog.where(data_source_id: @item.data_source_id).order(created_at: :desc)&.first
    return unless @importer

    if @importer.completed_at < '2021-10-01'.to_date
      @imported = @item.imported_items_2020.order(importer_log_id: :desc).first
      @csv = @item.loaded_items_2020.with_deleted.order(loader_id: :desc).first
    else
      @imported = @item.imported_items_2022.order(importer_log_id: :desc).first
      @csv = @item.loaded_items_2022.with_deleted.order(loader_id: :desc).first
    end
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
    scope = if @query.to_i == @query
      item_scope.where(
        @klass.arel_table[:id].eq(@query).
        or(@klass.arel_table[@klass.hud_key].eq(@query)),
      )
    else
      item_scope.where(@klass.arel_table[@klass.hud_key].eq(@query))
    end
    scope = scope.where(data_source_id: @data_source_id) if @data_source_id
    scope
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
