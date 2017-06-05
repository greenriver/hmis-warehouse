class StyleGuidesController < ApplicationController
  include PjaxModalController
  include WindowClientPathGenerator

  def icon_font
  end

  def careplan
    @client = GrdaWarehouse::Hud::Client.find(14911)
    @patient = @client.patient
    @careplan = @patient.careplan
    @goal = Health::Goal::Base.new
    @goals = @careplan.goals.order(number: :asc)
  end

  def add_goal
  end

  def health_team
    @member = Health::Team::Member.new
    @client = GrdaWarehouse::Hud::Client.find(14911)
    @patient = @client.patient
    @team = @patient.team
  end
end