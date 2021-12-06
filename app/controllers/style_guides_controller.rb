###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class StyleGuidesController < ApplicationController
  include AjaxModalRails::Controller
  include ClientPathGenerator

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
      class_name = ''
      class_name =
        if d == d.at_beginning_of_month
          '--start-of-month'
        elsif d == d.at_beginning_of_week
          '--start-of-week'
        end
      grid_lines << { value: d, class: "date-tick #{class_name}" }
    end
    @timeline_config = {
      data: {
        x: 'x',
        columns: [
          ['x'] + timeline_date_range.map { |d| d },
          ['Entries'] + entries,
        ],
        type: 'scatter',
      },
      grid: {
        x: {
          front: false,
          show: true,
          lines: grid_lines,
        },
      },
    }.to_json
    @appointments = (Date.today.beginning_of_week(:sunday)..Date.today + 2.weeks).map do |d|
      details = nil
      if rand(1..50) > 45
        details = {
          metadata: {
            doctor: Faker::Name.name,
          },
        }
      end
      {
        date: d,
        scheduled: details.present?,
        **(details || {}),
      }
    end
    @form = OpenStruct.new
  end

  def reports
    @indicator_groups = [
      {
        title: 'Rare',
        indicators: [[indicator], [indicator, indicator], [indicator]],
        description: lorem,
      },
      {
        title: 'Brief',
        indicators: [[indicator, indicator], [indicator, indicator], [indicator, indicator]],
        description: lorem,
      },
      {
        title: 'Non-Recuring',
        indicators: [[indicator], [indicator], [indicator]],
        description: lorem,
      },
    ]
  end

  def public_report
    render layout: 'test_public_report'
  end

  def modal
  end

  private def guide_routes
    @guide_routes ||= {
      add_goal: 'Add Goal',
      add_team_member: 'Add Team Member',
      alerts: 'Alerts',
      buttons: 'Buttons',
      careplan: 'Careplan',
      client_dashboard: 'Client Dashboard',
      form: 'Form Elements',
      health_team: 'Health Team',
      health_dashboard: 'Health Dashboard',
      icon_font: 'Icon Font',
      pagination: 'Pagination',
      modals: 'Modals',
      stimulus_select: 'Stimulus Select',
      reports: 'Reports',
      public_reports: 'Reports (Public)',
      tags: 'Tags',
    }
  end
  helper_method :guide_routes

  private def lorem sentence_count: 10
    Faker::Lorem.paragraph(sentence_count: sentence_count)
  end
  helper_method :lorem

  private def indicator
    directions = [:up, :down, :none]
    {
      title: lorem(sentence_count: 1),
      direction: directions[rand(0..2)],
      value_label: 'Change <br> over year',
      primary_value: rand(1..100),
      primary_unit: 'days',
      secondary_value: rand(1..100),
      secondary_unit: '%',
      passed: Faker::Boolean.boolean,
    }
  end
end
