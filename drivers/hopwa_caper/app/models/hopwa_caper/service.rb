###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Tracks services provided to HOPWA CAPER enrollments for reporting purposes.
#
# Services can originate from two sources:
# - HUD Services (service_source: 'hud_service'): Standard HUD service records from GrdaWarehouse::Hud::Service
#   - service_category_name: derived from record_type (e.g., "HOPWA Services")
#   - service_type_name: derived from type_provided (e.g., "Case management")
# - Custom Services (service_source: 'custom_service'): Custom service records from Hmis::Hud::CustomService
#   - service_category_name: from custom_service_type.custom_service_category.name
#   - service_type_name: from custom_service_type.name
#
# The service_category_name and service_type_name fields are denormalized for easier querying
# and reporting. They may be null if the source records lack the necessary type information.
#
# @see docs/features/hopwa_caper.md
module HopwaCaper
  class Service < ::HudReports::ReportClientBase
    self.table_name = 'hopwa_caper_services'

    HUD_SERVICE_SOURCE = 'hud_service'
    CUSTOM_SERVICE_SOURCE = 'custom_service'

    has_many :hud_reports_universe_members,
             -> do
               where(::HudReports::UniverseMember.arel_table[:universe_membership_type].eq('HopwaCaper::Service'))
             end,
             inverse_of: :universe_membership,
             class_name: 'HudReports::UniverseMember',
             foreign_key: :universe_membership_id

    belongs_to :enrollment, class_name: 'HopwaCaper::Enrollment', primary_key: :enrollment_id

    scope :hud_services, -> { where(service_source: HUD_SERVICE_SOURCE) }
    scope :custom_services, -> { where(service_source: CUSTOM_SERVICE_SOURCE) }

    delegate :first_name, :last_name, :personal_id, :hmis_enrollment_id, to: :enrollment

    def project_id
      enrollment.project.id
    end

    def self.as_report_members
      all.map do |record|
        ::HudReports::UniverseMember.new(
          universe_membership_type: sti_name,
          universe_membership_id: record.id,
        )
      end
    end

    def self.from_hud_service(service:, enrollment:, report:, client:)
      hud_util = HudHelper.util('2026')

      new(
        **common_attributes(
          report: report,
          enrollment: enrollment,
          client: client,
          service_id: service.id,
          service_source: HUD_SERVICE_SOURCE,
          data_source_id: service.data_source_id,
        ),
        date_provided: service.date_provided,
        record_type: service.record_type,
        type_provided: service.type_provided,
        fa_amount: service.fa_amount,
        service_category_name: hud_util.record_type(service.record_type),
        service_type_name: hud_util.service_type_provided(service.record_type, service.type_provided),
      )
    end

    def self.from_custom_service(service:, enrollment:, report:, client:)
      service_type = service.custom_service_type
      service_category = service_type&.custom_service_category

      new(
        **common_attributes(
          report: report,
          enrollment: enrollment,
          client: client,
          service_id: service.id,
          service_source: CUSTOM_SERVICE_SOURCE,
          data_source_id: service.data_source_id,
        ),
        date_provided: service.date_provided,
        fa_amount: service.fa_amount,
        service_category_name: service_category&.name,
        service_type_name: service_type&.name,
      )
    end

    def self.detail_headers
      special = ['personal_id', 'hmis_enrollment_id', 'first_name', 'last_name']
      remove = ['id', 'created_at', 'updated_at', 'report_instance_id', 'enrollment_id', 'report_household_id']
      cols = special + (column_names - special - remove)
      cols.map do |header|
        label = case header
        when 'service_source'
          'Service Source'
        when 'destination_client_id'
          'Warehouse Client ID'
        when 'personal_id'
          'HMIS Personal ID'
        when 'hmis_enrollment_id'
          'HMIS Enrollment ID'
        when 'service_id'
          'HMIS Service ID'
        when 'service_category_name'
          'Service Category'
        when 'service_type_name'
          'Service Type'
        else
          header.humanize
        end
        [header, label]
      end.to_h
    end

    def self.common_attributes(report:, enrollment:, client:, service_id:, service_source:, data_source_id:)
      {
        report_household_id: [data_source_id, enrollment.household_id, report.id].join(':'),
        report_instance_id: report.id,
        destination_client_id: client.id,
        enrollment_id: enrollment.id,
        service_id: service_id,
        service_source: service_source,
        personal_id: client.personal_id,
      }
    end
    private_class_method :common_attributes
  end
end
