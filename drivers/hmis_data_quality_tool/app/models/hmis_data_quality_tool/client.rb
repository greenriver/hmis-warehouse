###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisDataQualityTool
  class Client < ::HudReports::ReportClientBase
    self.table_name = 'hmis_dqt_clients'
    include ArelHelper
    acts_as_paranoid

    has_many :hud_reports_universe_members, inverse_of: :universe_membership, class_name: 'HudReports::UniverseMember', foreign_key: :universe_membership_id
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', optional: true

    def self.detail_headers
      {
        destination_client_id: 'Warehouse Client ID',
        first_name: 'First Name',
        last_name: 'Last Name',
        personal_id: 'HMIS Personal ID',
        dob: 'DOB',
        dob_data_quality: 'DOB Data Quality',
        male: 'Male',
        female: 'Female ',
        no_single_gender: 'No Single Gender',
        transgender: 'Transgender',
        questioning: 'Questioning',
        am_ind_ak_native: 'American Indian, Alaska Native, or Indigenous',
        asian: 'Asian or Asian American',
        black_af_american: 'Black, African American, or African',
        native_hi_pacific: 'Native Hawaiian or Pacific Islander',
        white: 'White',
        race_none: 'Race None',
      }.freeze
    end

    def self.calculate_issues(report_clients, report)
      report_clients = calculate_gender_issues(report_clients, report)
      calculate_race_issues(report_clients, report)
    end

    def self.calculate_gender_issues(report_clients, report)
      intermediate_report_clients = {}
      GrdaWarehouse::Hud::Client.joins(enrollments: :service_history_enrollment).
        preload(:warehouse_client_source).
        merge(report.report_scope).distinct.
        where(gender_issues_query).
        find_each do |client|
          report_client = report_clients[client] || new(
            report_id: report.id,
            client_id: client.id,
            destination_client_id: client.warehouse_client_source.destination_id,
          )
          report_client.first_name = client.FirstName
          report_client.last_name = client.LastName
          report_client.personal_id = client.PersonalID
          report_client.data_source_id = client.data_source_id
          report_client.male = client.Male
          report_client.female = client.Female
          report_client.no_single_gender = client.NoSingleGender
          report_client.transgender = client.Transgender
          report_client.questioning = client.Questioning
          intermediate_report_clients[client] = report_client
        end

      import!(
        intermediate_report_clients.values,
        batch_size: 5_000,
        on_duplicate_key_update: {
          conflict_target: [:id],
          columns: attribute_names.map(&:to_sym),
        },
      )
      report.universe(gender_issues_slug).add_universe_members(intermediate_report_clients) if intermediate_report_clients.present?

      report_clients.merge(intermediate_report_clients)
    end

    def self.gender_issues_query
      yes = 1
      no_not_collected = [0, 99]
      # any fall outside accepted options
      c_t[:Female].not_in(HUD.yes_no_missing_options.keys).
        or(c_t[:Male].not_in(HUD.yes_no_missing_options.keys)).
        or(c_t[:NoSingleGender].not_in(HUD.yes_no_missing_options.keys)).
        or(c_t[:Transgender].not_in(HUD.yes_no_missing_options.keys)).
        or(c_t[:Questioning].not_in(HUD.yes_no_missing_options.keys)).
        or(
          # any are yes and GenderNone is present
          c_t[:Female].eq(yes).
          or(c_t[:Male].eq(yes)).
          or(c_t[:NoSingleGender].eq(yes)).
          or(c_t[:Transgender].eq(yes)).
          or(c_t[:Questioning].eq(yes)).
          and(c_t[:GenderNone].not_eq(nil)),
        ).
        or(
          # all are no or not collected and GenderNone is not in 8, 9, 99
          c_t[:Female].not_in(no_not_collected).
          and(c_t[:Male].not_in(no_not_collected)).
          and(c_t[:NoSingleGender].not_in(no_not_collected)).
          and(c_t[:Transgender].not_in(no_not_collected)).
          and(c_t[:Questioning].not_in(no_not_collected)).
          and(c_t[:GenderNone].not_in([8, 9, 99])),
        )
    end

    def self.calculate_race_issues(report_clients, report)
      intermediate_report_clients = {}
      GrdaWarehouse::Hud::Client.joins(enrollments: :service_history_enrollment).
        preload(:warehouse_client_source).
        merge(report.report_scope).distinct.
        where(race_issues_query).
        find_each do |client|
          report_client = report_clients[client] || new(
            report_id: report.id,
            client_id: client.id,
            destination_client_id: client.warehouse_client_source.destination_id,
          )
          report_client.first_name = client.FirstName
          report_client.last_name = client.LastName
          report_client.personal_id = client.PersonalID
          report_client.data_source_id = client.data_source_id
          report_client.male = client.Male
          report_client.am_ind_ak_native = client.AmIndAKNative
          report_client.asian = client.Asian
          report_client.black_af_american = client.BlackAfAmerican
          report_client.native_hi_pacific = client.NativeHIPacific
          report_client.white = client.White
          report_client.race_none = client.RaceNone
          intermediate_report_clients[client] = report_client
        end

      import!(
        intermediate_report_clients.values,
        batch_size: 5_000,
        on_duplicate_key_update: {
          conflict_target: [:id],
          columns: attribute_names.map(&:to_sym),
        },
      )

      report.universe(race_issues_slug).add_universe_members(intermediate_report_clients) if intermediate_report_clients.present?

      report_clients.merge(intermediate_report_clients)
    end

    def self.race_issues_query
      yes = 1
      no_not_collected = [0, 99]
      # any fall outside accepted options
      c_t[:AmIndAKNative].not_in(HUD.yes_no_missing_options.keys).
        or(c_t[:Asian].not_in(HUD.yes_no_missing_options.keys)).
        or(c_t[:BlackAfAmerican].not_in(HUD.yes_no_missing_options.keys)).
        or(c_t[:NativeHIPacific].not_in(HUD.yes_no_missing_options.keys)).
        or(c_t[:White].not_in(HUD.yes_no_missing_options.keys)).
        or(
          # any are yes and RaceNone is present
          c_t[:AmIndAKNative].eq(yes).
          or(c_t[:Asian].eq(yes)).
          or(c_t[:BlackAfAmerican].eq(yes)).
          or(c_t[:NativeHIPacific].eq(yes)).
          or(c_t[:White].eq(yes)).
          and(c_t[:RaceNone].not_eq(nil)),
        ).
        or(
          # all are no or not collected and RaceNone is not in 8, 9, 99
          c_t[:AmIndAKNative].not_in(no_not_collected).
          and(c_t[:Asian].not_in(no_not_collected)).
          and(c_t[:BlackAfAmerican].not_in(no_not_collected)).
          and(c_t[:NativeHIPacific].not_in(no_not_collected)).
          and(c_t[:White].not_in(no_not_collected)).
          and(c_t[:RaceNone].not_in([8, 9, 99])),
        )
    end

    def self.gender_issues_slug
      'Gender'
    end

    def self.race_issues_slug
      'Race'
    end
  end
end
