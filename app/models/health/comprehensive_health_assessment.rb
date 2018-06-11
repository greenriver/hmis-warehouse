module Health
  class ComprehensiveHealthAssessment < HealthBase

    # Generates translation keys of the form "CHA A_Q5_A6"
    def self.answers_for section: nil, question: nil, number: 0
      return [] unless section.present? && 
        question.present? && 
        number&.is_a?(Integer)
      (1..number).map { |n| _("CHA #{section}_Q#{question}_A#{n}") }
    end

    QUESTION_ANSWER_OPTIONS = {
      a_q1:  nil,
      a_q2:  answers_for(section: 'A', question: 2, number: 2),
      a_q3:  nil,
      a_q4:  answers_for(section: 'A', question: 4, number: 6),
      a_q5a: nil,
      a_q5b: nil,
      a_q5c: nil,
      a_q6:  nil,
      a_q7:  answers_for(section: 'A', question: 7, number: 7),
      a_q8:  nil,
      a_q9:  nil,
      a_q10: nil,
      a_q11: answers_for(section: 'A', question: 11, number: 14),
      a_q12: answers_for(section: 'A', question: 12, number: 8),

      b_q1: nil,
      b_q2: answers_for(section: 'B', question: 2, number: 6),
      b_q3: answers_for(section: 'B', question: 3, number: 4),
      b_q4: answers_for(section: 'B', question: 4, number: 5),

      c_q1: answers_for(section: 'C', question: 1, number: 6),
      c_q2: answers_for(section: 'C', question: 2, number: 2),
      c_q3: answers_for(section: 'C', question: 3, number: 4),

      d_q1: answers_for(section: 'D', question: 1, number: 5),
      d_q2: answers_for(section: 'D', question: 2, number: 5),
      d_q3: answers_for(section: 'D', question: 3, number: 5),
      d_q4: answers_for(section: 'D', question: 4, number: 5),

      e_q1a: (indicators = answers_for(section: 'E', question: '1A', number: 4)),
      e_q1b: indicators,
      e_q1c: indicators,
      e_q1d: indicators,
      e_q1e: indicators,
      e_q1f: indicators,
      e_q1g: indicators,
      e_q1h: indicators,
      e_q1i: indicators,
      e_q2a: (indicators = answers_for(section: 'E', question: '2A', number: 5)),
      e_q2b: indicators,
      e_q2c: indicators,

      f_q1a: (indicators = answers_for(section: 'F', question: '1A', number: 6)),
      f_q1b: indicators,
      f_q1c: indicators,
      f_q1d: indicators,
      f_q1e: indicators,
      f_q1f: indicators,
      f_q2: answers_for(section: 'F', question: 2, number: 2),
      f_q3: answers_for(section: 'F', question: 3, number: 3),
      f_q4: answers_for(section: 'F', question: 4, number: 4),
      f_q5: answers_for(section: 'F', question: 5, number: 2),

      g_q1ap: (indicators = answers_for(section: 'G', question: '1AP', number: 8)),
      g_q1bp: indicators,
      g_q1cp: indicators,
      g_q1dp: indicators,
      g_q1ep: indicators,
      g_q1fp: indicators,
      g_q1gp: indicators,
      g_q1hp: indicators,

      g_q1ac: (indicators = indicators.take(7)),
      g_q1bc: indicators,
      g_q1cc: indicators,
      g_q1dc: indicators,
      g_q1ec: indicators,
      g_q1fc: indicators,
      g_q1gc: indicators,
      g_q1hc: indicators,

      g_q2a: (indicators = answers_for(section: 'G', question: '2A', number: 8)),
      g_q2b: indicators,
      g_q2c: indicators,
      g_q2d: indicators,
      g_q2e: indicators,
      g_q2f: indicators,

      g_q3:  answers_for(section: 'G', question: 3, number: 4),
      g_q4a: answers_for(section: 'G', question: '4A', number: 5),
      g_q4b: answers_for(section: 'G', question: '4B', number: 4),
      g_q5:  answers_for(section: 'G', question: 5, number: 4),
      g_q6a: answers_for(section: 'G', question: '6A', number: 2),
      g_q6b: answers_for(section: 'G', question: '6B', number: 2),

      h_q1:  answers_for(section: 'H', question: 1, number: 7),

      i_q1a: (indicators = answers_for(section: 'I', question: '1A', number: 4)),
      i_q1b: indicators,
      i_q1c: indicators,
      i_q1d: indicators,
      i_q1e: indicators,
      i_q1f: indicators,
      i_q1g: indicators,
      i_q1h: indicators,
      i_q1i: indicators,
      i_q1j: indicators,
      i_q1k: indicators,
      i_q1l: indicators,
      i_q1m: indicators,
      i_q1n: indicators,

      i_q2a1: nil,
      i_q2b1: nil,
      i_q2c1: nil,
      i_q2d1: nil,
      i_q2e1: nil,
      i_q2f1: nil,
      i_q2a2: indicators,
      i_q2b2: indicators,
      i_q2c2: indicators,
      i_q2d2: indicators,
      i_q2e2: indicators,
      i_q2f2: indicators,
      i_q2a3: nil,
      i_q2b3: nil,
      i_q2c3: nil,
      i_q2d3: nil,
      i_q2e3: nil,
      i_q2f3: nil,

      j_q1: answers_for(section: 'J', question: 1, number: 4),
      j_q2: answers_for(section: 'J', question: 2, number: 3),

      j_q3a: (indicators = answers_for(section: 'J', question: '3A', number: 5)),
      j_q3b: indicators,
      j_q3c: indicators,
      j_q3d: indicators,
      j_q3e: indicators,
      j_q3f: indicators,
      j_q3g: indicators,
      j_q3h: indicators,
      j_q3i: indicators,
      j_q3j: indicators,
      j_q3k: indicators,
      j_q3l: indicators,

      j_q4: answers_for(section: 'J', question: 4, number: 4),
      j_q5: answers_for(section: 'J', question: 5, number: 5),

      j_q6a: answers_for(section: 'J', question: '6A', number: 4),
      j_q6b: answers_for(section: 'J', question: '6B', number: 5),
      j_q6c: answers_for(section: 'J', question: '6C', number: 4),
      j_q6d: answers_for(section: 'J', question: '6D', number: 2),
      j_q6e: answers_for(section: 'J', question: '6E', number: 6),

      j_q7a: indicators = (answers_for(section: 'J', question: '7A', number: 2)),
      j_q7b: indicators,

      j_q8: answers_for(section: 'J', question: 8, number: 5),

      j_q9a: answers_for(section: 'J', question: '9A', number: 3),
      j_q9b: answers_for(section: 'J', question: '9B', number: 4),

      k_q1a: (indicators = answers_for(section: 'K', question: '1A', number: 2)),
      k_q1b: indicators,
      k_q1c: indicators,
      k_q1d: indicators,

      l_q1s1a: nil,
      l_q1s1b: nil,
      l_q1s1c: (units  = answers_for(section: 'L', question: '1_1C', number: 12)),
      l_q1s1d: (routes = answers_for(section: 'L', question: '1_1D', number: 13)),
      l_q1s1e: (freq   = answers_for(section: 'L', question: '1_1E', number: 21)),
      l_q1s1f: (prn    = answers_for(section: 'L', question: '1_1F', number: 2)),
      l_q1s1g: nil,

      l_q1s2a: nil,
      l_q1s2b: nil,
      l_q1s2c: units,
      l_q1s2d: routes,
      l_q1s2e: freq,
      l_q1s2f: prn,
      l_q1s2g: nil,

      l_q1s3a: nil,
      l_q1s3b: nil,
      l_q1s3c: units,
      l_q1s3d: routes,
      l_q1s3e: freq,
      l_q1s3f: prn,
      l_q1s3g: nil,

      l_q1s4a: nil,
      l_q1s4b: nil,
      l_q1s4c: units,
      l_q1s4d: routes,
      l_q1s4e: freq,
      l_q1s4f: prn,
      l_q1s4g: nil,

      l_q1s5a: nil,
      l_q1s5b: nil,
      l_q1s5c: units,
      l_q1s5d: routes,
      l_q1s5e: freq,
      l_q1s5f: prn,
      l_q1s5g: nil,

      l_q2: answers_for(section: 'L', question: 2, number: 2),

      m_q1a: (indicators = answers_for(section: 'M', question: '1A', number: 2)),
      m_q1b: indicators,
      m_q1c: indicators,
      m_q1d: indicators,
      m_q1e: indicators,
      m_q1f: indicators,
      m_q1g: indicators,
      m_q1h: indicators,

      n_q1: answers_for(section: 'N', question: 1, number: 2),

      o_q1: answers_for(section: 'O', question: 1, number: 2),

      p_q1: nil,
      p_q2: answers_for(section: 'P', question: 2, number: 15),

      q_q1: nil,
      q_q2: nil,

      r_q1: answers_for(section: 'R', question: 1, number: 4),
      r_q2: answers_for(section: 'R', question: 2, number: 2),
      r_q3: answers_for(section: 'R', question: 3, number: 2),
      r_q4: answers_for(section: 'R', question: 4, number: 2),
      r_q5: answers_for(section: 'R', question: 5, number: 4),
      r_q6a: nil,
      r_q6b: nil,
      r_q6c: nil,
      r_q6d: nil,
      r_q6e: nil,
      r_q7: answers_for(section: 'R', question: 7, number: 2),
      r_q8: answers_for(section: 'R', question: 8, number: 9),

      r_q9a: nil,
      r_q9b: nil,
      r_q9c: nil,
      r_q9d: nil,
      r_q10a: nil,
      r_q10b: nil,
      r_q10c: nil,
      r_q10d: nil,
      r_q11a: nil,
      r_q11b: nil,
      r_q11c: nil,
      r_q11d: nil,
      r_q12a: nil,
      r_q12b: nil,
      r_q12c: nil,
      r_q12d: nil,
      r_q13a: nil,
      r_q13b: nil,
      r_q13c: nil,
      r_q13d: nil,
      r_q14a: nil,
      r_q14b: nil,
      r_q14c: nil,
      r_q14d: nil,
      r_q15a: nil,
      r_q15b: nil,
      r_q15c: nil,
      r_q15d: nil,
      r_q16a: nil,
      r_q16b: nil,
      r_q16c: nil,
      r_q16d: nil,
      r_q17a: nil,
      r_q17b: nil,
      r_q17c: nil,
      r_q17d: nil,
      r_q18a: nil,
      r_q18b: nil,
      r_q18c: nil,
      r_q18d: nil,
      r_q19a: nil,
      r_q19b: nil,
      r_q19c: nil,
      r_q19d: nil,
      r_q20a: nil,
      r_q20b: nil,
      r_q20c: nil,
      r_q20d: nil,
      r_q21a: nil,
      r_q21b: nil,
      r_q21c: nil,
      r_q21d: nil,
      r_q22a: nil,
      r_q22b: nil,
      r_q22c: nil,
      r_q22d: nil,
      r_q23a: nil,
      r_q23b: nil,
      r_q23c: nil,
      r_q23d: nil,
      r_q24a: nil,
      r_q24b: nil,
      r_q24c: nil,
      r_q24d: nil,
      r_q25a: nil,
      r_q25b: nil,
      r_q25c: nil,
      r_q25d: nil,
      r_q26a: nil,
      r_q26b: nil,
      r_q26c: nil,
      r_q26d: nil,
      r_q27a: nil,
      r_q27b: nil,
      r_q27c: nil,
      r_q27d: nil,

      r_q28a: nil,
      r_q28b: nil,
      r_q28c: nil,
      r_q28d: nil,
      r_q29a: nil,
      r_q29b: nil,
      r_q29c: nil,
      r_q29d: nil,
      r_q30a: nil,
      r_q30b: nil,
      r_q30c: nil,
      r_q30d: nil,
      r_q31a: nil,
      r_q31b: nil,
      r_q31c: nil,
      r_q31d: nil,
      r_q32a: nil,
      r_q32b: nil,
      r_q32c: nil,
      r_q32d: nil,
      r_q33a: nil,
      r_q33b: nil,
      r_q33c: nil,
      r_q33d: nil,
      r_q34a: nil,
      r_q34b: nil,
      r_q34c: nil,
      r_q34d: nil,
      r_q35a: nil,
      r_q35b: nil,
      r_q35c: nil,
      r_q35d: nil,
      r_q36a: nil,
      r_q36b: nil,
      r_q36c: nil,
      r_q36d: nil,
      r_q37a: nil,
      r_q37b: nil,
      r_q37c: nil,
      r_q37d: nil,

    }

    belongs_to :patient
    belongs_to :user
    belongs_to :reviewed_by, class_name: 'User'
    belongs_to :health_file, dependent: :destroy

    enum status: [:not_started, :in_progress, :complete]

    scope :recent, -> { order(created_at: :desc).limit(1) }
    scope :reviewed, -> { where.not(reviewed_by_id: nil) }

    attr_accessor :reviewed_by_supervisor, :completed

    attr_accessor *QUESTION_ANSWER_OPTIONS.keys

    before_save :set_answers

    private def set_answers
      hash = self.answers.dup
      QUESTION_ANSWER_OPTIONS.keys.each do |section_question|
        section_code  = section_question.to_s.upcase.split('_').first
        section       = _("CHA #{section_code}_TITLE")
        question      = _("CHA #{section_question.upcase}")
        hash[section_code] ||= {}
        hash[section_code][:title] = section
        hash[section_code][:answers] ||= {}
        hash[section_code][:answers][section_question] ||= {}
        hash[section_code][:answers][section_question][:question] ||= question
        value = send(section_question)
        hash[section_code][:answers][section_question][:answer] = value if value
      end
      hash['A'][:answers][:a_q1][:answer] = patient.client&.name
      hash['A'][:answers][:a_q3][:answer] = patient.client&.DOB
      hash['A'][:answers][:a_q5c][:answer] = patient.medicaid_id
      self.answers = hash
    end

    def answers
      super || {}
    end

    def answer question_code
      section, question = question_code.to_s.upcase.split('_')

      answers.dig(section, 'answers', question_code.to_s, 'answer')
    end

    def editable_by? editor
      editor == user
    end

    # allow keys, but some keys need to allow multiple checkbox selections (b_q2 & b_q4)
    PERMITTED_PARAMS = QUESTION_ANSWER_OPTIONS.keys - [:b_q2, :b_q4, :r_q8] + [{ b_q2: [] }, { b_q4: [] }, { r_q8: [] }]

  end
end