###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::TcHmis::Importers::Loaders
  class MhmrNonBillableNoteLoader < CustomAssessmentLoader
    ASSESSMENT_DATE_COL = 'Date Taken'.freeze

    # Based on the the data Gig extracted from the form definition
    CDED_CONFIGS = [
      { key: 'mhmr_service_start_time', label: 'Start', field_type: 'string', repeats: false },
      { key: 'mhmr_service_end_time', label: 'End', field_type: 'string', repeats: false },
      { key: 'mhmr_service_duration', label: 'Service Duration', field_type: 'string', repeats: false },
      { key: 'mhmr_staff_name', label: 'Staff Name', field_type: 'string', repeats: false },
      { key: 'mhmr_staff_id', label: 'Staff ID#', field_type: 'string', repeats: false },
      { key: 'mhmr_staff_credentials', label: 'Staff Credentials', field_type: 'string', repeats: false },
      { key: 'mhmr_staff_scheduled_appointment', label: 'Scheduled Checkbox', field_type: 'boolean', repeats: false, ignore_type: true },
      { key: 'mhmr_dnka', label: 'DNKA Check Box', field_type: 'boolean', repeats: false, ignore_type: true },
      { key: 'mhmr_action_taken', label: 'Action taken', field_type: 'string', repeats: false },
      { key: 'mhmr_result', label: 'Result', field_type: 'string', repeats: false },
      { key: 'mhmr_other_notes', label: 'Other Notes', field_type: 'string', repeats: false },
    ].freeze

    def filename
      'MHMR-Non-Billable.xlsx'
    end

    def cded_configs
      CDED_CONFIGS +
        (1..6).map do |i|
          [
            { key: "mhmr_service_code_location_#{i}", label: "Location Code Row #{i}", field_type: 'string', repeats: false },
            { key: "mhmr_service_code_activity_code_#{i}", label: "Activity Code Row #{i}", field_type: 'string', repeats: false },
            { key: "mhmr_service_code_project_no_#{i}", label: "Project Number Row #{i}", field_type: 'string', repeats: false },
            { key: "mhmr_service_code_start_time_#{i}", label: "Start / Stop Time Row #{i}", field_type: 'string', repeats: false },
            { key: "mhmr_service_code_stop_time_#{i}", label: "Start / Stop Time Row #{i}", field_type: 'string', repeats: false },
            { key: "mhmr_service_code_recipient_#{i}", label: "Recipient Row #{i}", field_type: 'string', repeats: false },
            { key: "mhmr_service_code_attendance_#{i}", label: "Attendance Row #{i}", field_type: 'string', repeats: false },
            { key: "mhmr_service_code_num_recipients_#{i}", label: "Number of Recipients Row #{i}", field_type: 'string', repeats: false },
            { key: "mhmr_service_code_recipient_time_#{i}", label: "Recipient Time Row #{i}", field_type: 'string', repeats: false },
            { key: "mhmr_service_code_lof_#{i}", label: "LOF Row #{i}", field_type: 'string', repeats: false },
          ]
        end.flatten
    end

    def row_assessment_date(row)
      parse_date(row.field_value(ASSESSMENT_DATE_COL))
    end

    # use the eto response id to construct the custom assessment id
    def row_assessment_id(row)
      response_id = row.field_value(RESPONSE_ID_COL)
      "mhmr-nb-eto-#{response_id}"
    end

    def cde_values(row, config)
      key = config.fetch(:key)
      values = super(row, config)
      case key
        # Time ranges are 2 strings separated by ' - '
      when /mhmr_service_code_start_time/
        values.map { |value| value.present? ? value.split(' - ').first : nil }
      when /mhmr_service_code_stop_time/
        values.map { |value| value.present? ? value.split(' - ').last : nil }
        # Booleans where presence of a string means true
      when 'mhmr_staff_scheduled_appointment', 'mhmr_dnka'
        values.map(&:present?)
      else
        values
      end
    end

    def form_definition_identifier
      'mhmr-non-billable-note'
    end

    # Method to transform time string ("01:30AM") to minutes since midnight (90)
    # This isn't used here yet, but should be incorporated if the MHMR loaders are used again.
    # (Or, use this code to data-fix after they are used).
    #
    # Relevant for the following CDEDs:
    # 'mhmr_service_code_start_time_1',
    # 'mhmr_service_code_start_time_2',
    # 'mhmr_service_code_start_time_3',
    # 'mhmr_service_code_start_time_4',
    # 'mhmr_service_code_start_time_5',
    # 'mhmr_service_code_start_time_6',
    # 'mhmr_service_code_stop_time_1',
    # 'mhmr_service_code_stop_time_2',
    # 'mhmr_service_code_stop_time_3',
    # 'mhmr_service_code_stop_time_4',
    # 'mhmr_service_code_stop_time_5',
    # 'mhmr_service_code_stop_time_6',
    # 'mhmr_service_end_time',
    # 'mhmr_service_start_time',
    def transform_time_of_day(time_of_day_str)
      # https://stackoverflow.com/a/32466925/18803965
      times = { '12 AM' => 0 }.merge!(1.upto(11).collect { |n| { "#{n} AM" => n } }.reduce({}, :merge)).merge!({ '12 PM' => 12 }).merge!(1.upto(11).collect { |n| { "#{n} PM" => n + 12 } }.reduce({}, :merge))
      # {"12 AM"=>0, "1 AM"=>1, "2 AM"=>2, "3 AM"=>3, "4 AM"=>4, "5 AM"=>5, "6 AM"=>6, "7 AM"=>7, "8 AM"=>8, "9 AM"=>9, "10 AM"=>10, "11 AM"=>11, "12 PM"=>12, "1 PM"=>13, "2 PM"=>14, "3 PM"=>15, "4 PM"=>16, "5 PM"=>17, "6 PM"=>18, "7 PM"=>19, "8 PM"=>20, "9 PM"=>21, "10 PM"=>22, "11 PM"=>23}

      str = time_of_day_str # "01:09PM"
      return time_of_day_str if str&.size != 7 || !['AM', 'PM'].include?(str.last(2))

      hours = str.split(':').first.to_i
      minutes = str.split(':').last.first(2).to_i
      am_pm = str.last(2)
      hours_since_midnight = times["#{hours} #{am_pm}"]
      minutes_since_midnight = (hours_since_midnight * 60) + minutes

      minutes_since_midnight
    end
  end
end
