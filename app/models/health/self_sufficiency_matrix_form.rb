###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class SelfSufficiencyMatrixForm < HealthBase
    phi_patient :patient_id

    phi_attr :user_id, Phi::SmallPopulation
    phi_attr :point_completed, Phi::FreeText
    # phi_attr :housing_score,
    phi_attr :housing_notes, Phi::FreeText
    # phi_attr :income_score,
    phi_attr :income_notes, Phi::FreeText
    # phi_attr :benefits_score,
    phi_attr :benefits_notes, Phi::FreeText
    # phi_attr :disabilities_score,
    phi_attr :disabilities_notes, Phi::FreeText
    # phi_attr :food_score,
    phi_attr :food_notes, Phi::FreeText
    # phi_attr :employment_score,
    phi_attr :employment_notes, Phi::FreeText
    # phi_attr :education_score,
    phi_attr :education_notes, Phi::FreeText
    # phi_attr :mobility_score,
    phi_attr :mobility_notes, Phi::FreeText
    # phi_attr :life_score,
    phi_attr :life_notes, Phi::FreeText
    # phi_attr :healthcare_score,
    phi_attr :healthcare_notes, Phi::FreeText
    # phi_attr :physical_health_score,
    phi_attr :physical_health_notes, Phi::FreeText
    # phi_attr :mental_health_score,
    phi_attr :mental_health_notes, Phi::FreeText
    # phi_attr :substance_abuse_score,
    phi_attr :substance_abuse_notes, Phi::FreeText
    # phi_attr :criminal_score,
    phi_attr :criminal_notes, Phi::FreeText
    # phi_attr :legal_score,
    phi_attr :legal_notes, Phi::FreeText
    # phi_attr :safety_score,
    phi_attr :safety_notes, Phi::FreeText
    # phi_attr :risk_score,
    phi_attr :risk_notes, Phi::FreeText
    # phi_attr :family_score,
    phi_attr :family_notes, Phi::FreeText
    # phi_attr :community_score,
    phi_attr :community_notes, Phi::FreeText
    # phi_attr :time_score,
    phi_attr :time_notes, Phi::FreeText
    phi_attr :completed_at, Phi::Date
    phi_attr :collection_location, Phi::SmallPopulation
    phi_attr :health_file_id, Phi::OtherIdentifier

    belongs_to :patient, optional: true
    belongs_to :user, optional: true

    has_one :health_file, class_name: 'Health::SsmFile', foreign_key: :parent_id, dependent: :destroy
    include HealthFiles

    # first completed SSM form for each patient
    scope :first_completed, -> do
      where(
        id: order(
          :patient_id,
          completed_at: :asc,
        ).group(:patient_id, :id).distinct_on(:patient_id).select(:id),
      )
    end

    # most recent completed SSM form for each patient
    scope :latest_completed, -> do
      where(
        id: order(
          :patient_id,
          completed_at: :desc,
        ).group(:patient_id, :id).distinct_on(:patient_id).select(:id),
      )
    end

    scope :in_progress, -> { where(completed_at: nil) }
    scope :completed, -> { where.not completed_at: nil }
    scope :incomplete, -> { where(completed_at: nil) }
    scope :recent, -> { order(created_at: :desc).limit(1) }

    scope :active, -> do
      completed.where(arel_table[:completed_at].gteq(1.years.ago))
    end
    scope :expired, -> do
      where(arel_table[:completed_at].lt(1.years.ago))
    end
    scope :expiring_soon, -> do
      where(completed_at: 1.years.ago..11.months.ago)
    end
    scope :recently_signed, -> do
      active.where(arel_table[:completed_at].gteq(1.months.ago))
    end

    scope :completed_within_range, ->(range) do
      where(completed_at: range)
    end
    scope :during_current_enrollment, -> do
      where(arel_table[:completed_at].gteq(hpr_t[:enrollment_start_date])).
        joins(patient: :patient_referral)
    end

    scope :during_contributing_enrollments, -> do
      where(arel_table[:completed_at].gteq(hpr_t[:enrollment_start_date])).
        joins(patient: :patient_referrals).
        merge(Health::PatientReferral.contributing)
    end

    scope :allowed_for_engagement, -> do
      joins(patient: :patient_referrals).
        merge(
          Health::PatientReferral.contributing.
            where(
              hpr_t[:enrollment_start_date].lt(Arel.sql("#{arel_table[:completed_at].to_sql} + INTERVAL '1 year'")),
            ),
        )
    end

    attr_accessor :file

    SECTIONS = {
      housing: {
        0 => 'Not enough information at this time OR not applicable',
        1 => 'Homeless or threatened with eviction. (in-crisis)',
        2 => 'In transitional, temporary or substandard housing; and/or current rent/mortgage payment is unaffordable (over 30% of income). (vulnerable)',
        3 => 'In stable housing that is safe but only marginally adequate. (safe)',
        4 => 'Household is in safe, adequate subsidized housing. (stable)',
        5 => 'Household is safe, adequate, unsubsidized housing. (thriving)',
      },
      income: {
        0 => 'Not enough information at this time OR not applicable',
        1 => 'No income. (in-crisis)',
        2 => 'Inadequate income and/or spontaneous or inappropriate spending. (vulnerable)',
        3 => 'Can meet basic needs with subsidy; appropriate spending. (safe)',
        4 => 'Can meet basic needs and manage debt without assistance. (stable)',
        5 => 'Income is sufficient, well managed; has discretionary income and is able to save. (thriving)',
      },
      benefits: {
        0 => 'Not enough information at this time OR not applicable',
        1 => 'Eligible for benefits but does not currently receive benefits (in-crisis)',
        2 => 'Eligible for benefits but does not currently receive benefits AND is in the application process . (vulnerable)',
        3 => 'Not currently eligible for non-cash social benefits. (safe)',
        4 => 'Currently receiving some non-cash benefits but IS NOT receiving all eligible benefits social benefits. (stable)',
        5 => 'Currently receiving ALL eligible non-cash benefits. (thriving)',
      },
      disabilities: {
        0 => 'Not enough information at this time OR not applicable',
        1 => 'Acute or chronic symptoms affecting housing, employment, social interactions, etc. (in-crisis)',
        2 => 'Sometimes or periodically has acute or chronic symptoms affecting housing, employment, social interactions, etc. (vulnerable)',
        3 => 'Rarely has acute or chronic symptoms affecting housing, employment, social interactions, etc. (safe)',
        4 => 'Asymptomatic – condition controlled by services or medication. (stable)',
        5 => 'No identified disability. (thriving)',
      },
      food: {
        0 => 'Not enough information at this time OR not applicable',
        1 => 'Relies to a significant degree on other sources of free or low-cost food. (in-crisis)',
        2 => 'Household is on food stamps. (vulnerable)',
        3 => 'Can meet basic food needs, but requires occasional assistance. (safe)',
        4 => 'Can meet basic food needs without assistance. (stable)',
        5 => 'Can choose to purchase any food household desires. (thriving)',
      },
      employment: {
        0 => 'Not enough information at this time OR not applicable',
        1 => 'No job. (in-crisis)',
        2 => 'Temporary, part-time or seasonal; inadequate pay, no benefits. (vulnerable)',
        3 => 'Employed full time; inadequate pay; few or no benefits. (safe)',
        4 => 'Employed full time with adequate pay and benefits. (stable)',
        5 => 'Maintains permanent employment with adequate income and benefits. (thriving)',
      },
      education: {
        0 => 'Not enough information at this time OR not applicable',
        1 => 'Literacy problems and/or no high school diploma/GED are serious barriers to employment. (in-crisis)',
        2 => 'Enrolled in literacy and/or GED program and/or has sufficient command of English to where language is not a barrier to employment. (vulnerable)',
        3 => 'Has high school diploma/GED. (safe)',
        4 => 'Needs additional education/training to improve employment situation and/or to resolve literacy problems to where they are able to function effectively in society. (stable)',
        5 => 'Has completed education/training needed to become employable. No literacy problems. Has attended college or has graduated from college. (thriving)',
      },
      mobility: {
        0 => 'Not enough information at this time OR not applicable',
        1 => 'No access to transportation, public or private; may have car that is inoperable. (in-crisis)',
        2 => 'Transportation is available, but unreliable, unpredictable, unaffordable; may have car but no insurance, license, etc. (vulnerable)',
        3 => 'Transportation is available and reliable, but limited and/or inconvenient; drivers are licensed and minimally insured. (safe)',
        4 => 'Transportation is generally accessible to meet basic travel needs. (stable)',
        5 => 'Transportation is readily available and affordable; car is adequately insured. (thriving)',
      },
      life: {
        0 => 'Not enough information at this time OR not applicable',
        1 => 'Unable to meet basic needs such as hygiene, food, activities of daily living. (in-crisis)',
        2 => 'Can meet a few but not all needs of daily living without assistance. (vulnerable)',
        3 => 'Can meet most but not all daily living needs without assistance. (safe)',
        4 => 'Able to meet all basic needs of daily living without assistance. (stable)',
        5 => 'Able to provide beyond basic needs of daily living for self and family. (thriving)',
      },
      healthcare: {
        0 => 'Not enough information at this time OR not applicable',
        1 => 'No medical coverage with immediate need. (in-crisis)',
        2 => 'No medical coverage and great difficulty accessing medical care when needed. Some household members may be in poor health. (vulnerable)',
        3 => 'Some members (e.g. Children) have medical coverage. (safe)',
        4 => 'All members can get medical care when needed, but may strain budget. (stable)',
        5 => 'All members are covered by affordable, adequate health insurance. (thriving)',
      },
      physical_health: {
        0 => 'Not enough information at this time OR not applicable',
        1 => 'Untreated and chronic medical and life-threatening conditions, with inconsistent to minimal follow-up care. (in-crisis)',
        2 => 'Chronic medical conditions, potentially life-threatening, with inconsistent follow up care. (vulnerable)',
        3 => 'Chronic illness generally well managed and attempting to make and keep routine medical and dental appointments (safe)',
        4 => 'No chronic illness or stable chronic illness and maintain good preventive medical and dental care practices. (stable)',
        5 => 'No chronic illness and maintaining proactive preventive medical and dental care practices. (thriving)',
      },
      mental_health: {
        0 => 'Not enough information at this time OR not applicable',
        1 => 'Danger to self or others; recurring suicidal ideation; experiencing severe difficulty in day-to-day life due to psychological problems. (in-crisis)',
        2 => 'Recurrent mental health symptoms that may affect behavior, but not a danger to self/others; persistent problems with functioning due to mental health symptoms. (vulnerable)',
        3 => 'Mild symptoms may be present but are transient; only moderate difficulty in functioning due to mental health problems. (safe)',
        4 => 'Minimal symptoms that are expectable responses to life stressors; only slight impairment in functioning. (stable)',
        5 => 'Symptoms are absent or rare; good or superior functioning in wide range of activities; no more than every day problems or concerns. (thriving)',
      },
      substance_abuse: {
        0 => 'Not enough information at this time OR not applicable',
        1 => 'Meets criteria for severe abuse/dependence; resulting problems so severe that institutional living or hospitalization may be necessary. (in-crisis)',
        2 => 'Meets criteria for dependence; preoccupation with use and/or obtaining drugs/alcohol; withdrawal or withdrawal avoidance behaviors evident; use results in avoidance or neglect of essential life activities. (vulnerable)',
        3 => 'Use within last 6 months; evidence of persistent or recurrent social, occupational, emotional or physical problems related to use (such as disruptive behavior or housing problems); problems have persisted for at least one month. (safe)',
        4 => 'Client has used during last 6 months, but no evidence of persistent or recurrent social, occupational, emotional, or physical problems related to use; no evidence of recurrent dangerous use. (stable)',
        5 => 'No drug use/alcohol abuse in last 6 months or no drug use/alcohol abuse history. (thriving)',
      },
      criminal: {
        0 => 'Not enough information at this time OR not applicable',
        1 => 'Current outstanding tickets or warrants. (in-crisis)',
        2 => 'Current charges/trial pending, noncompliance with probation/parole. (vulnerable)',
        3 => 'Fully compliant with probation/parole terms. (safe)',
        4 => 'Has successfully completed probation/parole within past 12 months, no new charges filed. (stable)',
        5 => 'No active criminal justice involvement in more that 12 months and/or no felony criminal history. (thriving)',
      },
      legal: {
        0 => 'Not enough information at this time OR not applicable',
        1 => 'Has significant legal problem(s) and is not addressing them or does not understand that the problem involve legal issues. (in-crisis)',
        2 => 'Has identified legal problems but is unable to proceed without legal assistance. (vulnerable)',
        3 => 'Has responded to legal issues with appropriate legal assistance. (safe)',
        4 => 'Has legal representation and issues are moving towards resolution. (stable)',
        5 => 'No legal issues or legal issues have been fully resolved. (thriving)',
      },
      safety: {
        0 => 'Not enough information at this time OR not applicable',
        1 => 'Home or residence is not safe; immediate level of lethality is extremely high; possible CPS involvement. (in-crisis)',
        2 => 'Safety is threatened/temporary protection is available; level of lethality is high. (vulnerable)',
        3 => 'Current level of safety is minimally adequate; ongoing safety planning is essential. (safe)',
        4 => 'Environment is safe, however, future of such is uncertain; safety planning is important. (stable)',
        5 => 'Environment is apparently safe and stable. (thriving)',
      },
      risk: {
        0 => 'Not enough information at this time OR not applicable',
        1 => 'Mention of suicidal thoughts with actionable plan and/or mention of violent intentions with actionable plan. (in-crisis)',
        2 => 'History of suicidal attempts or violent criminal history within the last 12 months. Mention of suicidal thoughts without a plan to carry out action and/or mention of violent intentions to harm others without actionable plan. (vulnerable)',
        3 => 'History of suicidal attempts or violent criminal history over 12 months ago. (safe)',
        4 => 'History of suicidal attempts or violent criminal history over 12 months ago with mitigating action steps taken to address behavior. (stable)',
        5 => 'No mention of suicidal thoughts or violent intentions to harm others. (thriving)',
      },
      family: {
        0 => 'Not enough information at this time OR not applicable',
        1 => 'Lack of necessary support from family or friends; abuse (DV, child) is present or there is child neglect. (in-crisis)',
        2 => 'Family/friends may be supportive, but lack ability or resources to help; family members do not relate well with one another; potential for abuse or neglect. (vulnerable)',
        3 => 'Some support from family/friends; family members acknowledge and seek to change negative behaviors; are learning to communicate and support. (safe)',
        4 => 'Strong support from family or friends. Household members support each other’s efforts. (stable)',
        5 => 'Has healthy/expanding support network; household is stable and communication is consistently open. (thriving)',
      },
      community: {
        0 => 'Not enough information at this time OR not applicable',
        1 => 'Not applicable due to crisis situation; in “survival” mode. (in-crisis)',
        2 => 'Socially isolated and/or no social skills and/or lacks motivation to become involved. (vulnerable)',
        3 => 'Lacks knowledge of ways to become involved. (safe)',
        4 => 'Some community involvement (advisory group, support group), but has barriers such as transportation, childcare issues. (stable)',
        5 => 'Actively involved in community. (thriving)',
      },
      time: {
        0 => 'Not enough information at this time OR not applicable',
        1 => 'Unstructured and chaotic day with little to no awareness of appointments or time management (in-crisis)',
        2 => 'Unstructured and chaotic day with some awareness and attendance of appointments (vulnerable)',
        3 => 'Loosely structured day with sporadic awareness and attendance of appointments (safe)',
        4 => 'Structured day with full awareness of appointments but moderate attendance (stable)',
        5 => 'Structured and routine day with full awareness of appointments and attendance. (thriving)',
      },
    }.freeze

    SECTION_TITLES = {
      housing: 'Housing',
      income: 'Income/Money Management',
      benefits: 'Non-Cash Benefits',
      disabilities: 'Disabilities',
      food: 'Food',
      employment: 'Employment',
      education: 'Adult Education/Training',
      mobility: 'Mobility/Transportation',
      life: 'Life Skills & ADLs',
      healthcare: 'Health Care Coverage',
      physical_health: 'Physical Health',
      mental_health: 'Mental Health',
      substance_abuse: 'Substance Abuse',
      criminal: 'Criminal Justice',
      legal: 'Legal Non-criminal',
      safety: 'Safety',
      risk: 'Risk',
      family: 'Family & Social Relationships',
      community: 'Community Involvement',
      time: 'Time Management',
    }.freeze

    SECTION_NOTES = {
      housing: 'Please include the following information in notes: Current address/shelter/location and length of stay at current location.',
      income: 'Please include the following information: Income source and current income amount.',
      benefits: 'Please include the following information: Non-cash benefit type and amount if applicable.',
      disabilities: 'Please include the following information: Brief description of disability type, if applicable, i.e. mental health, substance use, physical, developmental.',
      food: 'Please include the following information: Type of limitation if in-crisis',
      employment: 'Please include the following information: Place of employment, job title, length of current employment',
      education: 'Please include the following information: Notable educational accomplishments.',
      mobility: 'Please include the following information: Any notable information the guest has disclosed about their current transportation situation.',
      life: '',
      healthcare: 'Please include the following information: Health care coverage type, if applicable.',
      physical_health: 'Please include the following information: Notable health concerns, as identified by the guest.',
      mental_health: 'Please include the following information: Notable mental health concerns as noted by guest or as observed.',
      substance_abuse: 'Please include the following information: Substance of choice, approximate usage (frequency and quantity). Brief substance use history.',
      criminal: 'Please include the following information: Recent activity, i.e. criminal charges, incarcerations, warrants, etc.',
      legal: 'Please include the following information: Prominent legal information (including immigration status if applicable)',
      safety: 'Please include the following information: Areas the guest has disclosed that currently influence the level of safety if vulnerable or below.',
      risk: 'Please include the following information: Notable information as it relates to current risk or history of risk.',
      family: 'Please include the following information: Positive family/social relationships that the guest has.',
      community: 'Please include the following information: Information regarding positive community involvement.',
      time: 'Please include the following information: Information regarding how guest spends his/her day. Please include information on time management and any/all particular activities that fill up the day.',
    }.freeze

    SECTION_FOOTERS = {
      # risk: "Work with guest (and other staff as applicable) around safety planning. Complete the CRIT and/or Suicide assessment after safety planning session."
    }.freeze

    # for health_charts (match with old for charts code)
    SSM_QUESTION_TITLE = {
      housing_score: 'Housing ',
      income_score: 'Income/Money Management ',
      benefits_score: 'Non Cash Benefits ',
      disabilities_score: 'Disabilities ',
      food_score: 'Food ',
      employment_score: 'Employment ',
      education_score: 'Adult Education/Training ',
      mobility_score: 'Mobility/Transportation ',
      life_score: 'Life Skills & Ad Ls ',
      healthcare_score: 'Health Care Coverage ',
      physical_health_score: 'Physical Health ',
      mental_health_score: 'Mental Health ',
      substance_abuse_score: 'Substance Use ',
      criminal_score: 'Criminal Justice ',
      legal_score: 'Legal Non Criminal ',
      safety_score: 'Safety ',
      risk_score: 'Risk ',
      family_score: 'Family & Social Relationships ',
      community_score: 'Community Involvement ',
      time_score: 'Daily Time Management ',
    }.freeze

    def self.collection_for section_key
      SECTIONS[section_key].map do |k, v|
        label = "[#{k}] #{v}"
        [
          label,
          k,
        ]
      end
    end

    def option_text_for(section_key, score)
      self.class.collection_for(section_key).to_h.invert[score]
    end

    def completed?
      completed_at.present?
    end

    def claim_submitted?
      qualifying_activities.submitted.exists?
    end

    def editable_by? _editor
      ! claim_submitted?
    end

    def self.point_completed_options
      ['Initial', 'Update', 'Exit']
    end

    SECTIONS.keys.each do |section_key|
      define_method section_key do
        SECTIONS[section_key][send("#{section_key}_score")]
      end
      define_singleton_method "#{section_key}_options" do
        SECTIONS[section_key].invert.to_a
      end
    end

    def total_score
      SECTIONS.keys.inject(0) do |sum, section|
        sum + send("#{section}_score").to_i
      end
    end

    def questions_answered
      questions = SECTIONS.keys.map { |key| send("#{key}_score") }.compact
      questions.delete(0)
      questions.size
    end

    def average_score
      (total_score / questions_answered.to_f).round(1)
    end

    # for health_charts
    def ssm_question_title(attr)
      SSM_QUESTION_TITLE[attr.to_sym]
    end

    def qualifying_activities
      Health::QualifyingActivity.where(source: self, patient: patient)
    end

    def expires_on
      return unless completed_at

      completed_at.to_date + 1.years
    end

    def complete?
      completed_at.present?
    end

    def active?
      completed_at && completed_at >= 1.years.ago
    end

    def encounter_report_details
      {
        source: 'Warehouse',
        housing_status: self.class::SECTIONS[:housing][housing_score],
      }
    end
  end
end
