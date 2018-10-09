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

    def set_time_format
      # We need this for exporting to the appropriate format
      @default_date_format = Date::DATE_FORMATS[:default]
      @default_time_format = Time::DATE_FORMATS[:default]
      Date::DATE_FORMATS[:default] = "%Y-%m-%d"
      Time::DATE_FORMATS[:default] = "%Y-%m-%d %H:%M:%S"
    end

    def reset_time_format
      Date::DATE_FORMATS[:default] = @default_date_format
      Time::DATE_FORMATS[:default] = @default_time_format
    end

    def housed
      @housed ||= Reporting::Housed.all
    end

    def returns
      @returns ||= Reporting::Return.all
    end

    def num_housed_1
      @num_housed_1 ||= begin
        set_r_variables
        @num_housed_1
      end
    end
    def num_housed_2
      @num_housed_2 ||= begin
        set_r_variables
        @num_housed_2
      end
    end
    def housed_plot_1
      @housedPlot_1 ||= begin
        set_r_variables
        @housedPlot_1
      end
    end
    def housed_plot_2
      @housedPlot_2 ||= begin
        set_r_variables
        @housedPlot_2
      end
    end
    def time_to_housing_1
      @time_to_housing_1 ||= begin
        set_r_variables
        @time_to_housing_1
      end
    end
    def time_to_housing_2
      @time_to_housing_2 ||= begin
        set_r_variables
        @time_to_housing_2
      end
    end
    def time_in_housing_1
      @time_in_housing_1 ||= begin
        set_r_variables
        @time_in_housing_1
      end
    end
    def time_in_housing_2
      @time_in_housing_2 ||= begin
        set_r_variables
        @time_in_housing_2
      end
    end
    def success_failure_1
      @success_failure_1 ||= begin
        set_r_variables
        @success_failure_1
      end
    end
    def success_failure_2
      @success_failure_2 ||= begin
        set_r_variables
        @success_failure_2
      end
    end
    def ph_exits_1
      @ph_exits_1 ||= begin
        set_r_variables
        @ph_exits_1
      end
    end
    def shelter_exits_1
      @shelter_exits_1 ||= begin
        set_r_variables
        @shelter_exits_1
      end
    end
    def ph_exits_2
      @ph_exits_2 ||= begin
        set_r_variables
        @ph_exits_2
      end
    end
    def shelter_exits_2
      @shelter_exits_2 ||= begin
        set_r_variables
        @shelter_exits_2
      end
    end
    def return_1
      @return_1 ||= begin
        set_r_variables
        @return_1
      end
    end
    def return_2
      @return_2 ||= begin
        set_r_variables
        @return_2
      end
    end
    def return_length_1
      @return_length_1 ||= begin
        set_r_variables
        @return_length_1
      end
    end
    def return_length_2
      @return_length_2 ||= begin
        set_r_variables
        @return_length_2
      end
    end
    def demographic_plot_1
      @demographic_plot_1 ||= begin
        set_r_variables
        @demographic_plot_1
      end
    end
    def demographic_plot_2
      @demographic_plot_2 ||= begin
        set_r_variables
        @demographic_plot_2
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

    def set_r_variables
      set_time_format
      housed_file = Tempfile.new('housed')
      CSV.open(housed_file, 'wb') do |csv|
        csv << housed.first.attributes.keys
        housed.each do |m|
          csv << m.attributes.values
        end
      end

      returns_file = Tempfile.new('returns')
      CSV.open(returns_file, 'wb') do |csv|
        csv << returns.first.attributes.keys
        returns.each do |m|
          csv << m.attributes.values
        end
      end

      housed_hash = {}
      housed.each do |h|
        h.attributes.each do |k,v|
          housed_hash[k] ||= []
          housed_hash[k] << v
        end
      end

      # For debugging, an R REPL in a Ruby REPL!
      # R.prompt
      # install_missing_r_packages()
      r.converse do
        <<~REOF
          library(lubridate)
          require(dplyr)
          require(magrittr)
          require(scales)
          library(jsonlite)
        REOF
      end

      r.converse(
        program_1: program_1_id,
        program_2: program_2_id,
        housed_file_path: housed_file.path,
        returns_file_path: returns_file.path
      ) do
        File.read('lib/r/rrh_report.r')
      end

      housed = r.converse("housed")


      housed_file.close
      housed_file.unlink
      returns_file.close
      returns_file.unlink
      reset_time_format

      @num_housed_1 = r.converse('num_housed_1')
      @num_housed_2 = r.converse('num_housed_2')
      @housedPlot_1 = JSON.parse(r.converse('housedPlot_1')) rescue '[]'
      @housedPlot_2 = JSON.parse(r.converse('housedPlot_2')) rescue '[]'
      @time_to_housing_1 = r.converse('time_to_housing_1') || 'unknown days to find housing' # prevent re-running if we receive no answer
      @time_to_housing_2 = r.converse('time_to_housing_2') || 'unknown days to find housing'
      @time_in_housing_1 = r.converse('time_in_housing_1') || 'unknown days in find housing'
      @time_in_housing_2 = r.converse('time_in_housing_2') || 'unknown days in find housing'
      @success_failure_1 = JSON.parse(r.converse('success_failure_1')) rescue '[]'
      @success_failure_2 = JSON.parse(r.converse('success_failure_2')) rescue '[]'
      @ph_exits_1 = r.converse('ph_exits_1')
      @shelter_exits_1 = r.converse('shelter_exits_1')
      @ph_exits_2 = r.converse('ph_exits_2')
      @shelter_exits_2 = r.converse('shelter_exits_2')
      @return_1 = r.converse('return_1')
      @return_2 = r.converse('return_2')
      @return_length_1 = begin
        (JSON.parse r.converse('return_length_1')).map do |row|
          row[:discrete] = length_of_time_buckets.try(:[], row['Discrete']) || row['Discrete']
          row[:count] = row['clients']
          row
        end
      rescue
        []
      end
      @return_length_2 = begin
        (JSON.parse r.converse('return_length_2')).map do |row|
          row[:discrete] = length_of_time_buckets.try(:[], row['Discrete']) || row['Discrete']
          row[:count] = row['clients']
          row
        end
      rescue
        []
      end
      @demographic_plot_1 = JSON.parse r.converse('demographic_plot_1')
      @demographic_plot_2 = JSON.parse r.converse('demographic_plot_2')

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