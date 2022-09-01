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
        overlapping_entry_exit: 'Overlapping Entry/Exit enrollments in ES, SH, and TH',
        overlapping_nbn: 'Overlapping Night-by-Night ES enrollments with other ES, SH, and TH',
        overlapping_pre_move_in: 'Overlapping Homeless Service After Move-in in PH',
        overlapping_post_move_in: 'Overlapping Moved-in PH',
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
      GrdaWarehouse::Hud::Client.joins(source_enrollments: :service_history_enrollment).
        preload(:warehouse_client_source, source_enrollments: [:services, :exit, :project]).
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
        destination_client_id: client.id, # to actually identify overlaps, we need to work against destination clients
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
      report_item.enrollments = client.source_enrollments
      report_item.overlapping_entry_exit = overlapping_entry_exit(enrollments: report_item.enrollments, report: report)
      # FIXME
      report_item.overlapping_nbn = overlapping_nbn(enrollments: report_item.enrollments, report: report)
      report_item.overlapping_pre_move_in = overlapping_homeless_post_move_in(enrollments: report_item.enrollments, report: report)
      report_item.overlapping_post_move_in = overlapping_post_move_in(enrollments: report_item.enrollments, report: report)
      report_item
    end

    # check for overlapping ES entry exit, TH, SH
    def self.overlapping_entry_exit(enrollments:, report:)
      involved_enrollments = enrollments.select do |en|
        (en.project.es? && ! en.project.bed_night_tracking?) || en.project.sh? || en.project.th?
      end

      return 0 if involved_enrollments.blank? || involved_enrollments.count == 1

      ranges_overlap(enrollments: involved_enrollments, report: report).count
    end

    # check for overlapping PH post-move-in
    def self.overlapping_post_move_in(enrollments:, report:)
      involved_enrollments = enrollments.select do |en|
        en.project.ph?
      end

      return 0 if involved_enrollments.blank? || involved_enrollments.count == 1

      ranges_overlap(enrollments: involved_enrollments, report: report, start_date_method: :MoveInDate).count
    end

    def self.overlapping_nbn(enrollments:, report:)
      nbn_enrollments = enrollments.select do |en|
        en.project.es? && en.project.bed_night_tracking?
      end
      return 0 if nbn_enrollments.blank?

      involved_enrollments = enrollments.select do |en|
        en.project.es? || en.project.sh? || en.project.th?
      end
      return 0 if involved_enrollments.blank?

      overlaps = Set.new
      # see if there are any dates of service within the other homeless enrollments
      nbn_enrollments.each do |nbn_en|
        involved_enrollments.each do |en|
          next if nbn_en.id == en.id

          end_date = en.exit&.ExitDate || report.filter.end
          nbn_en.services.each do |service|
            overlaps << service.DateProvided if service.DateProvided.between?(en.EntryDate, end_date) && service.bed_night?
          end
        end
      end
      overlaps.count
    end

    def self.overlapping_homeless_post_move_in(enrollments:, report:)
      homeless_enrollments = enrollments.select do |en|
        en.project.es? || en.project.sh? || en.project.th?
      end
      return 0 if homeless_enrollments.blank?

      involved_enrollments = enrollments.select do |en|
        en.project.ph?
      end
      return 0 if involved_enrollments.blank?

      overlaps = Set.new
      # see if there are any dates of service within the housed date ranges
      homeless_enrollments.each do |h_en|
        involved_enrollments.each do |en|
          # we're only looking for overlaps with housing
          next unless en.MoveInDate.present?

          end_date = en.exit&.ExitDate || report.filter.end
          if h_en.project.es? && h_en.project.bed_night_tracking?
            h_en.services.each do |service|
              overlaps << service.DateProvided if service.DateProvided.between?(en.EntryDate, end_date) && service.bed_night?
            end
          else
            homeless_range = (h_en.EntryDate..(h_en.exit&.ExitDate || report.filter.end))
            housed_range = (en.MoveInDate..end_date)
            homeless_range.to_a & housed_range.to_a.each do |d|
              overlaps << d
            end
          end
        end
      end
      overlaps.count
    end

    # compare each enrollment to every other one and see if there are overlaps
    def self.ranges_overlap(enrollments:, report:, start_date_method: :EntryDate)
      overlaps = Set.new
      enrollments.product(enrollments).each do |batch|
        batch.each do |en|
          start_date = en.send(start_date_method)
          # We may be checking move-in dates and may not have one.
          next unless start_date.present?

          end_date = en.exit&.ExitDate || report.filter.end
          batch.each do |en2|
            next if en.id == en2.id

            start_date2 = en2.send(start_date_method)
            # We may be checking move-in dates and may not have one.
            next unless start_date2.present?

            end_date2 = en2.exit&.ExitDate || report.filter.end
            overlaps << [en.id, en2.id].sort if (start_date..end_date).overlaps?((start_date2..end_date2))
          end
        end
      end
      overlaps
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
          title: 'Overlapping Entry/Exit enrollments in ES, SH, and TH',
          description: 'Homeless projects using Entry/Exit tracking methods should not have overlapping enrollments.',
          limiter: ->(item) {
            item.overlapping_entry_exit.positive?
          },
        },
        overlapping_nbn_issues: {
          title: 'Overlapping Night-by-Night ES enrollments with other ES, SH, and TH',
          description: 'Client\'s receiving more than two overlapping ES NbN services are included.',
          limiter: ->(item) {
            item.overlapping_post_move_in > 2
          },
        },
        overlapping_pre_move_in_issues: {
          title: 'Overlapping Homeless Service After Move-in in PH',
          description: 'Client\'s receiving more than two overlapping homeless nights are included.',
          limiter: ->(item) {
            item.overlapping_post_move_in > 2
          },
        },
        overlapping_post_move_in_issues: {
          title: 'Overlapping Moved-in PH',
          description: 'Client\'s should not be housed in more than one project at a time.',
          limiter: ->(item) {
            item.overlapping_post_move_in.positive?
          },
        },
      }
    end
  end
end
