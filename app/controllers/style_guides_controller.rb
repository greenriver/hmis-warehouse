###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class StyleGuidesController < ApplicationController
  include AjaxModalRails::Controller
  include ClientPathGenerator
  skip_before_action :authenticate_user!

  def index
  end

  def alerts
  end

  def icon_font
  end

  def careplan
    @patient = Health::Patient.pilot.first
    @client = @patient.client
    @careplan = @patient.careplans.build
    @goal = Health::Goal::Base.new
    @goals = @careplan.hpc_goals.order(number: :asc)
  end

  def add_goal
  end

  def add_team_member
  end

  def form
    @form = OpenStruct.new
  end

  def stimulus_select
    @form = OpenStruct.new
  end

  def health_team
    @member = Health::Team::Member.new
    @patient = Health::Patient.pilot.first
    @client = @patient.client
    @team = @patient.teams.build
    @careplan = @patient.careplans.first_or_create
  end

  def health_dashboard
    @name = Faker::Name.name
    timeline_date_range = ((Date.today - 3.months)..Date.today)
    entries = []
    grid_lines = []
    timeline_date_range.each do |d|
      entries << (rand(1..50) > 45 ? 0.5 : nil)
      class_name = ""
      class_name =
        if d == d.at_beginning_of_month
          "--start-of-month"
        elsif d == d.at_beginning_of_week
          "--start-of-week"
        end
      grid_lines << { value: d, class: "date-tick #{class_name}" }
    end
    @timeline_config = {
      data: {
        x: "x",
        columns: [
          [ "x" ] + timeline_date_range.map{ |d| d },
          [ "Entries" ] + entries,
        ],
        type: "scatter",
      },
      grid: {
        x: {
          front: false,
          show: true,
          lines: grid_lines,
        }
      }
    }.to_json
  end

  private def guide_routes
    @guide_routes ||= {
      form: 'Form Elements',
      careplan: 'Careplan',
      health_team: 'Health Team',
      icon_font: 'Icon Font',
      add_goal: 'Add Goal',
      add_team_member: 'Add Team Member',
      alerts: 'Alerts',
      tags: 'Tags',
      client_dashboard: 'Client Dashboard',
      buttons: 'Buttons',
      pagination: 'Pagination',
      stimulus_select: 'Stimulus Select',
    }
  end
  helper_method :guide_routes
end
