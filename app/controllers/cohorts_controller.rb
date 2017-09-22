class CohortsController < ApplicationController
  include PjaxModalController
  before_action :require_can_view_cohorts!

  def index
    @cohorts = GrdaWarehouse::Cohort.visible_by(current_user)
  end

  def edit

  end

  def destroy

  end

  def create

  end

  def update

  end
end