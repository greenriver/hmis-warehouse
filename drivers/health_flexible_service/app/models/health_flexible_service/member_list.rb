###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rubyXL'

module HealthFlexibleService
  class MemberList
    include ArelHelper

    attr_accessor :r_number, :end_date

    def initialize(aco_id, r_number, end_date)
      @aco_id = aco_id
      @r_number = r_number
      @report_range = ((end_date - 3.months)..end_date)
    end

    def filename
      @filename ||= begin
        aco = ::Health::AccountableCareOrganization.find(@aco_id)
        "#{aco.short_name}_ML_R#{@r_number}_QE#{@report_range.end.strftime('%Y%m%d')}.xlsx".upcase
      end
    end

    def write_to(template_path)
      workbook = RubyXL::Parser.parse(template_path)
      categories.each do |worksheet_name, category_name|
        worksheet = workbook[worksheet_name]
        vprs = vpr_scope(category_name)
        vprs.each_with_index do |vpr, row_index|
          columns(vpr, category_name).each_with_index do |value, col_index|
            value = value.join(', ') if value.is_a?(Array)
            worksheet.add_cell(row_index + 1, col_index, value)
          end
        end
      end
      workbook
    end

    def categories
      @categories ||= {
        'PRETENANCY_INDIVIDUAL' => 'Pre-Tenancy Supports: Individual Supports',
        'PRETENANCY_TRANSITIONAL' => 'Pre-Tenancy Supports: Transitional Assistance',
        'TENANCY_SUSTAINING' => 'Tenancy Sustaining Supports',
        'HOME_MODIFICATIONS' => 'Home Modification',
        'NUTRITION' => 'Nutritional Sustaining Supports',
      }.freeze
    end

    def columns(vpr, category)
      [
        vpr.patient[:medicaid_id],
        vpr[:last_name],
        vpr[:first_name],
        vpr[:middle_name],
        '', # We don't collect suffix, so leave it blank
        vpr[:dob].strftime('%Y%m%d'),
        vpr.patient.aco[:vpr_name],
        delivery_entities(vpr, category),
        'No', # transportation
        vpr[:gender],
        vpr[:sexual_orientation],
        vpr[:race],
        vpr[:primary_language],
        vpr[:education],
        vpr[:employment_status],
      ]
    end

    def vpr_scope(category)
      HealthFlexibleService::Vpr.
        joins(patient: :patient_referral).
        preload(patient: :patient_referral).
        merge(::Health::PatientReferral.at_acos(@aco_id)).
        category_in_range(category, @report_range).
        order(last_name: :asc, first_name: :asc, middle_name: :asc).
        distinct
    end

    private def delivery_entities(vpr, category)
      entity_names = (1..HealthFlexibleService::Vpr.max_service_count).map do |i|
        service_category = "service_#{i}_category"
        service_entity = "service_#{i}_delivering_entity"
        vpr[service_entity] if vpr[service_category] == category
      end
      entity_names.compact.uniq.join(', ')
    end
  end
end
