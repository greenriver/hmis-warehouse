module ClaimsReporting
  class PerformanceReport
    include ActiveModel::Model

    attr_reader :member_roster

    def available_filters
      [
        :age_bucket,
        :gender,
        :race,
        :aco,
      ]
    end

    def filter_options(filter)
      method = "#{filter}_options"
      respond_to?(method) ? send(method) : nil
    end

    # Age Bucket – The age of the member as of the report
    attr_accessor :age_bucket
    def age_bucket_options
      [
        '18-21',
        '22-29',
        '30-39',
        '40-49',
        '50-59',
        '60-64',
      ]
    end

    # Gender – The member’s gender
    attr_accessor :gender
    def gender_options
      # member_roster.group(:sex).count.keys
      ['Female', 'Male']
    end

    # Race – The member’s race
    attr_accessor :race
    def race_options
      # member_roster.group(:race).count.keys
      [
        '',
        'AMERICAN INDIAN OR ALASKAN AMERICAN',
        'ASIAN OR PACIFIC ISLANDER',
        'BLACK-NOT OF HISPANIC ORIGIN',
        'CAUCASIAN',
        'HISPANIC',
        'INTERRACIAL',
        'RACE UNKNOWN',
      ]
    end

    # ACO – The ACO that the member was assigned to at the time the claim is incurred
    attr_accessor :aco
    def aco_options
      member_roster.distinct.pluck(:aco_name).sort
    end

    # Mental Health Diagnosis Category –
    # The mental health diagnosis category represents a group of conditions
    # classified by mental health and substance abuse categories included
    # in the Clinical Classification Software (CCS) available at
    # https://www.hcup-us.ahrq.gov/toolssoftware/ccs/ccsfactsheet.jsp.
    # Schizophrenia
    # Psychoses/Bipolar Disorders (excludes schizophrenia)
    # Depression/Anxiety/Stress Reactions
    # Personality/Impulse Disorder
    # Suicidal Ideation/Attempt
    # Substance Abuse Disorder
    # Other
    attr_accessor :mental_health_diagnosis_category

    # Medical Diagnosis Category – The medical diagnosis category represents a group of conditions classified by medical diagnoses of specific interest in the Clinical Classification Software (CCS). Every member is categorized as having a medical diagnosis based on the claims they incurred - a member can be assigned to more than one category. Possible medical diagnosis categories include:
    # Asthma
    # Chronic Obstructive Pulmonary Disease (COPD)
    # Diabetes
    # Cardiac Disease
    # GI Tract and Biliary Disease
    # Degenerative Spinal Disease/Chronic Pain
    # Obesity
    # Hypertension
    # Hepatitis
    attr_accessor :medical_diagnosis_category

    # High Utilizing Member – ‘High Utilizing’ represents high utilizers (3+ inpatient stays or 5+ emergency room visits throughout their claims experience).
    attr_accessor :high_utilization_member

    # Cohorts of Interest– The user may select members based on their psychiatric inpatient and emergency room utilization history. The user can select the following utilization categories:
    # Cohorts of Interest– 1+ Psychoses Admission: patients that have had at least 1 inpatient admission for psychoses.
    # Cohorts of Interest– 1+ IP Psych Admission: patients that have had at least 1 non-psychoses psychiatric inpatient admission
    # Cohorts of Interest– 5+ ER Visits with No IP Psych Admission: patients that had at least 5 emergency room visits and no inpatient psychiatric admissions
    attr_accessor :cohort

    # Currently Assigned - If the member is still assigned to the CP as of the most recent member_roster
    attr_accessor :currently_assigned

    def initialize(member_roster: ClaimsReporting::MemberRoster.all)
      @member_roster = member_roster
    end

    def data
      t = filtered_medical_claims.arel_table

      scope = filtered_medical_claims.group(
        :ccs_id,
      ).select(
        :ccs_id,
        Arel.sql('*').count.as('count'),
        t[:member_id].count(true).as('member_count'),
        t[:paid_amount].sum.as('paid_amount_sum'),
      ).order('4 DESC NULLS LAST')

      connection.select_all(scope)
    end

    def filtered_member_roster
      scope = member_roster
      if age_bucket.present? && age_bucket.in?(age_bucket_options)
        range = age_bucket.split('-')
        # FIXME: Do we mean age at the time of service or age now?
        scope = scope.where(date_of_birth: range.max.to_i.years.ago .. range.min.to_i.years.ago)
      end

      scope = scope.where(race: race) if race.present? && race.in?(race_options)

      scope = scope.where(sex: gender) if gender.present? && gender.in?(gender_options)

      scope = scope.where(aco_name: aco) if aco.present? && aco.in?(aco_options)

      scope
    end

    private def filtered_medical_claims
      ClaimsReporting::MedicalClaim.where(member_id: filtered_member_roster.select(:member_id))
    end

    private def connection
      ClaimsReporting::MedicalClaim.connection
    end
  end
end
