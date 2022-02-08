###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# NOTE: Installation on mac
# TODO: Add the following to the developer setup once we know it works
# xcode-select --install
# brew install openssl@1.1
# export LIBRARY_PATH=$LIBRARY_PATH:/usr/local/opt/openssl@1.1/lib/
# R
# install.packages('Rserve',,"http://rforge.net/",type="source")


# NOTE: to use this in development, you'll need to do the following
# R
# pkg_url <- "https://cran.r-project.org/bin/macosx/el-capitan/contrib/3.5/Rserve_1.7-3.tgz"
# pkg_url <- "https://www.rforge.net/Rserve/snapshot/Rserve_1.8-6.tar.gz"
# install.packages(pkg_url, repos = NULL)
# library(Rserve)
# Rserve(args="--no-save")
#
#
# NOTE for linux
# wget https://www.rforge.net/Rserve/snapshot/Rserve_1.8-6.tar.gz
# R CMD INSTALL Rserve_1.8-6.tar.gz
# Figure out how to link installed version correctly https://stackoverflow.com/questions/24370980/how-to-specify-r-cmd-exec-directory
# R CMD Rserve
require 'rserve/simpler'
# require 'rinruby'
module Reporting
  class RrhReport

    attr_accessor :program_1_id, :program_2_id
    def initialize program_1_id:, program_2_id:
      self.program_1_id = program_1_id || ''
      self.program_2_id = program_2_id || ''
    end

    # mostly for debugging, allow external access
    def r
      @r ||= Rserve::Simpler.new
    end

    # def set_time_format
    #   # We need this for exporting to the appropriate format
    #   @default_date_format = Date::DATE_FORMATS[:default]
    #   @default_time_format = Time::DATE_FORMATS[:default]
    #   Date::DATE_FORMATS[:default] = "%Y-%m-%d"
    #   Time::DATE_FORMATS[:default] = "%Y-%m-%d %H:%M:%S"
    # end

    # def reset_time_format
    #   Date::DATE_FORMATS[:default] = @default_date_format
    #   Time::DATE_FORMATS[:default] = @default_time_format
    # end

    # def with_formatted_time
    #   set_time_format
    #   yield
    # ensure
    #   reset_time_format
    # end

    def housed
      @housed ||= Reporting::Housed.where(project_type: 13)
    end

    def returns
      @returns ||= Reporting::Return.where(client_id: housed.select(:client_id))
    end

    def num_housed_1
      @num_housed_1 ||= begin
        set_r_variables
        @project_1_data[:num_housed]
      end
    end
    def housed_plot_1
      @housedPlot_1 ||= begin
        set_r_variables
        @project_1_data[:housed_plot]
      end
    end
    def time_to_housing_1
      @time_to_housing_1 ||= begin
        set_r_variables
        @project_1_data[:time_to_housing]
      end
    end
    def time_in_housing_1
      @time_in_housing_1 ||= begin
        set_r_variables
        @project_1_data[:time_in_housing]
      end
    end
    def success_failure_1
      @success_failure_1 ||= begin
        set_r_variables
        @project_1_data[:success_failure]
      end
    end
    def ph_exits_1
      @ph_exits_1 ||= begin
        set_r_variables
        @project_1_data[:ph_exits]
      end
    end
    def shelter_exits_1
      @shelter_exits_1 ||= begin
        set_r_variables
        @project_1_data[:shelter_exits]
      end
    end
    def return_1
      @return_1 ||= begin
        set_r_variables
        @project_1_data[:return]
      end
    end
    def return_length_1
      @return_length_1 ||= begin
        set_r_variables
        @project_1_data[:return_length]
      end
    end
    def demographic_plot_1
      @demographic_plot_1 ||= begin
        set_r_variables
        @project_1_data[:demographic_plot]
      end
    end
    def num_housed_2
      @num_housed_2 ||= begin
        set_r_variables
        @project_2_data[:num_housed]
      end
    end
    def housed_plot_2
      @housedPlot_2 ||= begin
        set_r_variables
        @project_2_data[:housed_plot]
      end
    end
    def time_to_housing_2
      @time_to_housing_2 ||= begin
        set_r_variables
        @project_2_data[:time_to_housing]
      end
    end
    def time_in_housing_2
      @time_in_housing_2 ||= begin
        set_r_variables
        @project_2_data[:time_in_housing]
      end
    end
    def success_failure_2
      @success_failure_2 ||= begin
        set_r_variables
        @project_2_data[:success_failure]
      end
    end
    def ph_exits_2
      @ph_exits_2 ||= begin
        set_r_variables
        @project_2_data[:ph_exits]
      end
    end
    def shelter_exits_2
      @shelter_exits_2 ||= begin
        set_r_variables
        @project_2_data[:shelter_exits]
      end
    end
    def return_2
      @return_2 ||= begin
        set_r_variables
        @project_2_data[:return]
      end
    end
    def return_length_2
      @return_length_2 ||= begin
        set_r_variables
        @project_2_data[:return_length]
      end
    end
    def demographic_plot_2
      @demographic_plot_2 ||= begin
        set_r_variables
        @project_2_data[:demographic_plot]
      end
    end

    def length_of_time_buckets
      @length_of_time_buckets ||= {
        '(0,7]' => 'Less than 1 week',
        '(7,30]' => '1 week to one month',
        '(30,91]' => '1 month to 3 months',
        '(91,182]' => '3 months to 6 months',
        '(182,364]' => '3 months to 1 year',
        '(364,728]' => '1 year to 2 years',
        '(728,Inf]' => '2 years or more',
      }
    end

    def cache_key_for_program program_id
      ['r', 'rrh-report', program_id.to_s].to_s
    end

    def should_rebuild?
      ! (Rails.cache.exist?(cache_key_for_program(program_1_id)) && Rails.cache.exist?(cache_key_for_program(program_2_id)))
    end


    def set_r_variables
      # Don't bother building things if we've already cached them both
      if should_rebuild?
        housed_file = Tempfile.new('housed')
        CSV.open(housed_file, 'wb') do |csv|
          csv << housed.first.attributes.keys
          housed.each do |m|
            csv << m.attributes.values.map do |v|
              if v.respond_to?(:iso8601) then v.iso8601 else v end
            end
          end
        end

        returns_file = Tempfile.new('returns')
        CSV.open(returns_file, 'wb') do |csv|
          csv << returns.first.attributes.keys
          returns.each do |m|
            csv << m.attributes.values.map do |v|
              if v.respond_to?(:iso8601) then v.iso8601 else v end
            end
          end
        end
      end

      @project_1_data = fetch_from_r(program_id: program_1_id, housed_file_path: housed_file&.path, returns_file_path: returns_file&.path)
      @project_2_data = fetch_from_r(program_id: program_2_id, housed_file_path: housed_file&.path, returns_file_path: returns_file&.path)

      if should_rebuild?
        housed_file.close
        housed_file.unlink
        returns_file.close
        returns_file.unlink
      end
    end

    def fetch_from_r program_id:, housed_file_path:, returns_file_path:
      Rails.cache.fetch(cache_key_for_program(program_id), expires_in: 10.minutes) do
        r.converse(
          program_1: program_id,
          housed_file_path: housed_file_path,
          returns_file_path: returns_file_path
        ) do
          File.read('lib/r/rrh_report.r')
        end
        project_data = {}
        project_data[:num_housed] = r.converse('num_housed_1')
        project_data[:housed_plot] = JSON.parse(r.converse('housedPlot_1')) rescue '[]'
        project_data[:time_to_housing] = r.converse('time_to_housing_1') || 'unknown days to find housing'
        project_data[:time_in_housing] = r.converse('time_in_housing_1') || 'unknown days in find housing'
        project_data[:success_failure] = JSON.parse(r.converse('success_failure_1')) rescue '[]'
        project_data[:ph_exits] = r.converse('ph_exits_1')
        project_data[:shelter_exits] = r.converse('shelter_exits_1')
        project_data[:return] = r.converse('return_1')
        project_data[:return_length] = begin
          (JSON.parse r.converse('return_length_1')).map do |row|
            row[:discrete] = length_of_time_buckets.try(:[], row['Discrete']) || row['Discrete']
            row[:count] = row['clients']
            row
          end
        rescue
          []
        end
        project_data[:demographic_plot] = JSON.parse r.converse('demographic_plot_1')
        project_data
      end
    end

    def install_missing_r_packages
      r.command <<~REOF
        list.of.packages <- c("lubridate", "dplyr", "magrittr", "scales", "jsonlite")
        new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
        if(length(new.packages)) install.packages(new.packages)
        library(lubridate)
        require(dplyr)
        require(magrittr)
        require(scales)
        library(jsonlite)
      REOF
    end
  end
end
