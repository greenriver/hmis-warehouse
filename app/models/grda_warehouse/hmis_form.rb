###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::HmisForm < GrdaWarehouseBase
  include ActionView::Helpers
  include Eto::PathwaysAnswers
  include Eto::CovidAnswers
  include RailsDrivers::Extensions
  belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', optional: true
  has_one :destination_client, through: :client
  belongs_to :hmis_assessment, class_name: 'GrdaWarehouse::HMIS::Assessment', primary_key: [:assessment_id, :site_id, :data_source_id], foreign_key: [:assessment_id, :site_id, :data_source_id], optional: true
  serialize :api_response, Hash
  serialize :answers, Hash

  delegate :details_in_window_with_release?, to: :hmis_assessment

  scope :viewable_by, -> (user) do
    # FIXME: we need a site_id to ProjectID lookup table
    none
  end

  scope :hud_assessment, -> do
    joins(:hmis_assessment).merge(GrdaWarehouse::HMIS::Assessment.hud_assessment)
  end

  scope :triage, -> do
    joins(:hmis_assessment).merge(GrdaWarehouse::HMIS::Assessment.triage_assessment)
  end

  scope :vispdat, -> do
    joins(:hmis_assessment).merge(GrdaWarehouse::HMIS::Assessment.vispdat)
  end

  scope :pathways, -> do
    joins(:hmis_assessment).merge(GrdaWarehouse::HMIS::Assessment.pathways)
  end

  scope :covid_19_impact_assessments, -> do
    joins(:hmis_assessment).merge(GrdaWarehouse::HMIS::Assessment.covid_19_impact_assessments)
  end

  scope :interested_in_some_rrh, -> do
    where.not(rrh_desired: nil).
    or(
      where.not(rrh_th_desired: nil)
    ).
    or(
      where.not(dv_rrh_aggregate: nil)
    ).
    or(
      where.not(youth_rrh_desired: nil)
    ).
    or(
      where.not(adult_rrh_desired: nil)
    ).
    or(
      where.not(youth_rrh_aggregate: nil)
    ).
    or(
      where.not(veteran_rrh_desired: nil)
    )
  end

  scope :confidential, -> do
    joins(:hmis_assessment).merge(GrdaWarehouse::HMIS::Assessment.confidential)
  end

  scope :non_confidential, -> do
    joins(:hmis_assessment).merge(GrdaWarehouse::HMIS::Assessment.non_confidential)
  end

  scope :window, -> do
    joins(:hmis_assessment, :client).merge(GrdaWarehouse::HMIS::Assessment.window)
  end

  scope :health, -> do
    joins(:hmis_assessment).merge(GrdaWarehouse::HMIS::Assessment.health)
  end

  scope :window_with_details, -> do
    window.merge(GrdaWarehouse::HMIS::Assessment.window_with_details)
  end

  scope :self_sufficiency, -> do
    joins(:hmis_assessment).merge(GrdaWarehouse::HMIS::Assessment.ssm)
  end

  scope :collected, -> do
    where.not(collected_at: nil)
  end

  scope :case_management_notes, -> do
    joins(:hmis_assessment).merge(GrdaWarehouse::HMIS::Assessment.health_case_note)
  end

  scope :has_qualifying_activities, -> do
    joins(:hmis_assessment).merge(GrdaWarehouse::HMIS::Assessment.health_has_qualifying_activities)
  end

  scope :has_unprocessed_quailifying_activities, -> do
    processed_ids = Health::QualifyingActivity.where(source_type: self.name).
      distinct.
      pluck(:source_id)
    has_qualifying_activities.where.not(id: processed_ids)
  end

  scope :health_touch_points, -> do
    health_assessments = joins(:hmis_assessment).merge(GrdaWarehouse::HMIS::Assessment.health).distinct.pluck(:id)
    sdh_assessments = where(arel_table[:collection_location].matches('Social Determinants of Health%')).pluck(:id)
    where(id: health_assessments + sdh_assessments)
  end

  scope :rrh_assessment, -> do
    where(name: rrh_assessment_name)
  end

  scope :newest_first, -> do
    order(collected_at: :desc)
  end

  scope :oldest_first, -> do
    order(collected_at: :asc)
  end

  scope :with_staff_contact, -> do
    where.not(staff_email: nil)
  end

  scope :with_housing_status, -> do
    where.not(housing_status: [nil, '']).where.not(collected_at: nil)
  end

  scope :within_range, -> (range) do
    where(collected_at: range)
  end

  scope :vispdat_pregnant, -> do
    where(vispdat_pregnant: 'Yes')
  end

  def self.rrh_columns
    [
      :rrh_desired,
      :rrh_th_desired,
      :dv_rrh_aggregate,
      :youth_rrh_desired,
      :adult_rrh_desired,
      :youth_rrh_aggregate,
      :veteran_rrh_desired,
    ]
  end

  def self.set_missing_vispdat_scores
    # Process in batches, but ensure the batches occur such that the most recently completed are last
    # Fetch the ids, in order of unprocessed vispdat records
    ids = vispdat.oldest_first.
      where(
        arel_table[:vispdat_total_score].eq(nil).
        or(arel_table[:collected_at].gt(arel_table[:vispdat_score_updated_at]))
      ).pluck(:id)
    # loop over those records in batches of 100
    ids.each_slice(100) do |batch|
      # fetch the batch, in order
      vispdat.where(id: batch).preload(:destination_client).oldest_first.to_a.each do |hmis_form|
        next unless hmis_form.destination_client.present?

        hmis_form.vispdat_total_score = hmis_form.vispdat_score_total
        hmis_form.vispdat_family_score = hmis_form.vispdat_score_family
        hmis_form.vispdat_youth_score = hmis_form.vispdat_score_youth
        hmis_form.vispdat_months_homeless = hmis_form.vispdat_homeless_months
        hmis_form.vispdat_times_homeless = hmis_form.vispdat_homeless_times
        hmis_form.vispdat_score_updated_at = Time.now

        if hmis_form.changed? && hmis_form&.destination_client
          hmis_form.save
          hmis_form.destination_client.update(vispdat_prioritization_days_homeless: hmis_form.vispdat_days_homeless)
        end
      end
    end
  end

  def self.set_missing_vispdat_pregnancies
    # Process in batches, but ensure the batches occur such that the most recently completed are last
    # Fetch the ids, in order of unprocessed vispdat records
    ids = vispdat.oldest_first.
      where(
        arel_table[:vispdat_pregnant].eq(nil).
          or(arel_table[:collected_at].gt(arel_table[:vispdat_pregnant_updated_at]))
      ).pluck(:id)
    # loop over those records in batches of 100
    ids.each_slice(100) do |batch|
      # fetch the batch, in order
      vispdat.where(id: batch).preload(:destination_client).oldest_first.to_a.each do |hmis_form|
        next unless hmis_form.destination_client.present?

        hmis_form.vispdat_pregnant = hmis_form.vispdat_pregnancy_status
        hmis_form.vispdat_pregnant_updated_at = Time.now

        if hmis_form.changed?
          hmis_form.save
        end
      end
    end
  end

  def self.set_missing_physical_disabilities
    # Process in batches, but ensure the batches occur such that the most recently completed are last
    # Fetch the ids, in order of unprocessed vispdat records
    ids = vispdat.oldest_first.
      where(
        arel_table[:vispdat_physical_disability_answer].eq(nil).
          or(arel_table[:collected_at].gt(arel_table[:vispdat_physical_disability_updated_at]))
      ).pluck(:id)

    # loop over those records in batches of 100
    ids.each_slice(100) do |batch|
      # fetch the batch, in order
      vispdat.where(id: batch).preload(:destination_client).oldest_first.to_a.each do |hmis_form|
        next unless hmis_form.destination_client.present?

        hmis_form.vispdat_physical_disability_answer = hmis_form.vispdat_physical_disability
        hmis_form.vispdat_physical_disability_updated_at = Time.now

        if hmis_form.changed?
          hmis_form.save
        end
      end
    end
  end

  def self.set_missing_housing_status
    ids = case_management_notes.where(
      arel_table[:housing_status].eq(nil).
        or(arel_table[:collected_at].gt(arel_table[:housing_status_updated_at]))
      ).pluck(:id)
    ids.each_slice(100) do |batch|
      case_management_notes.where(id: batch).preload(:destination_client).oldest_first.to_a.each do |hmis_form|
        next unless hmis_form.destination_client.present?

        hmis_form.housing_status = hmis_form.housing_status_answer
        hmis_form.housing_status_updated_at = Time.current

        hmis_form.save if hmis_form.changed?
      end
    end
  end

  # Pre-check part of a family if the client has a family score > 2
  # or if they are under 60 and have a score = 1
  # Only check the box if the most-recent VI-SPDAT qualifies
  def self.set_part_of_a_family
    family_destination_client_ids = Set.new
    # keyed on destination client id
    vispdats = {}
    GrdaWarehouse::HmisForm.vispdat.joins(client: :warehouse_client_source).order(collected_at: :desc).
      pluck(:destination_id, :client_id, :vispdat_family_score, :collected_at).
      each do |client_id, source_client_id, vispdat_family_score, collected_at|
        vispdats[client_id] ||= {
          source_client_id: source_client_id,
          score: vispdat_family_score,
          collected_at: collected_at,
        }
      end

    potential_destination_clients = GrdaWarehouse::Hud::Client.where(id: vispdats.keys).
      select(:id, :DOB).
      index_by(&:id)
    vispdats.each do |client_id, score|
      # anyone with a score of 0 or nil in the most-recent vi-spdat is excluded
      next if score[:score].blank? || score[:score].zero?

      # anyone with the most-recent score > 2 is included
      if score[:score].present? && score[:score] > 2
        family_destination_client_ids << client_id
        next
      end

      # anyone who is under 60 and has a non-zero score in the most-recent vi-spdat
      client = potential_destination_clients[client_id]
      next unless client

      collected_at = score[:collected_at]
      age = client.age_on(collected_at.to_date)
      next if age.blank? || age >= 60

      family_destination_client_ids << client_id
    end

    GrdaWarehouse::Hud::Client.where(id: family_destination_client_ids).
      update_all(family_member: true)
  end

  def self.set_pathways_results(force_all: false)
    # find anyone who's never been processed or who has been updated since we last made
    # note of changes
    ids = if force_all
      pathways.pluck(:id)
    else
      pathways.where(
        arel_table[:pathways_updated_at].eq(nil).
          or(arel_table[:collected_at].gt(arel_table[:pathways_updated_at]))
        ).pluck(:id)
    end
    ids.each_slice(100) do |batch|
      pathways.where(id: batch).preload(:destination_client).oldest_first.to_a.each do |hmis_form|
        next unless hmis_form.destination_client.present?

        hmis_form.assessment_completed_on = hmis_form.assessment_completed_on_answer
        hmis_form.assessment_score = hmis_form.assessment_score_answer
        hmis_form.rrh_desired = hmis_form.rrh_desired_answer
        hmis_form.youth_rrh_desired = hmis_form.youth_rrh_desired_answer
        hmis_form.income_maximization_assistance_requested = hmis_form.income_maximization_assistance_requested_answer
        hmis_form.income_total_annual = hmis_form.income_total_annual_answer
        hmis_form.pending_subsidized_housing_placement = hmis_form.pending_subsidized_housing_placement_answer
        hmis_form.domestic_violence = hmis_form.domestic_violence_answer
        hmis_form.interested_in_set_asides = hmis_form.interested_in_set_asides_answer
        hmis_form.required_number_of_bedrooms = hmis_form.required_number_of_bedrooms_answer
        hmis_form.required_minimum_occupancy = hmis_form.required_minimum_occupancy_answer
        hmis_form.requires_wheelchair_accessibility = hmis_form.requires_wheelchair_accessibility_answer
        hmis_form.requires_elevator_access = hmis_form.requires_elevator_access_answer
        hmis_form.youth_rrh_aggregate = hmis_form.youth_rrh_aggregate_answer
        hmis_form.dv_rrh_aggregate = hmis_form.dv_rrh_aggregate_answer
        hmis_form.rrh_th_desired = hmis_form.rrh_th_desired_answer
        hmis_form.sro_ok = hmis_form.sro_ok_answer
        hmis_form.other_accessibility = hmis_form.other_accessibility_answer
        hmis_form.disabled_housing = hmis_form.disabled_housing_answer
        hmis_form.evicted = hmis_form.evicted_answer
        hmis_form.ssvf_eligible = hmis_form.ssvf_eligible_answer
        hmis_form.neighborhood_interests = hmis_form.neighborhood_interests_answer
        hmis_form.staff_email = hmis_form.staff_email_answer
        hmis_form.client_phones = hmis_form.client_phones_answer
        hmis_form.client_emails = hmis_form.client_emails_answer
        hmis_form.client_shelters = hmis_form.client_shelters_answer
        hmis_form.client_case_managers = hmis_form.client_case_managers_answer
        hmis_form.client_day_shelters = hmis_form.client_day_shelters_answer
        hmis_form.client_night_shelters = hmis_form.client_night_shelters_answer
        # hmis_form.pathways_dv_score_answer
        # hmis_form.pathways_length_of_time_homeless_score_answer

        hmis_form.pathways_updated_at = Time.current

        hmis_form.save if hmis_form.changed?
      end
    end
  end

  def self.covid_19_impact_assessment_results(force_all: false)
    # find anyone who's never been processed or who has been updated since we last made
    # note of changes
    ids = if force_all
      covid_19_impact_assessments.pluck(:id)
    else
      covid_19_impact_assessments.where(
        arel_table[:covid_impact_updated_at].eq(nil).
          or(arel_table[:collected_at].gt(arel_table[:covid_impact_updated_at]))
        ).pluck(:id)
    end
    ids.each_slice(100) do |batch|
      covid_19_impact_assessments.where(id: batch).preload(:destination_client).oldest_first.to_a.each do |hmis_form|
        next unless hmis_form.destination_client.present?

        hmis_form.number_of_bedrooms = hmis_form.number_of_bedrooms_answer
        hmis_form.subsidy_months = hmis_form.subsidy_months_answer
        hmis_form.monthly_rent_total = hmis_form.monthly_rent_total_answer
        hmis_form.total_subsidy = hmis_form.total_subsidy_answer
        hmis_form.percent_ami = hmis_form.percent_ami_answer
        hmis_form.household_type = hmis_form.household_type_answer
        hmis_form.household_size = hmis_form.household_size_answer
        hmis_form.covid_impact_updated_at = Time.current

        hmis_form.save if hmis_form.changed?
      end
    end
  end

  def primary_language
    return 'Unknown' unless answers.present?
    answers = self.answers.with_indifferent_access
    answers[:sections].each do |m|
      m[:questions].each do |m|
        return m[:answer] if m[:answer].present? && m[:question] == 'A-2. Primary Language Spoken'
      end
    end
    'Unknown'
  end

  def triage?
    name == 'Triage Assessment'
  end

  def veteran_score
    return nil unless name&.downcase == self.class.rrh_assessment_name.downcase
    relevant_section = answers[:sections].select do |section|
      section[:section_title].downcase.include?('assessment score') && section[:questions].present?
    end&.first
    return nil unless relevant_section.present?

    relevant_question = relevant_section[:questions].select do |question|
      question[:question].downcase.starts_with?('veterans score')
    end&.first.try(:[], :answer)
    relevant_question
  end

  def rrh_desired?
    return false unless name&.downcase == self.class.rrh_assessment_name.downcase
    relevant_section = answers[:sections].select do |section|
      section[:section_title].downcase == 'section 8: housing resource assessment'.downcase
    end&.first
    return false unless relevant_section.present?
    relevant_question = relevant_section[:questions].select do |question|
      question[:question].downcase.starts_with?('would you like to be considered for rapid re-housing')
    end&.first.try(:[], :answer)
    relevant_question&.downcase == 'yes' || false
  end

  def rrh_assessment_score
    return nil unless name&.downcase == self.class.rrh_assessment_name.downcase
    relevant_section = answers[:sections].select do |section|
      section[:section_title].downcase.include?('assessment score') && section[:questions].present?
    end&.first
    return nil unless relevant_section.present?

    relevant_question = relevant_section[:questions].select do |question|
      question[:question].downcase == 'boston coordinated entry assessment total score'
    end&.first.try(:[], :answer)
    relevant_question
  end

  def youth_rrh_desired?
    return false unless name&.downcase == self.class.rrh_assessment_name.downcase
    relevant_section = answers[:sections].select do |section|
      section[:section_title].downcase == 'section 8: housing resource assessment'.downcase
    end&.first
    return false unless relevant_section.present?

    relevant_question = relevant_section[:questions].select do |question|
      question[:question].downcase.include? "it looks like you have a head of household who is 24 years old"
    end&.first.try(:[], :answer)
    relevant_question&.downcase&.include?('youth') || false
  end

  def income_maximization_assistance_requested?
    return false unless name&.downcase == self.class.rrh_assessment_name.downcase
    relevant_section = answers[:sections].select do |section|
      section[:section_title].downcase == 'section 8: housing resource assessment'.downcase
    end&.first
    return false unless relevant_section.present?

    relevant_question = relevant_section[:questions].select do |question|
      question[:question].downcase.include? "increase and maximize all income sources"
    end&.first.try(:[], :answer)
    relevant_question&.downcase == 'yes' || false
  end

  def rrh_contact_info
    return nil unless name&.downcase == self.class.rrh_assessment_name.downcase
    return nil unless income_maximization_assistance_requested?
    relevant_section = answers[:sections].select do |section|
      section[:section_title].downcase == 'next steps and contact information' && section[:questions].present?
    end&.first
    return nil unless relevant_section.present?
    relevant_section[:questions].map do |question|
      "<div><strong>#{question[:question]}</strong> #{question[:answer]}</div>"
    end.join(' ')
  end

  def vispdat_score_total
    relevant_section = answers[:sections].select do |section|
      section[:section_title].downcase.include?('scoring') && section[:questions].present?
    end&.first
    return nil unless relevant_section.present?

    relevant_question = relevant_section[:questions].select do |question|
      question[:question].downcase.include?('total score')
    end&.first.try(:[], :answer)
    relevant_question
  end

  def vispdat_score_family
    relevant_section = answers[:sections].select do |section|
      section[:section_title].downcase.include?('family score') && section[:questions].present?
    end&.first
    return nil unless relevant_section.present?

    relevant_question = relevant_section[:questions].select do |question|
      question[:question].downcase.include?('total family score')
    end&.first.try(:[], :answer)
    relevant_question
  end

  def vispdat_score_youth
    relevant_section = answers[:sections].select do |section|
      section[:section_title].downcase.include?('youth score') && section[:questions].present?
    end&.first
    return nil unless relevant_section.present?

    relevant_question = relevant_section[:questions].select do |question|
      question[:question].downcase.include?('total score')
    end&.first.try(:[], :answer)
    relevant_question
  end

  def vispdat_homeless_months
    relevant_section = answers[:sections].select do |section|
      section[:section_title].downcase.include?('history of housing and homelessness') && section[:questions].present?
    end&.first
    return nil unless relevant_section.present?

    relevant_question = relevant_section[:questions].select do |question|
      question[:question].downcase.starts_with?('2. how long has it been since you lived in permanent stable housing? (months)')
    end&.first.try(:[], :answer)
    relevant_question
  end

  def vispdat_homeless_times
    relevant_section = answers[:sections].select do |section|
      section[:section_title].downcase.include?('history of housing and homelessness') && section[:questions].present?
    end&.first
    return nil unless relevant_section.present?

    relevant_question = relevant_section[:questions].select do |question|
      question[:question].downcase.starts_with?('3. in the last three years, how many times have you been homeless?')
    end&.first.try(:[], :answer)
    relevant_question
  end

  def vispdat_pregnancy_status
    health_sections = answers[:sections].select do |section|
      section[:section_title].downcase.include?('wellness') && section[:questions].present?
    end.compact
    return nil unless health_sections.present?

    health_sections.map do |relevant_section|
      relevant_section[:questions].select do |question|
        question[:question].downcase.include?('currently pregnant')
      end&.first.try(:[], :answer)
    end.compact.detect(&:presence)
  end

  def vispdat_physical_disability
    health_sections = answers[:sections].select do |section|
      section[:section_title].downcase.include?('wellness') && section[:questions].present?
    end.compact
    return nil unless health_sections.present?

    health_sections.map do |relevant_section|
      relevant_section[:questions].select do |question|
        question[:question].downcase.include?('issues with your liver')
      end&.first.try(:[], :answer)
    end.compact.detect(&:presence)
  end

  def vispdat_days_homeless
    return 0 unless vispdat_months_homeless.present?
    vispdat_months_homeless * 30
  end

  def housing_status_answer
    relevant_section = answers[:sections].select do |section|
      section[:section_title].downcase.include?('first page') && section[:questions].present?
    end&.first
    return nil unless relevant_section.present?

    relevant_question = relevant_section[:questions].select do |question|
      question[:question].downcase.starts_with?('housing status')
    end&.first.try(:[], :answer)
    relevant_question
  end

  def qualifying_activities
    Health::QualifyingActivity.where(source_type: self.class.name, source_id: id)
  end

  def has_eto_qualifying_activities?
    name.in?(['Case Management Daily Note']) && eto_qualifying_activities.any?
  end

  def eto_qualifying_activities
    @eto_qualifying_activities ||= answers[:sections].select{|m| m[:section_title].include?('Qualifying Activity') && m[:questions].first[:answer].present?}
  end

  def create_qualifying_activity!
    return true unless GrdaWarehouse::Config.get(:healthcare_available)
    # Only some have qualifying activities
    return true unless has_eto_qualifying_activities?
    # prevent duplication creation
    return true if Health::QualifyingActivity.where(source_type: self.class.name, source_id: id).exists?

    return true unless client&.destination_client.present?
    # Don't add qualifying activities if we can't find a patient with a referral
    return true unless patient = Health::Patient.joins(:patient_referral).where(client_id: client.destination_client.id)&.first

    user = User.setup_system_user()
    Health::QualifyingActivity.transaction do
      eto_qualifying_activities.each do |qa|
        activity = {
          mode_of_contact: care_hub_mode_key(qa),
          reached_client: care_hub_reached_key(qa),
          reached_client_collateral_contact: collateral_contact(qa),
          activity: care_hub_activity_key(qa),
          follow_up: follow_up(qa),
        }
        next unless activity[:follow_up] && activity[:mode_of_contact] && activity[:activity] && activity[:reached_client]
        qualifying_activity = Health::QualifyingActivity.new(
          patient_id: patient.id,
          date_of_activity: collected_at.to_date,
          user_full_name: staff,
          mode_of_contact: activity[:mode_of_contact],
          reached_client: activity[:reached_client],
          reached_client_collateral_contact: activity[:reached_client_collateral_contact],
          activity: activity[:activity],
          follow_up: activity[:follow_up],
          source_type: self.class.name,
          source_id: id,
          user_id: user.id
        )
        qualifying_activity.save if qualifying_activity.valid?
      end
    end
  end

  def follow_up qa
    qa[:questions].select{|m| m[:question] == 'Notes and follow-up'}.first.try(:[], :answer)
  end

  def collateral_contact qa
    qa[:questions].select{|m| m[:question] == 'Collateral contact - with whom?'}.first.try(:[], :answer)
  end

  def care_hub_reached_key qa
    @care_hub_client_reached ||= Health::QualifyingActivity.client_reached.map do |k, reached|
      [reached[:title], k]
    end.to_h
    @care_hub_client_reached[clean_reached_title(qa)]
  end

  def clean_reached_title qa
    qa[:questions].select{|m| m[:question] == 'Reached client?'}.first.try(:[], :answer)
  end


  def care_hub_mode_key qa
    @care_hub_modes_of_contact ||= Health::QualifyingActivity.modes_of_contact.map do |k, mode|
      [mode[:title], k]
    end.to_h
    @care_hub_modes_of_contact[clean_mode_title(qa)]
  end

  def clean_mode_title qa
    qa[:questions].select{|m| m[:question] == 'Mode of contact'}.first.try(:[], :answer)
  end

  def care_hub_activity_key qa
    @care_hub_activities ||= Health::QualifyingActivity.activities.map do |k, activity|
      [activity[:title], k]
    end.to_h
    @care_hub_activities[clean_activity_title(qa)]
  end

  def clean_activity_title qa
    activity = qa[:questions].select{|m| m[:question] == 'Which of these activities took place?'}.first.try(:[], :answer)
    case activity&.downcase
    when 'comprehensive assessment', 'health assessment'
      'Comprehensive Health Assessment'
    else
      activity
    end
  end

  def contains_contact_info?
    client_phones.present? || client_emails.present?
  end

  def value_for_rrh_cas_tag
    rrh_assessment_score
  end

  def encounter_report_details
    {
      source: 'ETO',
      housing_status: housing_status,
    }
  end

  # a display order we use on the client dashboard
  def <=>(other)
    if triage? ^ other.triage?
      return triage? ? -1 : 1
    end
    c = assessment_type <=> other.assessment_type
    c = other.collected_at <=> collected_at if c == 0
    c
  end

  def self.rrh_assessment_name
    GrdaWarehouse::HMIS::Assessment.rrh_assessment&.first&.name
  end

  def section_starts_with(string)
    relevant_section = answers[:sections].select do |section|
      section[:section_title].downcase.starts_with?(string.downcase)
    end&.first
    return false unless relevant_section.present?

    relevant_section
  end

  #
  # Finds the first relevant answer where the question includes the string.
  #
  # @param section [Hash] section part of the HmisForm answers column
  # @param question_string [String] question_string used to identify a relevant question
  #
  # @return [String] the answer provided
  #
  def answer_from_section(section, question_string)
    return unless section
    section[:questions].select do |question|
      question[:question].downcase.include?(question_string.downcase)
    end&.first.try(:[], :answer)
  end
end
