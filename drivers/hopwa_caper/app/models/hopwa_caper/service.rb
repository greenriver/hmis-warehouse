###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# services are only used to report on questions around households receiving certain service types
module HopwaCaper
  class Service < GrdaWarehouseBase
    self.table_name = 'hopwa_caper_services'

    has_many :hud_reports_universe_members,
             -> do
               where(::HudReports::UniverseMember.arel_table[:universe_membership_type].eq('HopwaCaper::Service'))
             end,
             inverse_of: :universe_membership,
             class_name: 'HudReports::UniverseMember',
             foreign_key: :universe_membership_id

    belongs_to :enrollment, class_name: 'HopwaCaper::Enrollment', primary_key: :enrollment_id
    delegate :first_name, :last_name, :personal_id, :hmis_enrollment_id, to: :enrollment

    def self.as_report_members
      all.map do |record|
        ::HudReports::UniverseMember.new(
          universe_membership_type: sti_name,
          universe_membership_id: record.id,
        )
      end
    end

    def self.from_hud_record(service:, enrollment:, report:, client:)
      new(
        report_household_id: [service.data_source_id, enrollment.household_id, report.id].join(':'),
        report_instance_id: report.id,

        destination_client_id: client.id,
        enrollment_id: enrollment.id,
        service_id: service.id,
        personal_id: client.personal_id,

        date_provided: service.date_provided,
        record_type: service.record_type,
        type_provided: service.type_provided,
        fa_amount: service.fa_amount,
      )
    end

    def self.detail_headers
      special = ['personal_id', 'hmis_enrollment_id', 'first_name', 'last_name']
      remove = ['id', 'created_at', 'updated_at', 'report_instance_id', 'enrollment_id', 'report_household_id']
      cols = special + (column_names - special - remove)
      cols.map do |header|
        label = case header
        when 'destination_client_id'
          'Warehouse Client ID'
        when 'personal_id'
          'HMIS Personal ID'
        when 'hmis_enrollment_id'
          'HMIS Enrollment ID'
        when 'service_id'
          'HMIS Service ID'
        else
          header.humanize
        end
        [header, label]
      end.to_h
    end
  end
end
