###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class GrdaWarehouse::HmisForm < GrdaWarehouseBase
  include ActionView::Helpers
  belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name
  has_one :destination_client, through: :client
  belongs_to :hmis_assessment, class_name: GrdaWarehouse::HMIS::Assessment.name, primary_key: [:assessment_id, :site_id, :data_source_id], foreign_key: [:assessment_id, :site_id, :data_source_id]
  serialize :api_response, Hash
  serialize :answers, Hash

  delegate :details_in_window_with_release?, to: :hmis_assessment

  scope :hud_assessment, -> { where name: 'HUD Assessment (Entry/Update/Annual/Exit)' }
  scope :triage, -> { where name: 'Triage Assessment'}
  scope :vispdat, -> do
    where(name: 'VI-SPDAT v2')
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
    window.merge(GrdaWarehouse::HMIS::Assessment.window)
  end

  scope :self_sufficiency, -> do
    where(name: 'Self-Sufficiency Matrix')
  end

  scope :collected, -> do
    where.not(collected_at: nil)
  end

  scope :case_management_notes, -> do
    where(name: ['SDH Case Management Note', 'Case Management Daily Note'])
  end

  scope :has_qualifying_activities, -> do
    where(name: ['Case Management Daily Note'])
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
        hmis_form.vispdat_months_homeless = hmis_form.vispdat_homless_months
        hmis_form.vispdat_times_homeless = hmis_form.vispdat_homless_times
        hmis_form.vispdat_score_updated_at = Time.now
        if hmis_form.changed?
          hmis_form.save
          hmis_form.destination_client.update(vispdat_prioritization_days_homeless: hmis_form.vispdat_days_homeless)
        end
      end
    end

  end

  # Pre-check part of a family if the client has a family score and are < 60
  # or if they are 60+ and have a score > 1
  def self.set_part_of_a_family
    # update any we don't need to check for age
    source_client_ids = vispdat.where(vispdat_family_score: (2..Float::INFINITY)).
      distinct.
      pluck(:client_id)
    destination_client_ids = GrdaWarehouse::WarehouseClient.
      where(source_id: source_client_ids).
      distinct.
      pluck(:destination_id)
    GrdaWarehouse::Hud::Client.where(id: destination_client_ids, family_member: false).
      update_all(family_member: true)

    # For anyone with a score of one, only update those who are < 60
    source_clients = vispdat.where(vispdat_family_score: 1).
      distinct.
      pluck(:client_id, :collected_at).to_h

    warehouse_clients = GrdaWarehouse::WarehouseClient.
      where(source_id: source_clients.keys).
      distinct.
      pluck(:destination_id, :source_id).to_h

    GrdaWarehouse::Hud::Client.where(id: warehouse_clients.keys).
      find_each do |client|
        source_client_id = warehouse_clients[client.id]
        collected_at = source_clients[source_client_id]
        age = client.age_on(collected_at.to_date)
        if age.blank? || age < 60
          client.update(family_member: true) unless client.family_member
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

  def vispdat_homless_months
    relevant_section = answers[:sections].select do |section|
      section[:section_title].downcase.include?('history of housing and homelessness') && section[:questions].present?
    end&.first
    return nil unless relevant_section.present?

    relevant_question = relevant_section[:questions].select do |question|
      question[:question].downcase.starts_with?('2. how long has it been since you lived in permanent stable housing? (months)')
    end&.first.try(:[], :answer)
    relevant_question
  end

  def vispdat_homless_times
    relevant_section = answers[:sections].select do |section|
      section[:section_title].downcase.include?('history of housing and homelessness') && section[:questions].present?
    end&.first
    return nil unless relevant_section.present?

    relevant_question = relevant_section[:questions].select do |question|
      question[:question].downcase.starts_with?('3. in the last three years, how many times have you been homeless?')
    end&.first.try(:[], :answer)
    relevant_question
  end

  def vispdat_days_homeless
    return 0 unless vispdat_months_homeless.present?
    vispdat_months_homeless * 30
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

  def value_for_rrh_cas_tag
    rrh_assessment_score
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
    'Boston CoC Coordinated Entry Assessment'
  end
end