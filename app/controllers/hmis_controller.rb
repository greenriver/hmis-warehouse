
class HmisController < ApplicationController
  # TODO: this is a temporary proxy for access
  before_action :require_can_export_hmis_data!
  before_action :set_item, only: [:show]

  include ArelHelper

  def index

  end

  def show

  end

  private def set_item

  end


end