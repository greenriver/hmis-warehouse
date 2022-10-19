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
        destination_client_id: { title: 'Warehouse Client ID' },
        first_name: { title: 'First Name' },
        last_name: { title: 'Last Name' },
        name_data_quality: { title: 'Name Data Quality', translator: ->(v) { HUD.name_data_quality(v) } },
        personal_id: { title: 'HMIS Personal ID' },
        dob: { title: 'DOB' },
        dob_data_quality: { title: 'DOB Data Quality', translator: ->(v) { HUD.dob_data_quality(v) } },
        male: { title: 'Male', translator: ->(v) { HUD.no_yes_missing(v) } },
        female: { title: 'Female', translator: ->(v) { HUD.no_yes_missing(v) } },
        no_single_gender: { title: 'No Single Gender', translator: ->(v) { HUD.no_yes_missing(v) } },
        transgender: { title: 'Transgender', translator: ->(v) { HUD.no_yes_missing(v) } },
        questioning: { title: 'Questioning', translator: ->(v) { HUD.no_yes_missing(v) } },
        gender_none: { title: 'Gender None', translator: ->(v) { HUD.gender_none(v) } },
        am_ind_ak_native: { title: 'American Indian, Alaska Native, or Indigenous', translator: ->(v) { HUD.no_yes_missing(v) } },
        asian: { title: 'Asian or Asian American', translator: ->(v) { HUD.no_yes_missing(v) } },
        black_af_american: { title: 'Black, African American, or African', translator: ->(v) { HUD.no_yes_missing(v) } },
        native_hi_pacific: { title: 'Native Hawaiian or Pacific Islander', translator: ->(v) { HUD.no_yes_missing(v) } },
        white: { title: 'White', translator: ->(v) { HUD.no_yes_missing(v) } },
        race_none: { title: 'Race None', translator: ->(v) { HUD.race_none(v) } },
        ethnicity: { title: 'Ethnicity', translator: ->(v) { HUD.ethnicity(v) } },
        veteran_status: { title: 'Veteran Status', translator: ->(v) { HUD.no_yes_reasons_for_missing_data(v) } },
        ssn: { title: 'SSN' },
        ssn_data_quality: { title: 'SSN Data Quality', translator: ->(v) { HUD.ssn_data_quality(v) } },
        overlapping_entry_exit: { title: 'Overlapping Entry/Exit enrollments in ES, SH, and TH' },
        overlapping_nbn: { title: 'Overlapping Night-by-Night ES enrollments with other ES, SH, and TH' },
        overlapping_pre_move_in: { title: 'Overlapping Homeless Service After Move-in in PH' },
        overlapping_post_move_in: { title: 'Overlapping Moved-in PH' },
        ch_at_most_recent_entry: { title: 'Chronically Homeless at Most-Recent Entry' },
        ch_at_any_entry: { title: 'Chronically Homeless at Any Entry' },
      }.freeze
    end

    def self.detail_headers_for_export
      return detail_headers if GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)

      detail_headers.except(:first_name, :last_name, :dob, :ssn)
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
            intermediate[section_title] ||= { denominator: {}, invalid: {} }
            intermediate[section_title][:denominator][client] = item if calc[:denominator].call(item)
            intermediate[section_title][:invalid][client] = item if calc[:limiter].call(item)
          end
        end
        intermediate.each do |section_title, item_batch|
          import_intermediate!(item_batch[:denominator].values)
          report.universe("#{section_title}__denominator").add_universe_members(item_batch[:denominator]) if item_batch[:denominator].present?
          report.universe("#{section_title}__invalid").add_universe_members(item_batch[:invalid]) if item_batch[:invalid].present?

          report_items.merge!(item_batch)
        end
      end
      report_items
    end

    def self.client_scope(report)
      GrdaWarehouse::Hud::Client.joins(source_enrollments: [:service_history_enrollment, :project]).
        preload(:warehouse_client_source, source_enrollments: [:exit, :project]).
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
      report_item.name_data_quality = client.NameDataQuality
      report_item.dob = client.DOB
      report_item.dob_data_quality = client.DOBDataQuality
      # for simplicity, since we don't have a specific enrollment, calculate age as of the end of the reporting period
      report_item.reporting_age = client.age_on(report.filter.end)
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
      report_item.ethnicity = client.Ethnicity
      report_item.veteran_status = client.VeteranStatus
      report_item.ssn = client.SSN
      report_item.ssn_data_quality = client.SSNDataQuality
      # we need these for calculations, but don't want to store them permanently,
      # also, limit them to those that overlap the projects included and the date range of the report
      report_item.enrollments = client.source_enrollments.select do |en|
        en.open_during_range?(report.filter.range) && en.project.id.in?(report.filter.effective_project_ids)
      end.uniq
      report_item.overlapping_entry_exit = overlapping_entry_exit(enrollments: report_item.enrollments, report: report)
      report_item.overlapping_nbn = overlapping_nbn(enrollments: report_item.enrollments, report: report)
      report_item.overlapping_pre_move_in = overlapping_homeless_post_move_in(enrollments: report_item.enrollments, report: report)
      report_item.overlapping_post_move_in = overlapping_post_move_in(enrollments: report_item.enrollments, report: report)
      report_item.ch_at_most_recent_entry = report_item.enrollments&.max_by(&:EntryDate)&.chronically_homeless_at_start?
      report_item.ch_at_any_entry = report_item.enrollments.map(&:chronically_homeless_at_start?)&.any?
      report_item
    end

    # check for overlapping ES entry exit, TH, SH
    def self.overlapping_entry_exit(enrollments:, report:)
      involved_enrollments = enrollments.select do |en|
        (en.project&.es? && ! en.project&.bed_night_tracking?) || en.project&.sh? || en.project&.th?
      end

      return 0 if involved_enrollments.blank? || involved_enrollments.count == 1

      ranges_overlap(enrollments: involved_enrollments, report: report).count
    end

    # check for overlapping PH post-move-in
    def self.overlapping_post_move_in(enrollments:, report:)
      involved_enrollments = enrollments.select do |en|
        en.project&.ph?
      end

      return 0 if involved_enrollments.blank? || involved_enrollments.count == 1

      ranges_overlap(enrollments: involved_enrollments, report: report, start_date_method: :MoveInDate).count
    end

    def self.overlapping_nbn(enrollments:, report:)
      nbn_enrollments = enrollments.select do |en|
        en.project&.es? && en.project&.bed_night_tracking?
      end
      return 0 if nbn_enrollments.blank?

      involved_enrollments = enrollments.select do |en|
        en.project&.es? || en.project&.sh? || en.project&.th?
      end
      return 0 if involved_enrollments.blank?

      overlaps = Set.new
      # see if there are any dates of service within the other homeless enrollments
      nbn_enrollments.each do |nbn_en|
        involved_enrollments.each do |en|
          next if nbn_en.id == en.id

          end_date = en.exit&.ExitDate || report.filter.end
          overlaps += nbn_en.services.where(RecordType: 200, DateProvided: [en.EntryDate, end_date]).pluck(:DateProvided)
          # nbn_en.services.each do |service|
          #   overlaps << service.DateProvided if service.DateProvided.between?(en.EntryDate, end_date) && service.bed_night?
          # end
        end
      end
      overlaps.count
    end

    def self.overlapping_homeless_post_move_in(enrollments:, report:)
      homeless_enrollments = enrollments.select do |en|
        en.project&.es? || en.project&.sh? || en.project&.th?
      end
      return 0 if homeless_enrollments.blank?

      involved_enrollments = enrollments.select do |en|
        en.project&.ph?
      end
      return 0 if involved_enrollments.blank?

      overlaps = Set.new
      # see if there are any dates of service within the housed date ranges
      homeless_enrollments.each do |h_en|
        involved_enrollments.each do |en|
          # we're only looking for overlaps with housing
          next unless en.MoveInDate.present?

          end_date = en.exit&.ExitDate || report.filter.end
          if h_en.project&.es? && h_en.project&.bed_night_tracking?
            overlaps += h_en.services.where(RecordType: 200, DateProvided: [en.MoveInDate, end_date]).pluck(:DateProvided)
            # h_en.services.each do |service|
            #   overlaps << service.DateProvided if service.DateProvided.between?(en.MoveInDate, end_date) && service.bed_night?
            # end
          else
            homeless_range = (h_en.EntryDate...(h_en.exit&.ExitDate || report.filter.end))
            housed_range = (en.MoveInDate...end_date)
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
            # three dots because starting on the end date is allowed
            overlaps << [en.id, en2.id].sort if (start_date...end_date).overlaps?((start_date2...end_date2))
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
          required_for: 'All',
          detail_columns: [
            :destination_client_id,
            :first_name,
            :last_name,
            :reporting_age,
            :male,
            :female,
            :no_single_gender,
            :transgender,
            :questioning,
            :gender_none,
          ],
          denominator: ->(_item) { true },
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
          required_for: 'All',
          detail_columns: [
            :destination_client_id,
            :first_name,
            :last_name,
            :reporting_age,
            :am_ind_ak_native,
            :asian,
            :black_af_american,
            :native_hi_pacific,
            :white,
            :race_none,
          ],
          denominator: ->(_item) { true },
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
          description: 'DOB is blank, before Oct. 10 1910, DOB is after an entry date, or DOB Data Quality is not collected, but DOB is present',
          required_for: 'All',
          detail_columns: [
            :destination_client_id,
            :first_name,
            :last_name,
            :reporting_age,
            :dob,
            :dob_data_quality,
          ],
          denominator: ->(_item) { true },
          limiter: ->(item) {
            # DOB is Blank
            return true if item.dob.blank?
            # DOB Quality is 99 or blank but dob is present?
            return true if item.dob.present? && (item.dob_data_quality.blank? || item.dob_data_quality == 99)
            # before 10/10/1910
            return true if item.dob <= '1910-10-10'.to_date
            # in the future
            return true if item.dob >= Date.tomorrow
            # after any entry date
            return true if item.enrollments.any? { |en| en.EntryDate < item.dob }

            false
          },
        },
        ssn_issues: {
          title: 'Social Security Number',
          description: 'SSN is blank but SSN Data Quality is 1, SSN is present but SSN Data Quality is not 1, or SSN Data Quality is 99 or blank, or SSN is all zeros',
          required_for: 'All',
          detail_columns: [
            :destination_client_id,
            :first_name,
            :last_name,
            :reporting_age,
            :ssn,
            :ssn_data_quality,
          ],
          denominator: ->(_item) { true },
          limiter: ->(item) {
            # SSN DQ is 99
            return true if item.ssn_data_quality == 99 || item.ssn_data_quality.blank?
            # SSN is Blank, but indicated it should be there
            return true if item.ssn.blank? && item.ssn_data_quality == 1
            # SSN is present but DQ indicates it shouldn't be
            return true if item.ssn.present? && ![1, 2].include?(item.ssn_data_quality)
            # SSN all zeros
            return true if (item.ssn =~ /^0+$/).present?

            false
          },
        },
        name_issues: {
          title: 'Name',
          description: 'Fist or last name is blank but Name Data Quality is 1, name is present but Name Data Quality is not 1, or Name Data Quality is 99 or blank',
          required_for: 'All',
          detail_columns: [
            :destination_client_id,
            :first_name,
            :last_name,
            :reporting_age,
            :name_data_quality,
          ],
          denominator: ->(_item) { true },
          limiter: ->(item) {
            # Name DQ is 99
            return true if item.name_data_quality == 99 || item.name_data_quality.blank?
            # Name is Blank, but indicated it should be there
            return true if [item.first_name, item.last_name].any?(nil) && item.name_data_quality == 1
            # Name is present but DQ indicates it shouldn't be
            return true if [item.first_name, item.last_name].all?(&:present?) && item.name_data_quality != 1

            false
          },
        },
        ethnicity_issues: {
          title: 'Ethnicity',
          description: 'Ethnicity is 99 or blank',
          required_for: 'All',
          detail_columns: [
            :destination_client_id,
            :first_name,
            :last_name,
            :reporting_age,
            :ethnicity,
          ],
          denominator: ->(_item) { true },
          limiter: ->(item) {
            return true if item.ethnicity == 99 || item.ethnicity.blank?

            false
          },
        },
        veteran_issues: {
          title: 'Veteran Status',
          description: 'Veteran Status is 99 or blank for adults',
          required_for: 'Adults (as of report end)',
          detail_columns: [
            :destination_client_id,
            :first_name,
            :last_name,
            :reporting_age,
            :veteran_status,
          ],
          denominator: ->(item) { item.reporting_age.present? && item.reporting_age > 18 },
          limiter: ->(item) {
            return false if item.reporting_age.blank? || item.reporting_age < 18
            return true if item.veteran_status == 99 || item.veteran_status.blank?

            false
          },
        },
        overlapping_entry_exit_issues: {
          title: 'Overlapping Entry/Exit enrollments in ES, SH, and TH',
          description: 'Homeless projects using Entry/Exit tracking methods should not have overlapping enrollments.',
          required_for: 'All',
          detail_columns: [
            :destination_client_id,
            :first_name,
            :last_name,
            :reporting_age,
            :overlapping_entry_exit,
          ],
          denominator: ->(_item) { true },
          limiter: ->(item) {
            item.overlapping_entry_exit.positive?
          },
        },
        overlapping_nbn_issues: {
          title: 'Overlapping Night-by-Night ES enrollments with other ES, SH, and TH',
          description: 'Client\'s receiving more than two overlapping ES NbN services are included.',
          required_for: 'All',
          detail_columns: [
            :destination_client_id,
            :first_name,
            :last_name,
            :reporting_age,
            :overlapping_nbn,
          ],
          denominator: ->(_item) { true },
          limiter: ->(item) {
            item.overlapping_nbn > 1
          },
        },
        overlapping_pre_move_in_issues: {
          title: 'Overlapping Homeless Service After Move-in in PH',
          description: 'Client\'s receiving more than two overlapping homeless nights are included.',
          required_for: 'Adults',
          detail_columns: [
            :destination_client_id,
            :first_name,
            :last_name,
            :reporting_age,
            :overlapping_pre_move_in,
          ],
          denominator: ->(item) { item.reporting_age.present? && item.reporting_age > 18 },
          limiter: ->(item) {
            return false unless item.reporting_age.present? && item.reporting_age > 18

            item.overlapping_pre_move_in > 2
          },
        },
        overlapping_post_move_in_issues: {
          title: 'Overlapping Moved-in PH',
          description: 'Client\'s should not be housed in more than one project at a time.',
          required_for: 'Adults',
          detail_columns: [
            :destination_client_id,
            :first_name,
            :last_name,
            :reporting_age,
            :overlapping_post_move_in,
          ],
          denominator: ->(item) { item.reporting_age.present? && item.reporting_age > 18 },
          limiter: ->(item) {
            return false unless item.reporting_age.present? && item.reporting_age > 18

            item.overlapping_post_move_in.positive?
          },
        },
      }
    end
  end
end
