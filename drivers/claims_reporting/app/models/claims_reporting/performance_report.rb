module ClaimsReporting
  class PerformanceReport
    attr_reader :month
    # Age Bucket – The age of the member as of July 31, 2020.
    # 18-21
    # 22-29
    # 30-39
    # 40-49
    # 50-59
    # 60-64
    attr_reader :age_bucket

    # Gender – The member’s gender
    # Female
    # Male
    attr_reader :gender

    # Race – The member’s race
    attr_reader :race

    # ACO – The ACO that the member was assigned to at the time the claim is incurred
    attr_reader :aco

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
    attr_reader :mental_health_diagnosis_category

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
    attr_reader :medical_diagnosis_category

    # High Utilizing Member – ‘High Utilizing’ represents high utilizers (3+ inpatient stays or 5+ emergency room visits throughout their claims experience).
    attr_reader :high_utilization_member

    # Cohorts of Interest– The user may select members based on their psychiatric inpatient and emergency room utilization history. The user can select the following utilization categories:
    # Cohorts of Interest– 1+ Psychoses Admission: patients that have had at least 1 inpatient admission for psychoses.
    # Cohorts of Interest– 1+ IP Psych Admission: patients that have had at least 1 non-psychoses psychiatric inpatient admission
    # Cohorts of Interest– 5+ ER Visits with No IP Psych Admission: patients that had at least 5 emergency room visits and no inpatient psychiatric admissions
    attr_reader :cohort

    # Currently Assigned - If the member is still assigned to the CP as of the date of July 31, 2020
    attr_reader :currently_assigned

    def initialize(month:)
      @month = month
    end

    def report_date_range
      @month.beginning_of_month .. @month.end_of_month
    end

    def data
      t = medical_claims.arel_table

      scope = medical_claims.group(
        :ccs_id,
      ).select(
        :ccs_id,
        Arel.sql('*').count.as('count'),
        t[:member_id].count(true).as('member_count'),
        t[:paid_amount].sum.as('paid_amount_sum'),
      ).order('4 DESC NULLS LAST')

      connection.select_all(scope)
    end

    private def connection
      ClaimsReporting::MedicalClaim.connection
    end

    private def medical_claims
      ClaimsReporting::MedicalClaim.all
    end
  end
end
