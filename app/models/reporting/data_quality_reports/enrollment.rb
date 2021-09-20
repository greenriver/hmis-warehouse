###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# A reporting table to power the enrollment related answers for project data quality reports.

# Some notes on completeness from the HUD Glossary

# Order for checking: Doesn't know/refused, then missing.
# Rules
# • Within each row, the column categories are mutually exclusive; records that meet more than one of the criteria described below should be counted in the column for the first match.
# • Column B Row 2 – count of clients where [Name Data Quality] = 8 or 9.
# • Column C Row 2 – count of clients where [First Name] OR [Last Name] is missing.
# • Column D Row 2 – [Name Data Quality] = 2
# • Column B Row 3 – count of clients where [SSN Data Quality] = 8 or 9.
# • Column C Row 3 – count of clients where [SSN] is missing.
# • Column D Row 3 – count of clients where [SSN Data Quality] = 2 OR [SSN] does not conform to Social
# Security Administration rules for a valid SSN shown below.
# o Cannot contain a non-numeric character.
# o Must be 9 digits long.
# o First three digits cannot be “000,” “666,” or in the 900 series. o The second group / 5th and 6th digits cannot be “00”.
# o The third group / last four digits cannot be “0000”.
# o There cannot be repetitive (e.g. “333333333”) or sequential (e.g. “345678901” “987654321”)
# numbers for all 9 digits.
# • Column B Row 4 – count of clients where [DOB Data Quality] = 8 or 9.
# • Column C Row 4 – count of clients where [DOB] is missing.
# • Column D Row 4 – count of clients where [DOB Data Quality] = 2 OR where [DOB] is any one of the values
# listed below
# o Priorto1/1/1915.
# o After the [date created] for the record.
# o For heads of household and adults only: Equal to or after the [project start date]. This test
# purposely excludes child household members including those who may be newborns.
# • Column B Row 5, 6, 7 – count of clients where [Race] [Ethnicity] [Gender] respectively = 8 or 9. For [Race],
# include records with an 8 or 9 indicated even if there is also a value of 1, 2, 3, 4 or 5 in the same field.
# • Column C Row 5, 6, 7 – count of clients where [Race] [Ethnicity] [Gender] respectively is missing.
# • Column E Rows 2 through 7 – [total] = the unique count of clients reported in columns B, C or D, i.e. report
# each record only once per person if the field fails any one of the data quality checks. Divide the [total] by
# the total number of people indicated in the validations table.
# • Column E Row 8 – [total] = the unique count of clients reported in columns B, C or D / rows 2 through 7.
# Again, report each record only once per person even if there are multiple data quality issues in multiple fields.

# • Column B Row 2: count of adults where [veteran status] = 8, 9, missing OR ([veteran status] = 1 and [Age] < 18).
# • Column B Row 3: count of clients where:
# o [Project start date] < [project exit date] for an earlier project start. This detects overlapping project
# stays by the same client in the same project.
# • Column B Row 4: count of all clients where any one of the following are true:
# o [Relationship to Head of Household] is missing or has a value that is not between 1 and 5. OR
# o Thereisnohouseholdmemberforthegroupofclientswiththesame[HouseholdID]wherethe
# [Relationship to Head of Household] = Self (1). I.e. report every household member without an
# identified head of household for the [Household ID]. OR
# o More than one client for the [Household ID] has a [Relationship to Head of Household] = Self. I.e.
# report every household member in households where multiple heads of household exist. • Column B Row 5: count of heads of household where:
# o There is no record of [client location] for the project start with a [data collection stage] of project start (1). OR
# o The [Continuum of Care Code] for the client location record does not match a valid HUD-defined Continuum of Care Code.
# • Column B Row 6: count of clients where ([disabling condition] = 8, 9, missing) OR ([disabling condition] = 0 AND there is at least one special need where “substantially impairs ability to live independently” = 1)

# 1. Column B Row 2 – count the number of leavers where [Destination] = 8, 9, 30, or missing.
# 2. Column B Row 3 – count the number of adults and heads of household active in the report date range
# where any one of the following are true:
#  22 | P a g e
#                a. [income and sources] at start is completely missing.
# b. There is no record of [income and sources] with an [information date] equal to [project start date]
# and a [data collection stage] of project start (1).
# c. [data collection stage] for [income and sources] = 1 AND [income from any source] = 8, 9, or missing.
# d. [data collection stage] for [income and sources] = 1 AND [income from any source] = 0 AND there
# are identified income sources.
# e. [data collection stage] for [income and sources] = 1 AND [income from any source] = 1 AND there
# are no identified income sources.
# 3. Column B Row 4 – count the number of adults and heads of household stayers active in the report date
# range where the head of household has a project stay of >= 365 days as of the [report end date] AND where any one of the following are true:
# a. There is no record of [income and sources] with an [information date] within 30 days of the anniversary date and a [data collection stage] of annual assessment (5).
# b. [information date] is within 30 days of the anniversary date AND [data collection stage] for [income and sources] = 5 AND [income from any source] = 8, 9, or missing.
# c. [information date] is within 30 days of the anniversary date AND [data collection stage] for [income and sources] = 5 AND [income from any source] = 0 AND there are identified income sources.
# d. [information date] is within 30 days of the anniversary date AND [data collection stage] for [income and sources] = 5 AND [income from any source] = 1 AND there are no identified income sources.
# 4. Column B Row 5 – count the number of adult and head of household leavers where any one of the following are true:
# a. There is no record of [income and sources] with an [information date] equal to [project exit date] and a [data collection stage] of project exit (3).
# b. [data collection stage] for [income and sources] = 3 AND [income from any source] = 8, 9, or missing.
# c. [income from any source] = 0 AND there are identified income sources.
# d. [income from any source] = 1 AND there are no identified income sources.

module Reporting::DataQualityReports
  class Enrollment < ReportingBase
    include ArelHelper

    COMPLETE = [1, 2]
    REFUSED = [8, 9]
    YES_NO = [0,1]
    VALID_GENDERS = [0,1,2,3,4]

    self.table_name = :warehouse_data_quality_report_enrollments

    belongs_to :report, class_name: 'GrdaWarehouse::WarehouseReports::Project::DataQuality::Base', foreign_key: :report_id

    scope :enrolled, -> do
      where enrolled: true
    end

    scope :active, -> do
      where active: true
    end

    scope :stayer, -> do
      where exited: false
    end

    scope :exited, -> do
      where exited: true
    end

    scope :entered, -> do
      where entered: true
    end

    scope :adult, -> do
      where adult: true
    end

    scope :head_of_household, -> do
      where head_of_household: true
    end

    scope :adult_or_head_of_household, -> do
      a_t = Reporting::DataQualityReports::Enrollment.arel_table
      enrolled.where(a_t[:head_of_household].eq(true).or(a_t[:adult].eq(true)))
    end

    scope :ph, -> do
      where project_type: GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph]
    end

    scope :should_calculate_income_annual_completeness, -> do
      where should_have_income_annual_assessment: true
    end

    def is_adult? date:
      age = calculate_age date: date
      age.present? && age > 18
    end

    def is_exited? exit_record:, report_start:, report_end:
      exit_record.present? && exit_record.ExitDate.in?(report_start..report_end)
    end

    def is_entered? entry_date:, report_start:, report_end:
       entry_date.in?(report_start..report_end)
    end

    def calculate_age date:
      GrdaWarehouse::Hud::Client.age date: date, dob: dob
    end

    def is_stayer? report_end:, exit_date:
      return true if exit_date.blank?
      exit_date > report_end
    end

    def is_leaver? report_end:, exit_date:
      exit_date.present? && exit_date <= report_end
    end

    # Blanks should not be allowed according to the spec
    def is_head_of_household? enrollment:
      enrollment.RelationshipToHoH.blank? || enrollment.RelationshipToHoH == 1
    end

    def calculate_days_to_add_entry_date enrollment:
      (enrollment.DateCreated.to_date - enrollment.EntryDate).to_i
    end

    def calculate_days_to_add_exit_date exit_record:
      if exit_record.blank? || exit_record.ExitDate.blank?
        nil
      else
        (exit_record.DateCreated.to_date - exit_record.ExitDate).to_i
      end
    end

    def calculate_dob_after_entry_date
      dob.present? && dob > entry_date
    end

    def is_active? project:, service_dates:, report_start:, report_end:
      return true unless project.bed_night_tracking?
      ((report_start..report_end).to_a & service_dates).any?
    end

    def calculate_most_recent_service_within_range project:, service_dates:, report_start:, report_end:, exit_date:
      if ! project.bed_night_tracking?
        [report_end, exit_date].compact.min
      else
        ((report_start..report_end).to_a & service_dates).max
      end
    end

    def calculate_service_within_last_30_days project:, service_dates:, exit_date:, report_end:
      if ! project.bed_night_tracking?
        true
      else
        range = if exit_date.present?
          ((exit_date - 30.days)..exit_date)
        else
          ((report_end - 30.days)..report_end)
        end
        (range.to_a & service_dates).any?
      end
    end

    def calculate_service_after_exit project:, service_dates:, exit_date:
      if ! project.bed_night_tracking? || exit_date.blank? || service_dates.blank?
        false
      else
        service_dates.max > exit_date rescue false
      end
    end

    # NOTE: days served between start and (exit or report_end), whichever is earlier
    def calculate_days_of_service project:, service_dates:, entry_date:, exit_date:,  report_end:
      if project.bed_night_tracking?
        service_dates.select{ |d| d <= report_end }.uniq.count
      else
        if exit_date.present? && exit_date <= report_end
          (exit_date - entry_date).to_i
        else
          (report_end - entry_date).to_i
        end
      end
    end

    # per the HUD glossary, refused trumps missing, missing trumps partial
    # We're adding in not collected and complete so these need to be added in the following
    # order
    # refused, not collected, missing, partial, complete
    def set_name_completeness  first_name:, last_name:, name_quality:
      if calculate_name_refused(name_quality: name_quality)
        self.name_refused = true
        return
      end
      if calculate_name_not_collected(name_quality: name_quality)
        self.name_not_collected = true
        return
      end
      if calculate_name_missing(first_name: first_name, last_name: last_name)
        self.name_missing = true
        return
      end
      if calculate_name_partial(name_quality: name_quality)
        self.name_partial = true
        return
      end
      self.name_complete = true
    end

    def calculate_name_refused name_quality:
      name_quality.in?(REFUSED)
    end

    def calculate_name_missing first_name:, last_name:
      (first_name.blank? || last_name.blank?)
    end

    def calculate_name_partial name_quality:
      name_quality == 2
    end

    def calculate_name_not_collected name_quality:
      name_quality == 99
    end


    def set_ssn_completeness  ssn:, ssn_quality:
      if calculate_ssn_refused(ssn_quality: ssn_quality)
        self.ssn_refused = true
        return
      end
      if calculate_ssn_not_collected(ssn_quality: ssn_quality)
        self.ssn_not_collected = true
        return
      end
      if calculate_ssn_missing(ssn: ssn)
        self.ssn_missing = true
        return
      end
      if calculate_ssn_partial(ssn_quality: ssn_quality)
        self.ssn_partial = true
        return
      end
      self.ssn_complete = true
    end

    def calculate_ssn_complete ssn:, ssn_quality:
      ssn_quality.in?(COMPLETE) && ssn.present?
    end

    def calculate_ssn_refused ssn_quality:
      ssn_quality.in?(REFUSED)
    end

    def calculate_ssn_missing ssn:
      ssn.blank? || ! ::HUD.valid_social?(ssn)
    end

    def calculate_ssn_partial ssn_quality:
      ssn_quality == 2
    end

    def calculate_ssn_not_collected ssn_quality:
      ssn_quality == 99
    end

    def set_dob_completeness  dob:, dob_quality:, head_of_household:, entry_date:, enrollment_created_date:
      if calculate_dob_refused(dob_quality: dob_quality)
        self.dob_refused = true
        return
      end
      if calculate_dob_not_collected(dob_quality: dob_quality)
        self.dob_not_collected = true
        return
      end
      if calculate_dob_missing(
        dob: dob,
        dob_quality: dob_quality,
        head_of_household: head_of_household,
        entry_date: entry_date,
        enrollment_created_date: enrollment_created_date
      )
        self.dob_missing = true
        return
      end
      if calculate_dob_partial(dob_quality: dob_quality)
        self.dob_partial = true
        return
      end
      self.dob_complete = true
    end

    def calculate_dob_complete dob:, dob_quality:
      dob_quality.in?(COMPLETE) && dob.present?
    end

    def calculate_dob_refused dob_quality:
      dob_quality.in?(REFUSED)
    end

    def calculate_dob_missing dob:, dob_quality:, head_of_household:, entry_date:, enrollment_created_date:
      missing = false
      missing = true if dob.blank?
      missing = true if dob_quality == 2
      missing = true if dob.present? && dob < '1915-01-01'.to_date
      missing = true if dob.present? && dob > enrollment_created_date
      missing = true if (is_adult?(date: Date.current) || head_of_household) && dob.present? && dob >= entry_date

      return missing
    end

    def calculate_dob_partial dob_quality:
      dob_quality == 2
    end

    def calculate_dob_not_collected dob_quality:
      dob_quality == 99
    end

    def set_gender_completeness(gender_none:, gender_multi:)
      if calculate_gender_refused(gender_none: gender_none)
        self.gender_refused = true
        return
      end
      if calculate_gender_not_collected(gender_none: gender_none)
        self.gender_not_collected = true
        return
      end
      if calculate_gender_missing(gender_multi: gender_multi)
        self.gender_missing = true
        return
      end
      self.gender_complete = true
    end

    def calculate_gender_refused gender_none:
      gender_none.in?(REFUSED)
    end

    def calculate_gender_missing gender_multi:
      gender_multi.blank?
    end

    def calculate_gender_not_collected gender_none:
      gender_none == 99
    end

    def set_veteran_completeness  veteran:, entry_date:
      if calculate_veteran_refused(veteran: veteran, entry_date: entry_date)
        self.veteran_refused = true
        return
      end
      if calculate_veteran_not_collected(veteran: veteran)
        self.veteran_not_collected = true
        return
      end
      if calculate_veteran_missing(veteran: veteran, entry_date: entry_date)
        self.veteran_missing = true
        return
      end
      self.veteran_complete = true
    end

    def calculate_veteran_refused veteran:, entry_date:
      return false unless is_adult?(date: entry_date)
      veteran.in?(REFUSED)
    end

    def calculate_veteran_missing veteran:, entry_date:
      return false unless is_adult?(date: entry_date)
      veteran.blank?
    end

    def calculate_veteran_not_collected veteran:
      veteran == 99
    end

    def set_ethnicity_completeness  ethnicity:
      if calculate_ethnicity_refused(ethnicity: ethnicity)
        self.ethnicity_refused = true
        return
      end
      if calculate_ethnicity_not_collected(ethnicity: ethnicity)
        self.ethnicity_not_collected = true
        return
      end
      if calculate_ethnicity_missing(ethnicity: ethnicity)
        self.ethnicity_missing = true
        return
      end
      self.ethnicity_complete = true
    end

    def calculate_ethnicity_refused ethnicity:
      ethnicity.in?(REFUSED)
    end

    def calculate_ethnicity_missing ethnicity:
      ethnicity.blank?
    end

    def calculate_ethnicity_not_collected ethnicity:
      ethnicity == 99
    end

    def set_race_completeness race_none:, american_indian_or_ak_native:, asian:, black_or_african_american:, native_hi_or_other_pacific_islander:, white:
      if calculate_race_refused(race_none: race_none)
        self.race_refused = true
        return
      end
      if calculate_race_not_collected(race_none: race_none)
        self.race_not_collected = true
        return
      end
      if calculate_race_missing(
        race_none: race_none,
        american_indian_or_ak_native: american_indian_or_ak_native,
        asian: asian,
        black_or_african_american: black_or_african_american,
        native_hi_or_other_pacific_islander: native_hi_or_other_pacific_islander,
        white: white,
      )
        self.race_missing = true
        return
      end
      self.race_complete = true
    end

    def calculate_race_refused race_none:
      race_none.in?(REFUSED)
    end

    # all blank
    def calculate_race_missing race_none:, american_indian_or_ak_native:, asian:, black_or_african_american:, native_hi_or_other_pacific_islander:, white:
      race_none.blank? &&
      american_indian_or_ak_native.blank? &&
      asian.blank? &&
      black_or_african_american.blank? &&
      native_hi_or_other_pacific_islander.blank? &&
      white.blank?
    end

    def calculate_race_not_collected race_none:
      race_none == 99
    end

    # This uses 3.8 Disabling condition, NOT the disability table, HMIS should
    # keep this in sync with 4.5 - 4.10, with the exception of indefinite and impairs
    # We'll grab the most recent Disability response
    def set_disabling_condition_completeness disabling_condition:, all_indefinite_and_impairs:
      if calculate_disabling_condition_refused(disabling_condition: disabling_condition)
        self.disabling_condition_refused = true
        return
      end
      if calculate_disabling_condition_not_collected(disabling_condition: disabling_condition)
        self.disabling_condition_not_collected = true
        return
      end
      if calculate_disabling_condition_missing(disabling_condition: disabling_condition, all_indefinite_and_impairs: all_indefinite_and_impairs)
        self.disabling_condition_missing = true
        return
      end
      self.disabling_condition_complete = true
    end

    def calculate_disabling_condition_refused disabling_condition:
      return false unless is_adult?(date: Date.current)
      disabling_condition.in?(REFUSED)
    end

    def calculate_disabling_condition_missing disabling_condition:, all_indefinite_and_impairs:
      return false unless is_adult?(date: Date.current)
      disabling_condition.blank? || disabling_condition == 0 && all_indefinite_and_impairs.present? && all_indefinite_and_impairs.any?(1)
    end

    def calculate_disabling_condition_not_collected disabling_condition:
      disabling_condition == 99
    end

    def set_destination_completeness hud_exit:, head_of_household:
      if hud_exit.blank?
        self.destination_complete = true
        return
      end
      if calculate_destination_refused(destination: hud_exit.Destination, head_of_household: head_of_household)
        self.destination_refused = true
        return
      end
      if calculate_destination_not_collected(destination: hud_exit.Destination, head_of_household: head_of_household)
        self.destination_not_collected = true
        return
      end
      if calculate_destination_missing(destination: hud_exit.Destination, head_of_household: head_of_household)
        self.destination_missing = true
        return
      end
      self.destination_complete = true
    end

    def calculate_destination_refused destination:, head_of_household:
      return false unless is_adult?(date: Date.current) || head_of_household
      destination.in?(REFUSED)
    end

    def calculate_destination_missing destination:, head_of_household:
      return false unless is_adult?(date: Date.current) || head_of_household
      destination.blank?
    end

    def calculate_destination_not_collected destination:, head_of_household:
      return false unless is_adult?(date: Date.current) || head_of_household
      destination.in? [30, 99]
    end

    def set_prior_living_situation_completeness  prior_living_situation:, head_of_household:
      if calculate_prior_living_situation_refused(
        prior_living_situation: prior_living_situation,
        head_of_household: head_of_household
      )
        self.prior_living_situation_refused = true
        return
      end
      if calculate_prior_living_situation_not_collected(
        prior_living_situation: prior_living_situation,
        head_of_household: head_of_household
      )
        self.prior_living_situation_not_collected = true
        return
      end
      if calculate_prior_living_situation_missing(
        prior_living_situation: prior_living_situation,
        head_of_household: head_of_household
      )
        self.prior_living_situation_missing = true
        return
      end
      self.prior_living_situation_complete = true
    end

    def calculate_prior_living_situation_refused prior_living_situation:, head_of_household:
      return false unless is_adult?(date: Date.current) || head_of_household
      prior_living_situation.in?(REFUSED)
    end

    def calculate_prior_living_situation_missing prior_living_situation:, head_of_household:
      return false unless is_adult?(date: Date.current) || head_of_household
      prior_living_situation.blank?
    end

    def calculate_prior_living_situation_not_collected prior_living_situation:, head_of_household:
      return false unless is_adult?(date: Date.current) || head_of_household
      prior_living_situation == 99
    end

    def set_income_at_entry_completeness  income_at_entry:
      if calculate_income_at_entry_refused(
        income_at_entry: income_at_entry,
        head_of_household: head_of_household
      )
        self.income_at_entry_refused = true
        return
      end
      if calculate_income_at_entry_not_collected(
        income_at_entry: income_at_entry,
        head_of_household: head_of_household
      )
        self.income_at_entry_not_collected = true
        return
      end
      if calculate_income_at_entry_missing(
        income_at_entry: income_at_entry,
        head_of_household: head_of_household
      )
        self.income_at_entry_missing = true
        return
      end
      self.income_at_entry_complete = true
    end

    def calculate_income_at_entry_refused income_at_entry:, head_of_household:
      return false unless is_adult?(date: Date.current) || head_of_household
      income_at_entry.present? && income_at_entry.IncomeFromAnySource.in?(REFUSED)
    end

    def calculate_income_at_entry_missing income_at_entry:, head_of_household:
      return false unless is_adult?(date: Date.current) || head_of_household
      income_at_entry.blank? || income_at_entry.IncomeFromAnySource.blank?
    end

    def calculate_income_at_entry_not_collected income_at_entry:, head_of_household:
      return false unless is_adult?(date: Date.current) || head_of_household
      income_at_entry.present? && income_at_entry.IncomeFromAnySource == 99
    end

    def set_income_at_exit_completeness income_at_exit:, head_of_household:, exit_date:, report_end:
      if calculate_income_at_exit_refused(
        income_at_exit: income_at_exit,
        head_of_household: head_of_household,
        exit_date: exit_date,
        report_end: report_end,
      )
        self.income_at_exit_refused = true
        return
      end
      if calculate_income_at_exit_not_collected(
        income_at_exit: income_at_exit,
        head_of_household: head_of_household,
        exit_date: exit_date,
        report_end: report_end,
      )
        self.income_at_exit_not_collected = true
        return
      end
      if calculate_income_at_exit_missing(
        income_at_exit: income_at_exit,
        head_of_household: head_of_household,
        exit_date: exit_date,
        report_end: report_end,
      )
        self.income_at_exit_missing = true
        return
      end
      self.income_at_exit_complete = true
    end

    def calculate_income_at_exit_refused income_at_exit:, exit_date:, report_end:, head_of_household:
      return false unless is_adult?(date: Date.current) || head_of_household
      return false if exit_date.blank? # no exit
      return false if exit_date > report_end # exit after report end
      income_at_exit.present? && income_at_exit.IncomeFromAnySource.in?(REFUSED)
    end

    def calculate_income_at_exit_missing income_at_exit:, exit_date:, report_end:, head_of_household:
      return false unless is_adult?(date: Date.current) || head_of_household
      return false if exit_date.blank? # no exit
      return false if exit_date > report_end # exit after report end
      income_at_exit.blank? || income_at_exit.IncomeFromAnySource.blank?
    end

    def calculate_income_at_exit_not_collected income_at_exit:, exit_date:, report_end:, head_of_household:
      return false unless is_adult?(date: Date.current) || head_of_household
      return false if exit_date.blank? # no exit
      return false if exit_date > report_end # exit after report end
      income_at_exit.present? && income_at_exit.IncomeFromAnySource == 99
    end

    def set_income_at_annual_completeness entry_date:, exit_date:, income_record:, head_of_household:, report_end:
      # Short circuit if we shouldn't have a record
      if ! should_calculate_annual_completeness?(
        entry_date: entry_date,
        exit_date: exit_date,
        head_of_household: head_of_household,
        report_end: report_end,
      )
        self.income_at_annual_assessment_complete = true
        return
      end
      if calculate_income_at_annual_assessment_refused(
        income_record: income_record,
        head_of_household: head_of_household,
        report_end: report_end,
        entry_date: entry_date,
        exit_date: exit_date,
      )
        self.income_at_annual_assessment_refused = true
        return
      end
      if calculate_income_at_annual_assessment_not_collected(
        income_record: income_record,
        head_of_household: head_of_household,
        report_end: report_end,
        entry_date: entry_date,
        exit_date: exit_date,
      )
        self.income_at_annual_assessment_not_collected = true
        return
      end
      if calculate_income_at_annual_assessment_missing(
        income_record: income_record,
        head_of_household: head_of_household,
        report_end: report_end,
        entry_date: entry_date,
        exit_date: exit_date,
      )
        self.income_at_annual_assessment_missing = true
        return
      end
      self.income_at_annual_assessment_complete = true
    end

    def calculate_income_at_annual_assessment_refused income_record:, report_end:, head_of_household:, entry_date:, exit_date:
      return false unless should_calculate_annual_completeness?(
        entry_date: entry_date,
        exit_date: exit_date,
        head_of_household: head_of_household,
        report_end: report_end,
      )
      income_record.present? && income_record.IncomeFromAnySource.in?(REFUSED)
    end

    def calculate_income_at_annual_assessment_missing income_record:, report_end:, head_of_household:, entry_date:, exit_date:
      return false unless should_calculate_annual_completeness?(
        entry_date: entry_date,
        exit_date: exit_date,
        head_of_household: head_of_household,
        report_end: report_end,
      )
      income_record.blank? || income_record.IncomeFromAnySource.blank?
    end

    def calculate_income_at_annual_assessment_not_collected income_record:, report_end:, head_of_household:, entry_date:, exit_date:
      return false unless should_calculate_annual_completeness?(
        entry_date: entry_date,
        exit_date: exit_date,
        head_of_household: head_of_household,
        report_end: report_end,
      )
      income_record.present? && income_record.IncomeFromAnySource == 99
    end

    # income calculations are only valid for clients who are adults
    # or heads-of-household at entry
    def should_calculate_income_change? entry_date:, head_of_household:
      return true if is_adult?(date: entry_date) || head_of_household
      return false
    end

    # This should be nil unless we have some income
    def calculate_income_at_entry_earned income_at_entry:,  entry_date:, head_of_household:
      return unless should_calculate_income_change?(entry_date: entry_date, head_of_household: head_of_household)
      return unless income_at_entry.present?
      income_for_types(types: earned_income_types, income_record: income_at_entry)
    end

    def calculate_income_at_entry_non_employment_cash income_at_entry:,  entry_date:, head_of_household:
      return unless should_calculate_income_change?(entry_date: entry_date, head_of_household: head_of_household)
      return unless income_at_entry.present?
      income_for_types(types: non_employment_cash_income_types, income_record: income_at_entry)
    end

    def calculate_income_at_entry_overall income_at_entry:,  entry_date:, head_of_household:
      return unless should_calculate_income_change?(entry_date: entry_date, head_of_household: head_of_household)
      return unless income_at_entry.present?
      income_for_types(
        types: (earned_income_types + non_employment_cash_income_types),
        income_record: income_at_entry
      )
    end

    def calculate_income_at_later_date_earned income_record:,  entry_date:, head_of_household:, report_end:
      return unless should_calculate_income_change?(entry_date: entry_date, head_of_household: head_of_household)
      return unless income_record.present?
      income_for_types(
        types: earned_income_types,
        income_record: income_record
      )
    end

    def calculate_income_at_later_date_non_employment_cash income_record:,  entry_date:, head_of_household:, report_end:
      return unless should_calculate_income_change?(entry_date: entry_date, head_of_household: head_of_household)
      return unless income_record.present?
      income_for_types(
        types: non_employment_cash_income_types,
        income_record: income_record
      )
    end

    def calculate_income_at_later_date_overall income_record:,  entry_date:, head_of_household:, report_end:
      return unless should_calculate_income_change?(entry_date: entry_date, head_of_household: head_of_household)
      return unless income_record.present?
      income_for_types(
        types: (earned_income_types + non_employment_cash_income_types),
        income_record: income_record
      )
    end

    def calculate_income_at_penultimate_earned income_record:,  entry_date:, head_of_household:, report_end:
      return unless should_calculate_income_change?(entry_date: entry_date, head_of_household: head_of_household)
      return unless income_record.present?
      income_for_types(
        types: earned_income_types,
        income_record: income_record
      )
    end

    def calculate_income_at_penultimate_non_employment_cash income_record:,  entry_date:, head_of_household:, report_end:
      return unless should_calculate_income_change?(entry_date: entry_date, head_of_household: head_of_household)
      return unless income_record.present?
      income_for_types(
        types: non_employment_cash_income_types,
        income_record: income_record
      )
    end

    def calculate_income_at_penultimate_overall income_record:,  entry_date:, head_of_household:, report_end:
      return unless should_calculate_income_change?(entry_date: entry_date, head_of_household: head_of_household)
      return unless income_record.present?
      income_for_types(
        types: (earned_income_types + non_employment_cash_income_types),
        income_record: income_record
      )
    end

    # Only calculate this for adults or heads of household who have been enrolled for
    # more than one year since the report end
    def should_calculate_annual_completeness? entry_date:, exit_date:, head_of_household:, report_end:
      return true if (is_adult?(date: entry_date) || head_of_household) && entry_date + 1.years < report_end && (exit_date.blank? || exit_date.present? && entry_date + 1.years < exit_date)
      return false
    end

    # similar to income at exit, but the InformationDate must be within the past year
    def calculate_income_at_annual_earned income_record:,  entry_date:, exit_date:, head_of_household:, report_end:
      return unless should_calculate_annual_completeness?(entry_date: entry_date, exit_date: exit_date, head_of_household: head_of_household, report_end: report_end)
      return unless income_record.present?
      return unless income_record.InformationDate < report_end && income_record.InformationDate + 1.years >= report_end
      income_for_types(
        types: earned_income_types,
        income_record: income_record,
      )
    end

    # similar to income at exit, but the InformationDate must be within the past year
    def calculate_income_at_annual_non_employment_cash income_record:,  entry_date:, exit_date:, head_of_household:, report_end:
      return unless should_calculate_annual_completeness?(entry_date: entry_date, exit_date: exit_date, head_of_household: head_of_household, report_end: report_end)
      return unless income_record.present?
      return unless income_record.InformationDate < report_end && income_record.InformationDate + 1.years >= report_end
      income_for_types(
        types: non_employment_cash_income_types,
        income_record: income_record,
      )
    end

    # similar to income at exit, but the InformationDate must be within the past year
    def calculate_income_at_annual_overall income_record:,  entry_date:, exit_date:, head_of_household:, report_end:
      return unless should_calculate_annual_completeness?(entry_date: entry_date, exit_date: exit_date, head_of_household: head_of_household, report_end: report_end)
      return unless income_record.present?
      return unless income_record.InformationDate < report_end && income_record.InformationDate + 1.years >= report_end
      income_for_types(
        types: (earned_income_types + non_employment_cash_income_types),
        income_record: income_record,
      )
    end

    def later_income incomes:, report_end:
      return nil unless incomes.present?
      @later_income ||= incomes.select do |income|
        income.DataCollectionStage.in?([3, 2, 5]) && income.InformationDate.present? && income.InformationDate <= report_end
      end.sort_by(&:InformationDate).last
    end

    def penultimate_income incomes:, report_end:
      return nil unless incomes.present?
      return nil unless incomes.count > 1
      @penultimate_income ||= incomes.select do |income|
        income.InformationDate.present? && income.InformationDate <= report_end
      end.sort_by(&:InformationDate).last(2).first
    end

    def income_for_types types:, income_record:
      return unless income_record.present?
      income = nil
      types.each do |type|
        income_for_type = income_record[type.to_s]
        if income_for_type.present?
          income ||= 0
          income += income_for_type
        end
      end
      # binding.pry if income_record.IncomeFromAnySource == 1
      return income
    end

    def earned_income_types
      @earned_income_types ||= [
        :EarnedAmount,
      ]
    end

    def non_employment_cash_income_types
      @non_employment_cash_income_types ||= [
        :UnemploymentAmount,
        :SSIAmount,
        :SSDIAmount,
        :VADisabilityServiceAmount,
        :VADisabilityNonServiceAmount,
        :PrivateDisabilityAmount,
        :WorkersCompAmount,
        :TANFAmount,
        :GAAmount,
        :SocSecRetirementAmount,
        :PensionAmount,
        :ChildSupportAmount,
        :AlimonyAmount,
        :OtherIncomeAmount
      ]
    end

    def calculate_days_to_move_in_date entry_date:, move_in_date:
      return nil unless move_in_date.present?
      (move_in_date - entry_date).to_i
    end

    def calculate_days_in_ph_before_move_in_date project_type:, entry_date:, move_in_date:, report_end:
      return nil unless project_type.in?(GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph])
      # if we don't have a move-in-date use the earlier of report_end and today.
      # if the report_end is before the move-in-date use the report end
      # if for some odd reason we are running this with a future report_end, use today
      end_date = [move_in_date, report_end, Date.current].compact.min
      (end_date - entry_date).to_i
    end

    def calculate_incorrect_household_type household_type:, project:
      return false if project.serves_families? && project.serves_individuals?
      return false if household_type == 'individual' && project.serves_individuals?
      return false if household_type == 'family' && project.serves_families?
      return true
    end
  end
end
