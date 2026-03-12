###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Thin wrapper around project for FBH sheets
# This model is not persisted
module HopwaCaper
  class Facility
    attr_reader :project, :report, :position

    def initialize(project:, report:, position:)
      @project = project
      @report = report
      @position = position
    end

    def id = project.id
    def name = project.project_name

    def medically_assisted_living_facility?
      case project.HOPWAMedAssistedLivingFac
      when 1
        true
      when 0, 2
        false
      end
    end

    def placed_in_service_during_program_year?
      project.OperatingStartDate&.between?(report.start_date, report.end_date)
    end

    def units_placed_into_service
      project.inventories.within_range(report.start_date..report.end_date).sum(:UnitInventory)
    end
  end
end
