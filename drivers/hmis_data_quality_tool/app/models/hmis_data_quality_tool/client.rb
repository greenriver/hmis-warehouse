###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisDataQualityTool
  class Client < ::HudReports::ReportClientBase
    self.table_name = 'hmis_dqt_clients'
    include ArelHelper
    include DqConcern
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

    def self.calculate_issues(report_items, report)
      sections.each do |_, opts|
        report_items = calculate(**{ report_items: report_items, report: report }.merge(opts))
      end
      report_items
    end

    def self.calculate(report_items:, report:, title:, query:, **_)
      intermediate = {}
      client_scope(query, report).find_each do |client|
        item = report_item_fields_from_client(
          report_items: report_items,
          client: client,
          report: report,
        )

        intermediate[client] = item
      end

      import_intermediate!(intermediate.values)
      report.universe(title).add_universe_members(intermediate) if intermediate.present?

      report_items.merge(intermediate)
    end

    def self.client_scope(scope, report)
      GrdaWarehouse::Hud::Client.joins(enrollments: :service_history_enrollment).
        preload(:warehouse_client_source).
        merge(report.report_scope).distinct.
        where(scope)
    end

    def self.report_item_fields_from_client(report_items:, client:, report:)
      report_item = report_items[client] || new(
        report_id: report.id,
        client_id: client.id,
        destination_client_id: client.warehouse_client_source.destination_id,
      )
      report_item.first_name = client.FirstName
      report_item.last_name = client.LastName
      report_item.personal_id = client.PersonalID
      report_item.data_source_id = client.data_source_id
      report_item.male = client.Male
      report_item.female = client.Female
      report_item.no_single_gender = client.NoSingleGender
      report_item.transgender = client.Transgender
      report_item.questioning = client.Questioning
      report_items[client] = report_item
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

    def self.dob_issues_query
      # DOB is Blank, before 10/10/1910, or after entry date
      c_t[:DOB].eq(nil).
        or(c_t[:DOB].lteq('1910-10-10')).
        or(c_t[:DOB].gt(she_t[:first_date_in_program]))
    end

    def self.sections
      {
        gender_issues: {
          title: 'Gender',
          description: 'Gender fields and Gender None are incompatible, or invalid gender response was recorded',
          query: gender_issues_query,
        },
        race_issues: {
          title: 'Race',
          description: 'Race fields and Race None are incompatible, or invalid race response was recorded',
          query: race_issues_query,
        },
        dob_issues: {
          title: 'DOB',
          description: 'DOB is blank, before Oct. 10 1910, or after entry date',
          query: dob_issues_query,
        },
      }
    end
  end
end
