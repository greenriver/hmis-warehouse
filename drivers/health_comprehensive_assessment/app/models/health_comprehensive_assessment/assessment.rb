###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthComprehensiveAssessment
  class Assessment < HealthBase
    include Rails.application.routes.url_helpers
    include HealthComprehensiveAssessment::PopulateAssessmentConcern
    acts_as_paranoid

    phi_patient :patient_id
    phi_attr :user_id, Phi::SmallPopulation
    phi_attr :completed_on, Phi::Date
    phi_attr :reviewed_by_id, Phi::SmallPopulation
    phi_attr :reviewed_on, Phi::Date
    # An assessment is almost entirely PHI, but the attributes are not listed here due to their number

    belongs_to :patient, class_name: 'Health::Patient', optional: true
    belongs_to :user, optional: true
    belongs_to :reviewed_by, class_name: 'User', optional: true

    has_many :medications, dependent: :destroy
    has_many :sud_treatments, dependent: :destroy

    scope :in_progress, -> { where(completed_on: nil) }
    scope :completed_within, ->(range) { where(completed_at: range) }
    scope :allowed_for_engagement, -> do
      joins(patient: :patient_referrals).
        merge(
          ::Health::PatientReferral.contributing.
            where(
              hpr_t[:enrollment_start_date].lt(Arel.sql("#{arel_table[:completed_on].to_sql} + INTERVAL '1 year'")),
            ),
        )
    end
    scope :reviewed, -> { where.not(reviewed_by_id: nil) }
    scope :reviewed_within, ->(range) { where(reviewed_on: range) }

    alias_attribute :completed_at, :completed_on
    alias_attribute :reviewed_at, :reviewed_on

    def edit_path
      client_health_comprehensive_assessment_assessment_path(patient.client, self)
    end

    def completed?
      completed_on.present?
    end

    def active?
      completed_on && completed_on >= 1.years.ago
    end

    def identifying_information
      {
        name: ['Enrollee Name', :string, nil],
        pronouns: ['What pronoun does the Member use', :select_two, pronoun_responses],
        dob: ['DOB', :date_picker, nil],
        update_reason: ['Reason for Update', :select_two, update_reason_responses],
        phone: ['Enrollee Phone Number', :tel, nil],
        email: ['Enrollee Email Address', :email, nil],
        address: ['Address', :string, nil],
        contact: ['Preferred method of contact', :select_two, contact_responses],
        message_ok: ['Okay to leave a message on the phone?', :pretty_boolean_group, yes_no],
        internet_access: ['Do you have access to the internet?', :pretty_boolean_group, yes_no],
      }
    end

    def demographic_information
      {
        race: ['Race', :select_two, race_responses],
        ethnicity: ['Ethnicity', :select_two, ethnicity_responses],
        language: ['Language', :select_two, language_responses],
        disabled: ['Disability Status', :pretty_boolean_group, yes_no],
        orientation: [['Sexual Orientation', 'Do you think of yourself as:'], :select_two, orientation_responses],
        sex_at_birth: [['Sex at Birth', 'What sex were you assigned at birth?'], :select_two, sex_at_birth_responses],
        gender: [['Gender Identity', 'What is your current gender identity?'], :select_two, gender_responses],
      }
    end

    def service_funders
      {
        dmh: 'Department of Mental Health (DMH)',
        dcf: 'Department of Children & Families (DCF)',
        dys: 'Department of Youth Services (DYS)',
        dds: 'Department of Developmental Services (DDS)',
        dph: 'Department of Public Health (DPH)',
        bsa: 'Bureau of Substance Abuse Services (BSAS)',
        mrc: 'Mass Rehabilitation Commission (MRC)',
        mcb: 'Mass Commission for the Blind (MCB)',
        mcdhh: 'Mass Commission for the Deaf and Hard of Hearing (MCDHH)',
      }.with_indifferent_access.invert
    end

    def service_providers
      {
        pcp: ['Primary Care Provider (PCP)', 'When did you see PCP last?'],
        hh: ['Home Health', nil],
        psych: ['Psychiatrist', nil],
        therapist: ['Therapist', nil],
        case_manager: ['Other Case Manager', nil],
        specialist: ['Specialist (Endocrinology, Cardiology, Neurology, Dermatology, Pulmonary)', 'Specify type'],
        guardian: ['Guardian (Permanent, Roger’s, Medical, Conservatorship, Temporary, Full)', 'Specify type'],
        rep_payee: ['Rep Payee', nil],
        social_support: ['Social Support (Informal, Caregiver, Family)', 'Specify relationship'],
        cbfs: ['Community Based Flexible Supports (CBFS)', nil],
        housing: ['Housing Provider', nil],
        day: ['Day Services Provider', nil],
        job: ['Job Coach / Employment', nil],
        peer_support: ['Peer Support / CHW', nil],
        dta: ['Department of Transitional Assistance (DTA)', nil],
        va: ['Veterans Affairs', nil],
        probation: ['Probation/Parole', 'Indicate start and stop dates'],
        other_provider: ['Other', 'Specify type'],
      }
    end

    def health_conditions
      {
        'Musculoskeletal' => {
          hip_fracture: 'Hip fracture during last 30 days',
          other_fracture: 'Other fracture during last 30 days',
          chronic_pain: 'Chronic Pain (Low back pain, neuropathic pain, etc.)',
        },
        'Neurological' => {
          alzheimers: "Alzheimer's disease",
          dementia: "Dementia other than Alzheimer's disease",
          stroke: 'Stroke/Cerebral Vascular Accident (CVA)',
          parkinsons: "Parkinson's/ALS/Other Neurological Disorder",
        },
        'Cardiac or Pulmonary' => {
          hypertension: 'Hypertension',
          cad: 'Coronary Artery Disease (CAD)',
          chf: 'Congestive heart failure (CHF)',
          copd: 'Chronic obstructive pulmonary disease',
          asthma: 'Asthma',
          apnea: 'Sleep Apnea',
        },
        'Psychiatric' => {
          anxiety: 'Anxiety',
          bipolar: 'Bipolar disorder',
          depression: 'Depression',
          schizophrenia: 'Schizophrenia',
        },
        'Additional Concerns' => {
          cancer: 'Cancer',
          diabetes: 'Diabetes mellitus',
          arthritis: 'Arthritis',
          ckd: 'Chronic Kidney Disease (CKD)',
          liver: 'Liver disease',
          transplant: 'Transplant',
          weight: 'Weight Problem',
          other_condition: 'Other',
        },
      }
    end

    def general_health_conditions
      {
        a: 'Excellent',
        b: 'Very good',
        c: 'Good',
        d: 'Fair',
        f: 'Poor',
      }.with_indifferent_access.invert
    end

    def pain_levels
      {
        none: 'None',
        some: 'Some',
        a_lot: 'A lot',
      }.with_indifferent_access.invert
    end

    def pronoun_responses
      {
        he: 'He/him/his',
        she: 'She/her/hers',
        they: 'They/them/theirs',
        other: 'Other',
      }.with_indifferent_access.invert
    end

    def update_reason_responses
      {
        initial: 'Initial Comprehensive Assessment',
        annual: 'Annual Update',
        status_change: 'Change in Behavioral or Physical Health Status',
        other: 'Other',
      }.with_indifferent_access.invert
    end

    def contact_responses
      {
        email: 'Email',
        postal: 'Mailing Addres',
        phone: 'Phone',
        text: 'Text',
        other: 'Other',
      }.with_indifferent_access.invert
    end

    def yes_no
      {
        yes: 'Yes',
        no: 'No',
      }.with_indifferent_access.invert
    end

    def race_responses
      {
        am_ind_ak_native: 'American Indian or Alaskan Native',
        asian: 'Asian',
        black_af_american: 'Black or African American',
        native_hi_pacific: 'Native Hawaiian or Other Pacific Islander',
        white: 'White',
        declined: 'Declined to Specify',
        not_captured: 'Not Captured',
      }.with_indifferent_access.invert
    end

    def ethnicity_responses
      {
        hispanic: 'Hispanic or Latino',
        not_hispanic: 'Not Hispanic or Latino',
        declined: 'Declined to Specify',
        not_captured: 'Not Captured',
      }.with_indifferent_access.invert
    end

    def language_responses
      {
        sqi: 'Albanian',
        amh: 'Amharic',
        ara: 'Arabic',
        hye: 'Armenian',
        ben: 'Bengali',
        khm: 'Central Khmer',
        zhp: 'Chinese',
        cpp: 'Creoles and pidgins, Portuguese-based',
        hrv: 'Croatian',
        und: 'Declined to Specify',
        eng: 'English',
        fra: 'French',
        cpf: 'French Creole',
        deu: 'German',
        ell: 'Greek, Modern (1453-)',
        guj: 'Gujarati',
        hat: 'Haitian; Haitian Creole',
        heb: 'Hebrew',
        hin: 'Hindi',
        hmn: 'Hmong; Mong',
        ita: 'Italian',
        jpn: 'Japanese',
        kor: 'Korean',
        lao: 'Lao',
        lit: 'Lithuanian',
        nep: 'Nepali',
        orm: 'Oromo',
        pol: 'Polish',
        por: 'Portuguese',
        rus: 'Russian',
        srp: 'Serbian',
        sgn: 'Sign Languages',
        slv: 'Slovenian',
        som: 'Somali',
        spa: 'Spanish',
        swa: 'Swahili',
        swe: 'Swedish',
        tgl: 'Tagalog',
        tha: 'Thai',
        vie: 'Vietnamese',
      }.with_indifferent_access.invert
    end

    def orientation_responses
      {
        straight: 'Straight or heterosexual',
        gay: 'Lesbian, gay, or homosexual',
        bisexual: 'Bisexual',
        other: 'Additional category (e.g., queer, pansexual, asexual)',
        unknown: 'Don’t know',
        declined: 'Choose not to disclose',
      }.with_indifferent_access.invert
    end

    def sex_at_birth_responses
      {
        male: 'Male',
        female: 'Female',
        other: 'Other',
      }.with_indifferent_access.invert
    end

    def gender_responses
      {
        female: 'Female',
        male: 'Male',
        trans_female: 'Transgender Woman/Transgender Female',
        trans_male: 'Transgender Man/Transgender Male',
        other: 'Additional category (e.g., non-binary, genderqueer, gender-diverse, or gender fluid)',
        declined: 'Choose not to disclose',
      }.with_indifferent_access.invert
    end

    def health_condition_statuses
      {
        not_present: 'Not present',
        treating: 'Diagnosis present,receiving active treatment',
        monitoring: 'Diagnosis present, monitored, but no active treatment',
      }.with_indifferent_access.invert
    end

    def medication_adherence_responses
      {
        not_applicable: 'I do not have to take medicine',
        always: 'I always take them as prescribed',
        sometimes: 'Sometimes I take them as prescribed',
        seldom: 'I seldom take them as prescribed',
      }.with_indifferent_access.invert
    end

    def can_communicate_about_responses
      {
        concerns: 'Concerns',
        symptoms: 'Symptoms',
        goals: 'Goals',
      }.with_indifferent_access.invert
    end

    def assessed_needs_responses
      {
        housekeeping: 'Housekeeping/Laundry',
        housing: 'Housing Stability',
        food: 'Grocery Shopping/Food Preparation',
        medication_management: 'Medication Management',
        money_management: 'Money Management',
        personal_care: 'Personal Care Skills (includes Grooming/Dress)',
        exercise: 'Exercise',
        safety: 'Safety/Self Preservation',
        transportation: 'Transportation',
        problem_solving: 'Problem Solving Skills',
        time_management: 'Time Management',
        other: 'Other (specify below)',
      }.with_indifferent_access.invert
    end

    def substance_use_responses
      {
        never: '0',
        once: '1',
        twice: '2',
        three_or_more: '3 or more times',
      }.with_indifferent_access.invert
    end

    def alcohol_drinks_responses
      {
        never: 'Never',
        once: 'Once during the week',
        two_or_three: '2–3 times during the week',
        more_than_three: 'More than 3 times during the week',
      }.with_indifferent_access.invert
    end

    def in_patient_responses
      {
        inpatient: 'Inpatient',
        outpatient: 'Outpatient',
      }.with_indifferent_access.invert
    end

    def sud_treatment_sources_responses
      {
        patient: 'Person Served',
        family: 'Significant other/Family member(s)',
        provider: 'Service Provider(s)',
        case_manager: 'Case Manager',
        records: 'Written records',
        other: 'Other',
      }.with_indifferent_access.invert
    end

    def preferred_mode_responses
      {
        oral: 'Oral',
        written: 'Written',
      }.with_indifferent_access.invert
    end

    def accessibility_equipment_responses
      {
        diaper: 'Adult Diapers/Incontinence Bedding',
        sugar_monitor: 'Blood Sugar Monitor',
        walker: 'Cane/Crutch/Walker',
        commode: 'Commode Chair',
        cpap: 'CPAP Device',
        bed: 'Hospital Bed',
        hoyer_lift: 'Hoyer Lift',
        nebulizer: 'Nebulizer',
        oxigen: 'Oxygen Equipment',
        wheelchair: 'Wheelchair – Manual',
        motorized_wheelchair: 'Wheelchair – Motorized',
        n_a: 'N/A',
        other: 'Other - Not Listed (specify below)',
      }.with_indifferent_access.invert
    end

    def supports_responses
      {
        friend: 'Friend',
        family: 'Family',
        spouse: 'Spouse/Partner',
        sibling: 'Sibling(s)',
        adult_child: 'Adult Child(ren)',
        parent: 'Parent(s)',
        social: 'Social Supports',
        peer: 'Peer Supports',
        pet: 'Pet/Service Animal',
        community: 'Community Supports',
        group: 'Self Help Groups (AA, NA, SMART, NAMI)',
        school: 'School',
        church: 'Spiritual/Religious',
        other: 'Other',
      }.with_indifferent_access.invert
    end

    def social_supports_placeholder
      "Describe the person's relationships with friends and other sources of social support. " +
        'Describe social skills and limitations including difficulties the person may experience in ' +
        'his/her relationships with others. Record the supports the person currently receives from his/her ' +
        'community or from self-help groups. Include a description of the support(s) being received. For example, ' +
        'if the person is receiving support from the Department of Children and Families, explain what ' +
        'types of services DCF is providing'
    end

    def abuse_risk_factors
      {
        physical_abuse_frequency: ['How often does anyone, including family and friends, physically hurt you?', :select_two, abuse_risk_responses],
        verbal_abuse: ['How often does anyone, including family and friends, insult or talk down to you?', :select_two, abuse_risk_responses],
        threat_frequency: ['How often does anyone, including family and friends, threaten you with harm?', :select_two, abuse_risk_responses],
        scream_or_curse_frequency: ['How often does anyone, including family and friends, scream or curse at you?', :select_two, abuse_risk_responses],
      }
    end

    enum physical_abuse_frequency: {
      never: 1,
      rarely: 2,
      sometimes: 3,
      often: 4,
      frequently: 5,
    }, _prefix: true

    enum verbal_abuse: {
      never: 1,
      rarely: 2,
      sometimes: 3,
      often: 4,
      frequently: 5,
    }, _prefix: true

    enum threat_frequency: {
      never: 1,
      rarely: 2,
      sometimes: 3,
      often: 4,
      frequently: 5,
    }, _prefix: true

    enum scream_or_curse_frequency: {
      never: 1,
      rarely: 2,
      sometimes: 3,
      often: 4,
      frequently: 5,
    }, _prefix: true

    def abuse_risk_responses
      {
        never: 'Never (1)',
        rarely: 'Rarely (2)',
        sometimes: 'Sometimes (3)',
        often: 'Fairly often (4)',
        frequently: 'Frequently (5)',
      }.invert
    end

    def advanced_directive_responses
      {
        advanced_directive: ['Does the person have an advanced directive established?', :pretty_boolean_group, yes_no, { class: 'jHasAdvancedDirective' }],
        directive_type: ['If yes, what type?', :select_two, directive_types, nil, 'jYesDirective'],
        develop_directive: ['If no, does the person wish to develop them at this time?', :select_two, yes_no_develop, nil, 'jNoDirective'],
      }
    end

    def directive_types
      {
        living_will: 'Living Will',
        power_of_attorney: 'Power of Attorney',
        health_care_proxy: 'Health Care Proxy',
        other: 'Other',
      }.with_indifferent_access.invert
    end

    def yes_no_develop
      {
        yes: 'Yes (follow agency’s procedure for completion)',
        no: 'No',
      }.with_indifferent_access.invert
    end

    def employment_questions
      {
        employment_status: ['Which of the following best describes you?', :select_two, employment_status_responses],
      }
    end

    def employment_status_responses
      {
        employed: 'Employed (full or part time, including self-employed)',
        unemployed: 'Unemployed / looking for work',
        school: 'At school or in full time education',
        unable_to_work: 'Unable to work due to long term sickness',
        caregiver: 'Looking after your home/family',
        retired: 'Retired from paid work',
        other: 'Other',
      }.with_indifferent_access.invert
    end

    def legal_status
      {
        has_legal_involvement: ['Does the Enrollee have current legal involvement or issues or a history of legal involvement or issues?', :pretty_boolean_group, yes_no, { class: 'jHasLegalInvolvements' }],
        legal_involvements: ['If yes, select all that apply:', :select_two, legal_involvements_responses, { multiple: true }, 'jLegalInvolvements'],
      }
    end

    def legal_involvements_responses
      {
        arrest: 'Arrest',
        jail: 'Jail',
        adjudication: 'Adjudication',
        conviction: 'Conviction',
        probation: 'Probation',
        sex_offender: 'Registered Sex Offender',
        restraining_order: 'Active Restraining Order',
        parole: 'Parole',
        immigration: 'Immigration issues',
        custody: 'Custody/Family Court',
        civil: 'Civil Litigation',
        cori: 'CORI Issues',
        court_case: 'Open Court Case',
        warrant: 'Warrant',
        other: 'Other',
      }.with_indifferent_access.invert
    end

    def education_level_responses
      {
        ged: 'GED',
        hs_grad: 'HS Grad',
        college: 'College',
        voc: 'Vocational Training',
        graduate_degree: 'Graduate Degree',
        no_diploma: 'No diploma',
        some_school: 'Highest Grade Completed, specify below',
        other: 'Other',
      }.with_indifferent_access.invert
    end

    def financial_support_responses
      {
        ssi: 'SSI',
        ssdi: 'SSDI',
        food_stamps: 'Food Stamps',
        family: 'Contributions from family or friends',
        disability: 'Disability',
        child_support: 'Child Support',
        va: 'Veterans Benefits',
        tafdc: 'TAFDC',
        eaedc: 'EAEDC',
        other: 'Other',
      }.with_indifferent_access.invert
    end
  end
end
