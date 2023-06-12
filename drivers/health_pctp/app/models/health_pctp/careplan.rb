###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthPctp
  class Careplan < HealthBase
    include Rails.application.routes.url_helpers

    phi_patient :patient_id
    phi_attr :user_id, Phi::SmallPopulation
    phi_attr :completed_at, Phi::Date

    belongs_to :patient, class_name: 'Health::Patient', optional: true
    belongs_to :user, optional: true

    has_many :needs, dependent: :destroy
    has_many :care_goals, dependent: :destroy

    scope :in_progress, -> { where(patient_signed_on: nil) }
    scope :completed_within, ->(range) { where(patient_signed_on: range) }

    scope :allowed_for_engagement, -> do
      joins(patient: :patient_referrals).
        merge(
          ::Health::PatientReferral.contributing.
            where(
              hpr_t[:enrollment_start_date].lt(Arel.sql("#{arel_table[:patient_signed_on].to_sql} + INTERVAL '1 year'")),
            ),
        )
    end

    alias_attribute :completed_at, :patient_signed_on

    def active?
      completed_on && completed_on >= 1.years.ago
    end

    def completed?
      completed_on.present?
    end

    def identifying_information
      {
        name: ['Enrollee Name', :string, nil],
        dob: ['DOB', :date_picker, nil],
        phone: ['Enrollee Phone Number', :tel, nil],
        email: ['Enrollee Email Address', :email, nil],
        mmis: ['MMIS', :string, nil],
        aco: ['ACO/MCO', :string, nil],
      }
    end

    def care_team_members
      {
        cc: "Enrollee's Care Coordinator (s)",
        ccm: "Enrollee's Clinical Care Manager(s)",
        pcp: "Enrollee's PCP or PCP Designee",
        rn: "Enrollee's RN",
        other_members: 'Additional Care Team members, as applicable',
      }
    end

    def enrollee_overview_label
      'Briefly describe the Enrollee’s (age, gender), their living situation (who do they live with and ' +
        'what are their relationships), communication style (best way to communicate), cultural considerations. ' +
        "Please also consider the Enrollee's ability to adhere to treatment plans."
    end

    def demographic_information
      {
        scribe: ['Person completing this care plan', :string, nil],
        update_reason: ['Reason for Update', :select_two, update_reason_responses],
        sex_at_birth: [['Sex at Birth', 'What sex were you assigned at birth?'], :select_two, sex_at_birth_responses],
        gender: [['Gender Identity', 'What is your current gender identity?'], :select_two, gender_responses],
        orientation: [['Sexual Orientation', 'Do you think of yourself as:'], :select_two, orientation_responses],
        race: ['Race', :select_two, race_responses],
        ethnicity: ['Ethnicity', :select_two, ethnicity_responses],
        language: ['Language', :select_two, language_responses],
        contact: ['Preferred method of contact', :select_two, contact_responses],
      }
    end

    def goals_label
      'What are the goals they would like to achieve with the Community Partner program and how will their ' +
        'self-identified strengths be used to overcome barriers to these goals?'
    end

    def update_reason_responses
      {
        initial: 'Initial Comprehensive Assessment',
        annual: 'Annual Update',
        status_change: 'Change in Behavioral or Physical Health Status',
        other: 'Other',
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

    def accommodation_responses
      {
        communication: 'Communication',
        equipment: 'Equipment',
        transportation: 'Transportation',
        other: 'Other – Not Listed (specify below)',
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
  end
end
