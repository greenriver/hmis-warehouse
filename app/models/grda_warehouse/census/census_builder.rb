# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'progress_bar'

# Builds and populates the nightly_census_by_projects table.
# Entry point: GrdaWarehouse::Tasks::CensusImport#run!
module GrdaWarehouse::Census
  class CensusBuilder
    def self.call(...)
      new(...).call
    end

    attr_accessor :start_date, :end_date
    def initialize(start_date, end_date)
      self.start_date = start_date
      self.end_date = end_date
    end

    def call(project_ids: nil, progress: false)
      project_scope = relevant_projects(project_ids)
      bar = new_progress_bar(project_scope.count) if progress
      project_scope.find_each do |project|
        rows = project_rows(project)
        ByProject.transaction do
          ByProject.where(project: project).where(date: start_date..end_date).delete_all
          ByProject.import!(rows) if rows.any?
        end
        # bar&.puts("Project ID #{project.id}, rows: #{rows.size}")
        bar&.increment!(1)
      end
    end

    protected

    def populations
      @populations ||= GrdaWarehouse::Census.census_populations.map { |p| p[:population] }.uniq
    end

    def relevant_projects(project_ids)
      scope = GrdaWarehouse::Hud::Project
      scope = scope.where(id: project_ids) if project_ids
      scope.within_range(start_date..end_date)
    end

    def project_rows(project)
      merged = {}
      populations.each do |population|
        project_population_counts(project, population).each do |date, count|
          merged[date] ||= { project_id: project.id }
          merged[date][population] = count
        end
      end
      inventories = project.inventories.within_range(start_date..end_date).where.not(beds: nil)
      merged.keys.each do |date|
        inventories.each do |inventory|
          next unless inventory.active_on_date?(date)

          merged[date][:beds] ||= 0
          merged[date][:beds] += inventory.beds
        end
      end
      # ensure consistent cols for import
      cols = [:beds] + populations
      merged.map do |date, row|
        cols.each { |col| row[col] ||= 0 }
        row[:date] = date
        row
      end
    end

    def project_population_counts(project, population)
      enrollment_scope = GrdaWarehouse::ServiceHistoryEnrollment.
        where(project: project).
        public_send(population)

      GrdaWarehouse::ServiceHistoryService.
        joins(service_history_enrollment: :project).
        joins(:client).service_within_date_range(start_date: start_date, end_date: end_date).
        merge(enrollment_scope).
        group(:date).
        distinct.count(:client_id)
    end

    def new_progress_bar(total)
      ProgressBar.new(total, :counter, :bar, :percentage, :rate, :eta)
    end
  end
end
