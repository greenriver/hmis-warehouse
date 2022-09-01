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
    attr_accessor :enrollments

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
        gender_none: 'Gender None',
        am_ind_ak_native: 'American Indian, Alaska Native, or Indigenous',
        asian: 'Asian or Asian American',
        black_af_american: 'Black, African American, or African',
        native_hi_pacific: 'Native Hawaiian or Pacific Islander',
        white: 'White',
        race_none: 'Race None',
        overlapping_entry_exit: 'Overlapping Entry/Exits',
      }.freeze
    end

    # Because multiple of these calculations require inspecting all client enrollments
    # we're going to loop over the entire client scope once rather than
    # load it multiple times
    def self.calculate(report_items:, report:)
      client_scope(report).find_in_batches do |batch|
        intermediate = {}
        batch.each do |client|
          item = report_item_fields_from_client(
            report_items: report_items,
            client: client,
            report: report,
          )
          sections.each do |_, calc|
            section_title = calc[:title]
            intermediate[section_title] ||= {}
            intermediate[section_title][client] = item if calc[:limiter].call(item)
          end
        end
        intermediate.each do |section_title, client_batch|
          import_intermediate!(client_batch.values)
          report.universe(section_title).add_universe_members(client_batch) if client_batch.present?

          report_items.merge!(client_batch)
        end
      end
      report_items
    end

    def self.client_scope(report)
      GrdaWarehouse::Hud::Client.joins(enrollments: [:services, :service_history_enrollment, :project]).
        preload(:warehouse_client_source).
        merge(report.report_scope).distinct
    end

    def self.report_item_fields_from_client(report_items:, client:, report:)
      # we only need to do the calculations once, the values will be the same for any client,
      # no matter how many times we see it
      report_item = report_items[client]
      return report_item if report_item.present?

      report_item = new(
        report_id: report.id,
        client_id: client.id,
        destination_client_id: client.warehouse_client_source.destination_id,
      )
      report_item.first_name = client.FirstName
      report_item.last_name = client.LastName
      report_item.dob = client.DOB
      report_item.personal_id = client.PersonalID
      report_item.data_source_id = client.data_source_id
      report_item.male = client.Male
      report_item.female = client.Female
      report_item.no_single_gender = client.NoSingleGender
      report_item.transgender = client.Transgender
      report_item.questioning = client.Questioning
      report_item.gender_none = client.GenderNone
      report_item.am_ind_ak_native = client.AmIndAKNative
      report_item.asian = client.Asian
      report_item.black_af_american = client.BlackAfAmerican
      report_item.native_hi_pacific = client.NativeHIPacific
      report_item.white = client.White
      report_item.race_none = client.RaceNone
      # we need these for calculations, but don't want to store them permanently
      report_item.enrollments = client.enrollments
      report_item.overlapping_entry_exit = overlapping_entry_exit(enrollments: client.enrollments, report: report)
      # FIXME
      report_item.overlapping_nbn
      report_item.overlapping_pre_move_in
      report_item.overlapping_post_move_in
      report_item
    end

    # check for overlapping ES entry exit, TH, SH
    def self.overlapping_entry_exit(enrollments:, report:)
      involved_enrollments = enrollments.select do |en|
        project = en.project
        project_type = project.project_type_to_use
        project_type.in?(GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:es]) &&
          ! project.bed_night_tracking? ||
        project_type.in?(GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:sh]) ||
        project_type.in?(GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:th])
      end
      overlaps = Set.new
      return overlaps.count if involved_enrollments.blank? || involved_enrollments.count == 1

      # compare each enrollment to every other one and see if there are overlaps
      involved_enrollments.product(involved_enrollments).each do |batch|
        batch.each do |en|
          start_date = en.EntryDate
          end_date = en.service_history_enrollment.last_date_in_program || report.filter.end
          batch.each do |en2|
            next if en.id == en2.id

            start_date2 = en2.EntryDate
            end_date2 = en2.service_history_enrollment.last_date_in_program || report.filter.end
            overlaps << [en.id, en2.id].sort if (start_date..end_date).overlaps?((start_date2..end_date2))
          end
        end
      end
      overlaps.count
    end

    def self.sections
      {
        gender_issues: {
          title: 'Gender',
          description: 'Gender fields and Gender None are incompatible, or invalid gender response was recorded',
          limiter: ->(item) {
            # any fall outside accepted options
            values = [
              item.male,
              item.female,
              item.no_single_gender,
              item.transgender,
              item.questioning,
            ]
            return true if (values - HUD.yes_no_missing_options.keys).any?

            # any are yes and GenderNone is present
            return true if values.include?(1) && item.gender_none.present?

            # all are no or not collected and GenderNone is not in 8, 9, 99
            return true if values.all? { |m| m.in?([0, 99]) } && ! item.gender_none.in?([8, 9, 99])

            false
          },
        },
        race_issues: {
          title: 'Race',
          description: 'Race fields and Race None are incompatible, or invalid race response was recorded',
          limiter: ->(item) {
            # any fall outside accepted options
            values = [
              item.am_ind_ak_native,
              item.asian,
              item.black_af_american,
              item.native_hi_pacific,
              item.white,
            ]
            return true if (values - HUD.yes_no_missing_options.keys).any?

            # any are yes and RaceNone is present
            return true if values.include?(1) && item.race_none.present?

            # all are no or not collected and RaceNone is not in 8, 9, 99
            return true if values.all? { |m| m.in?([0, 99]) } && ! item.race_none.in?([8, 9, 99])

            false
          },
        },
        dob_issues: {
          title: 'DOB',
          description: 'DOB is blank, before Oct. 10 1910, or after entry date',
          limiter: ->(item) {
            # DOB is Blank
            return true if item.dob.blank?
            # before 10/10/1910
            return true if item.dob <= '1910-10-10'.to_date
            # in the future
            return true if item.dob >= Date.tomorrow
            # after any entry date
            return true if item.enrollments.any? { |en| en.EntryDate < item.dob }

            false
          },
        },
        overlapping_entry_exit_issues: {
          title: 'Overlapping Entry/Exits',
          description: 'FIXME',
          limiter: ->(item) {
            item.overlapping_entry_exit.positive?
          },
        },
      }
    end
  end
end
