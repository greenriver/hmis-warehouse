class StyleGuidesController < ApplicationController
  include PjaxModalController
  include WindowClientPathGenerator
  
  def alerts
  end

  def icon_font
  end

  def careplan
    @patient = Health::Patient.pilot.first
    @client = @patient.client
    @careplan = @patient.careplans.build
    @goal = Health::Goal::Base.new
    @goals = @careplan.goals.order(number: :asc)
  end

  def add_goal
  end

  def add_team_member
  end

  def health_team
    @member = Health::Team::Member.new
    @patient = Health::Patient.pilot.first
    @client = @patient.client
    @team = @patient.teams.build
    @careplan = @patient.careplans.first_or_create
  end
end