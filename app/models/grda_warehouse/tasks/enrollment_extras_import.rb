###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'roo'
require 'roo-xls'
module GrdaWarehouse::Tasks
  class EnrollmentExtrasImport
    # include TsqlImport
    include ArelHelper

    SPEC = {
      "Demographics" => {
        headers: [
          "Client Uid",
          "Entry Exit Uid",
          "Entry Exit Provider Id",
          "ROI Permission",
          "Entry Exit Entry Date",
          "Entry Exit Exit Date",
          "Locality of Last Residence(1242)",
          "Zip Code of Last Permanent Address(1215)",
        ],
        method: :demographics,
      },
      "VI-SPDAT2" => {
        headers: [
          "Client Uid",
          "Entry Exit Provider Id",
          "Entry Exit Uid",
          "GRAND TOTAL(2458)",
          "Date Added (2409-date_added)",
          "Start Date(2410)",
          "End Date(2411)",
        ],
        method: :vispdat2,
      },
      "VI-SPDAT1" => {
        headers: [
          "Client Uid",
          "Entry Exit Uid",
          "Entry Exit Provider Id",
          "PRE-SCREEN TOTAL(2238)",
          "GRAND TOTAL (ADJUSTED FOR v2.0)(2459)",
          "Date Added (2167-date_added)",
          "Start Date(2168)",
          "End Date(2169)",
        ],
        method: :vispdat1
      },
      "LPG" => {
        headers: [
          "Entry Exit Provider Id",
          "LPG",
        ],
        method: :lpg,
      },
    }

    def initialize(source:, data_source_id:)
      @source = source
      @data_source_id = data_source_id
    end

    def model
      ::GrdaWarehouse::EnrollmentExtra
    end

    def run!
      puts @source
      workbook = Roo::Excel.new(@source)
      model.transaction do
        workbook.each_with_pagename do |name, sheet|
          Rails.logger.info "importing sheet #{name} from #{@source}"
          spec = SPEC[name] or raise "unexpected sheet: #{name}"
          validate_headers sheet, name, spec[:headers]
          @name = name
          send spec[:method], sheet
        end
      end
      if @log.present?
        puts "Errors"
        puts "------"
        @log.group_by{ |m| m[:sheet] }.each do |sheet, ms|
          puts "\tsheet: #{sheet}"
          ms.each do |m|
            puts "\t\t#{m[:message]}"
          end
        end
      end
    end

    # log problems to be reported
    def log(msg)
      ( @log ||= [] ) << { sheet: @name, message: msg }
    end

    # This is contained in the final parenthesis of the string
    def parse_project_id value
      value.strip[ /.*\((.+)\).*/, 1 ]
    end

    def clean_string value
      value_to_i = value.to_i
      if value.try(:round) == value_to_i
        value_to_i
      else
        value
      end
    end

    def _handle_vispdat_row(row)
      personal_id, project_id_etc, project_entry_id, total, added_date, start_date, end_date = row
      project_id = parse_project_id(project_id_etc)
      personal_id = clean_string(personal_id)
      project_entry_id = clean_string(project_entry_id)
      enrollment = GrdaWarehouse::Hud::Enrollment.
        where( e_t[:PersonalID].eq personal_id ).
        where( e_t[:data_source_id].eq @data_source_id ).
        where( e_t[:EnrollmentID].eq project_entry_id ).
        where( e_t[:ProjectID].eq project_id ).
        first
      if enrollment
        # start_date, end_date, added_date = [ start_date, end_date, added_date ].map{ |d| d && Date.parse(d) }
        extras = model.where(
          enrollment_id:       enrollment.id,
          source_tab:          @name,
          vispdat_grand_total: total.to_i,
          vispdat_added_at:    added_date,
          vispdat_started_at:  start_date,
          vispdat_ended_at:    end_date,
        ).first_or_create
      else
        log "could not find enrollment for row #{row.inspect}"
      end
    end

    def vispdat1(sheet)
      model.joins(:enrollment).
        where( e_t[:data_source_id].eq @data_source_id ).
        where( source_tab: @name ).
        delete_all
      sheet.to_a[2..-1].each do |row|
        next if row.none?(&:present?)
        # rearrange columns
        personal_id, project_entry_id, project_id_etc, _, total, added_date, start_date, end_date = row
        _handle_vispdat_row [ personal_id, project_id_etc, project_entry_id, total, added_date, start_date, end_date ]
      end
    end

    def vispdat2(sheet)
      model.joins(:enrollment).
        where( e_t[:data_source_id].eq @data_source_id ).
        where( source_tab: @name ).
        delete_all
      sheet.to_a[2..-1].each do |row|
        next if row.none?(&:present?)
        _handle_vispdat_row row
      end
    end

    def demographics(sheet)
      sheet.to_a[2..-1].each do |row|
        next if row.none?(&:present?)
        personal_id, project_entry_id, project_id_etc, roi_permission, eee_date, _, locality, zip = row
        project_id = parse_project_id(project_id_etc)
        personal_id = clean_string(personal_id)
        project_entry_id = clean_string(project_entry_id)
        enrollment = GrdaWarehouse::Hud::Enrollment.
          where( e_t[:PersonalID].eq personal_id.to_s ).
          where( e_t[:data_source_id].eq @data_source_id ).
          where( e_t[:EnrollmentID].eq project_entry_id.to_s ).
          where( e_t[:ProjectID].eq project_id ).
          where( e_t[:EntryDate].eq eee_date ).
          first
        if enrollment
          roi_permission = roi_permission.strip == "Yes" rescue false
          enrollment.update_columns roi_permission: roi_permission, last_locality: locality, last_zipcode: zip
        else
          log "could not find enrollment for row #{row.inspect}"
        end
      end
    end

    def lpg(sheet)
      sheet.to_a[2..-1].each do |row|
        next if row.none?(&:present?)
        project_id_etc, group = row
        project_id = parse_project_id(project_id_etc)
        GrdaWarehouse::Hud::Projec.where( ProjectID: project_id, data_source_id: @data_source_id ).update_all local_planning_group: group
      end
    end

    def validate_headers(sheet, name, headers)
      sheet_headers = sheet.to_a[1]
      return if sheet_headers == headers
      raise "Unexpected headers in: #{name} \n #{sheet_headers.inspect} \n Looking for: \n #{headers.inspect}"
    end

  end
end
