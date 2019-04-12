
class HmisController < ApplicationController
  # TODO: this is a temporary proxy for access
  before_action :require_can_upload_hud_zips!
  before_action :set_item, only: [:show]
  before_action :searched?, only: [:index]

  include ArelHelper

  def index
    if searched?
      @type = params[:search].try(:[], :type)
      @id = params[:search].try(:[], :id)
    end

    @results = load_results

  end

  def show

  end

  private def searched?
    @searched = params[:search].present?
  end
  helper_method :searched?

  private def load_results
    return [] unless @searched
    @klass = valid_class(params[:search].try(:[], :type))
    return [] unless @klass.present?
    return [] unless params[:search][:id].present?
    # can't force to_i since this might be a string
    query = params[:search][:id]
    item_scope.where(
      @klass.arel_table[:id].eq(query).
      or(@klass.arel_table[@klass.hud_key].eq(query))
    )
  end

  private def valid_class type
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