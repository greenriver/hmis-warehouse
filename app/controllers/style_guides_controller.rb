###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
    # Stub out a patient for the style guide if one isn't available
    @patient ||= OpenStruct.new(
      client: GrdaWarehouse::Hud::Client.new(
        id: 1,
        FirstName: Faker::Name.first_name,
        LastName: Faker::Name.last_name,
      ),
      careplans: Health::Careplan.none,
    )
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

  def health_dashboard
    @name = Faker::Name.name
    timeline_date_range = ((Date.today - 3.months)..Date.today)
    entries = []
    grid_lines = []
    timeline_date_range.each do |d|
      entries << (rand(1..50) > 45 ? 0.5 : nil)
      class_name = if d == d.at_beginning_of_month
        '--start-of-month'
      elsif d == d.at_beginning_of_week
        '--start-of-week'
      else
        ''
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

  def js_example
    # You can include javascript files for a single controller action by specifying an array of file paths
    @per_page_js = ['style_guide_example']
  end

  def system_colors
  end

  def colors
  end

  def client_dashboard
    setup_client_dashboard_data
  end

  private def guide_routes
    @guide_routes ||= {
      add_goal: 'Add Goal',
      add_team_member: 'Add Team Member',
      alerts: 'Alerts',
      buttons: 'Buttons',
      careplan: 'Careplan',
      client_dashboard: 'Client Dashboard',
      colors: 'Colors',
      form: 'Form Elements',
      health_dashboard: 'Health Dashboard',
      icon_font: 'Icon Font',
      pagination: 'Pagination',
      menu: 'Menu',
      modals: 'Modals',
      stimulus_select: 'Stimulus Select',
      reports: 'Reports',
      public_reports: 'Reports (Public)',
      tags: 'Tags',
      js_example: 'JS Example',
      system_colors: 'System Colors',
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

  private def setup_client_dashboard_data
    # Sample data for residential enrollments
    @sample_enrollments = [
      {
        client_source_id: 1,
        project_id: 1,
        project_name: 'Transitional Housing Program < ABC Housing Organization (MA-500)',
        confidential_project: false,
        entry_date: Date.new(2023, 1, 15),
        living_situation: 1,
        chronically_homeless_at_start: true,
        chronically_homeless_at_most_recent: false,
        exit_date: Date.new(2023, 8, 20),
        destination: 435,
        move_in_date: Date.new(2023, 1, 20),
        move_in_date_inherited: false,
        days: 218,
        homeless: true,
        residential: true,
        homeless_days: 218,
        adjusted_days: 218,
        months_served: [[2023, 1], [2023, 2], [2023, 3], [2023, 4], [2023, 5], [2023, 6], [2023, 7], [2023, 8]],
        household: [
          {
            'client_id' => 1,
            'FirstName' => 'John',
            'LastName' => 'Doe',
            'age' => 45,
            'head_of_household' => true,
            'first_date_in_program' => Date.new(2023, 1, 15),
            'move_in_date' => Date.new(2023, 1, 20),
            'last_date_in_program' => Date.new(2023, 8, 20),
          },
          {
            'client_id' => 2,
            'FirstName' => 'Jane',
            'LastName' => 'Doe',
            'age' => 42,
            'head_of_household' => false,
            'first_date_in_program' => Date.new(2023, 1, 15),
            'move_in_date' => Date.new(2023, 1, 20),
            'last_date_in_program' => Date.new(2023, 8, 20),
          },
        ],
        project_type: 'TH',
        project_type_id: 2,
        rrh_sub_type: nil,
        class: 'client__service_type_2',
        most_recent_service: Date.new(2023, 8, 20),
        new_episode: false,
        data_source_id: 1,
        created_at: DateTime.new(2023, 1, 15, 10, 0, 0),
        updated_at: DateTime.new(2023, 8, 20, 14, 30, 0),
        hmis_id: 12345,
        hmis_exit_id: 67890,
        total_enrollment_count: 3,
        visible_enrollment_count: 3,
      },
      {
        client_source_id: 1,
        project_id: 2,
        project_name: 'Permanent Supportive Housing < XYZ Services (MA-501)',
        confidential_project: false,
        entry_date: Date.new(2023, 9, 1),
        living_situation: 16,
        chronically_homeless_at_start: false,
        chronically_homeless_at_most_recent: false,
        exit_date: nil,
        destination: nil,
        move_in_date: Date.new(2023, 9, 15),
        move_in_date_inherited: false,
        days: 120,
        homeless: false,
        residential: true,
        homeless_days: 0,
        adjusted_days: 120,
        months_served: [[2023, 9], [2023, 10], [2023, 11], [2023, 12]],
        household: [
          {
            'client_id' => 1,
            'FirstName' => 'John',
            'LastName' => 'Doe',
            'age' => 45,
            'head_of_household' => true,
            'first_date_in_program' => Date.new(2023, 9, 1),
            'move_in_date' => Date.new(2023, 9, 15),
            'last_date_in_program' => nil,
          },
        ],
        project_type: 'PSH',
        project_type_id: 3,
        rrh_sub_type: nil,
        class: 'client__service_type_3',
        most_recent_service: Date.new(2023, 12, 30),
        new_episode: true,
        data_source_id: 1,
        created_at: DateTime.new(2023, 9, 1, 9, 0, 0),
        updated_at: DateTime.new(2023, 12, 30, 16, 45, 0),
        hmis_id: 23456,
        hmis_exit_id: nil,
        total_enrollment_count: 3,
        visible_enrollment_count: 3,
      },
      {
        client_source_id: 1,
        project_id: 3,
        project_name: 'Rapid Re-Housing Program < Community Housing Solutions (MA-502)',
        confidential_project: false,
        entry_date: Date.new(2022, 6, 10),
        living_situation: 1,
        chronically_homeless_at_start: true,
        chronically_homeless_at_most_recent: false,
        exit_date: Date.new(2022, 12, 31),
        destination: 411,
        move_in_date: Date.new(2022, 7, 1),
        move_in_date_inherited: false,
        days: 204,
        homeless: true,
        residential: true,
        homeless_days: 183,
        adjusted_days: 183,
        months_served: [[2022, 6], [2022, 7], [2022, 8], [2022, 9], [2022, 10], [2022, 11], [2022, 12]],
        household: [
          {
            'client_id' => 1,
            'FirstName' => 'John',
            'LastName' => 'Doe',
            'age' => 44,
            'head_of_household' => true,
            'first_date_in_program' => Date.new(2022, 6, 10),
            'move_in_date' => Date.new(2022, 7, 1),
            'last_date_in_program' => Date.new(2022, 12, 31),
          },
        ],
        project_type: 'RRH',
        project_type_id: 13,
        rrh_sub_type: 1,
        class: 'client__service_type_13',
        most_recent_service: Date.new(2022, 12, 31),
        new_episode: false,
        data_source_id: 1,
        created_at: DateTime.new(2022, 6, 10, 8, 30, 0),
        updated_at: DateTime.new(2022, 12, 31, 17, 0, 0),
        hmis_id: 34567,
        hmis_exit_id: 78901,
        total_enrollment_count: 3,
        visible_enrollment_count: 3,
      },
    ]

    # Create a mock client object for the style guide
    @client = MockClient.new

    # Set up defaults for the view
    @include_links = false
    @days_homeless = 401
  end

  # Mock client class for the style guide
  class MockClient
    def id
      1
    end

    def total_days(enrollments)
      enrollments.sum { |e| e[:days] }
    end

    def days_homeless
      401
    end

    def total_adjusted_days(enrollments)
      enrollments.sum { |e| e[:adjusted_days] }
    end

    def total_months(enrollments)
      enrollments.map { |e| e[:months_served] }.flatten.uniq.size
    end

    def hmis_source_visible_by?(_user)
      true
    end

    def program_tooltip_data_for_enrollment(_enrollment, _user)
      {}
    end

    def pii_provider(_user)
      OpenStruct.new(redact_name?: false, first_name: 'John')
    end
  end

  # Helper methods for the style guide
  def ds_tooltip_content(client_source_id, data_source_id)
    "Client Source: #{client_source_id}<br/>Data Source: #{data_source_id}"
  end

  def ds_short_name_for(client_source_id)
    "DS#{client_source_id}"
  end

  def can_view_confidential_project_names?
    false
  end

  # Make helper methods available to the view
  helper_method :ds_tooltip_content, :ds_short_name_for, :can_view_confidential_project_names
end
