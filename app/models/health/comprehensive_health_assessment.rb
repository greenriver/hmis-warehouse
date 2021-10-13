###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class ComprehensiveHealthAssessment < HealthBase
    acts_as_paranoid
    phi_patient :patient_id
    phi_attr :user_id, Phi::SmallPopulation, "ID of user"
    phi_attr :reviewed_by_id, Phi::SmallPopulation, "ID of reviewer"
    phi_attr :reviewer, Phi::SmallPopulation
    phi_attr :completed_at, Phi::Date, "Date of assessment completion"
    phi_attr :reviewed_at, Phi::Date, "Date of review"
    phi_attr :health_file_id, Phi::OtherIdentifier, "ID of health file"
    phi_attr :answers, Phi::FreeText

    # Generates translation keys of the form "CHA A_Q5_A6"
    def self.answers_for section: nil, question: nil, number: 0
      return [] unless section.present? &&
        question.present? &&
        number&.is_a?(Integer)
      (1..number).map do |n|
        question_key = "#{section}_Q#{question}"
        answer_key = "#{section}_Q#{question}_A#{n}"
        value = _("CHA #{answer_key}")
        text = value.gsub(/^\d+\./, '').strip # Some values already have numbers
        # text = "#{text} / #{question_key}"

        if value.downcase.in?(EIGHTS_RESPONSES)
          label = "[8] #{text}"
        elsif value.downcase.in?(BLANK_RESPONSES)
          label = "[blank] #{text}"
        elsif question_key.in?(ZERO_BASED)
          label = "[#{n - 1}] #{text}"
        elsif question_key.in?(LETTER_BASED)
          label = "[#{LETTERS[n - 1]}] #{text}"
        elsif question_key.in?(NO_PREFIX)
          label = text
        else
          label = "[#{n}] #{text}"
        end
        [
          label,
          value,
        ]
      end
    end

    NO_PREFIX = [
      'R_Q1', 'R_Q2', 'R_Q3', 'R_Q4', 'R_Q5', 'R_Q7', 'R_Q8',

    ]

    EIGHTS_RESPONSES = [
      'uncertain',
      'unable to determine',
      'person could not (would not) respond',
      'activity did not occur—during entire period ',
      'activity did not occur during entire period',
      'did not occur',
      'could not (would not) respond',
      'did not occur—no urine output from bladder in last 3 days',
    ]

    BLANK_RESPONSES = [
      'not applicable (first assessment, or more than 30 days since last assessment)',
    ]

    LETTERS = ('a' .. 'z').to_a

    LETTER_BASED = [
      'B_Q2', 'B_Q4',
    ]

    ZERO_BASED = [
      'C_Q1', 'C_Q2', 'C_Q3',
      'D_Q1', 'D_Q2', 'D_Q3', 'D_Q4',
      'E_Q1A', 'E_Q2A',
      'F_Q1A', 'F_Q2', 'F_Q3', 'F_Q4', 'F_Q5',
      'G_Q1AP', 'G_Q2A', 'G_Q3', 'G_Q4A', 'G_Q4B', 'G_Q5', 'G_Q6A', 'G_Q6B',
      'H_Q1',
      'I_Q1A',
      'J_Q1', 'J_Q2', 'J_Q3A', 'J_Q4', 'J_Q5', 'J_Q6A', 'J_Q6B', 'J_Q6C', 'J_Q6D', 'J_Q6E', 'J_Q7A', 'J_Q8', 'J_Q9A', 'J_Q9B',
      'K_Q1A',
      'L_Q2',
      'M_Q1A',
      'N_Q1',
      'O_Q1',
    ]

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
      i_q2g1: nil,
      i_q2h1: nil,
      i_q2i1: nil,
      i_q2j1: nil,
      i_q2k1: nil,
      i_q2l1: nil,
      i_q2m1: nil,
      i_q2n1: nil,
      i_q2o1: nil,
      i_q2p1: nil,
      i_q2q1: nil,
      i_q2r1: nil,
      i_q2s1: nil,
      i_q2t1: nil,
      i_q2u1: nil,
      i_q2v1: nil,
      i_q2w1: nil,
      i_q2x1: nil,
      i_q2y1: nil,
      i_q2z1: nil,

      i_q2a2: indicators,
      i_q2b2: indicators,
      i_q2c2: indicators,
      i_q2d2: indicators,
      i_q2e2: indicators,
      i_q2f2: indicators,
      i_q2g2: indicators,
      i_q2h2: indicators,
      i_q2i2: indicators,
      i_q2j2: indicators,
      i_q2k2: indicators,
      i_q2l2: indicators,
      i_q2m2: indicators,
      i_q2n2: indicators,
      i_q2o2: indicators,
      i_q2p2: indicators,
      i_q2q2: indicators,
      i_q2r2: indicators,
      i_q2s2: indicators,
      i_q2t2: indicators,
      i_q2u2: indicators,
      i_q2v2: indicators,
      i_q2w2: indicators,
      i_q2x2: indicators,
      i_q2y2: indicators,
      i_q2z2: indicators,

      i_q2a3: nil,
      i_q2b3: nil,
      i_q2c3: nil,
      i_q2d3: nil,
      i_q2e3: nil,
      i_q2f3: nil,
      i_q2g3: nil,
      i_q2h3: nil,
      i_q2i3: nil,
      i_q2j3: nil,
      i_q2k3: nil,
      i_q2l3: nil,
      i_q2m3: nil,
      i_q2n3: nil,
      i_q2o3: nil,
      i_q2p3: nil,
      i_q2q3: nil,
      i_q2r3: nil,
      i_q2s3: nil,
      i_q2t3: nil,
      i_q2u3: nil,
      i_q2v3: nil,
      i_q2w3: nil,
      i_q2x3: nil,
      i_q2y3: nil,
      i_q2z3: nil,

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

      l_q1s6a: nil,
      l_q1s6b: nil,
      l_q1s6c: units,
      l_q1s6d: routes,
      l_q1s6e: freq,
      l_q1s6f: prn,
      l_q1s6g: nil,

      l_q1s7a: nil,
      l_q1s7b: nil,
      l_q1s7c: units,
      l_q1s7d: routes,
      l_q1s7e: freq,
      l_q1s7f: prn,
      l_q1s7g: nil,

      l_q1s8a: nil,
      l_q1s8b: nil,
      l_q1s8c: units,
      l_q1s8d: routes,
      l_q1s8e: freq,
      l_q1s8f: prn,
      l_q1s8g: nil,

      l_q1s9a: nil,
      l_q1s9b: nil,
      l_q1s9c: units,
      l_q1s9d: routes,
      l_q1s9e: freq,
      l_q1s9f: prn,
      l_q1s9g: nil,

      l_q1s10a: nil,
      l_q1s10b: nil,
      l_q1s10c: units,
      l_q1s10d: routes,
      l_q1s10e: freq,
      l_q1s10f: prn,
      l_q1s10g: nil,

      l_q1s11a: nil,
      l_q1s11b: nil,
      l_q1s11c: units,
      l_q1s11d: routes,
      l_q1s11e: freq,
      l_q1s11f: prn,
      l_q1s11g: nil,

      l_q1s12a: nil,
      l_q1s12b: nil,
      l_q1s12c: units,
      l_q1s12d: routes,
      l_q1s12e: freq,
      l_q1s12f: prn,
      l_q1s12g: nil,

      l_q1s13a: nil,
      l_q1s13b: nil,
      l_q1s13c: units,
      l_q1s13d: routes,
      l_q1s13e: freq,
      l_q1s13f: prn,
      l_q1s13g: nil,

      l_q1s14a: nil,
      l_q1s14b: nil,
      l_q1s14c: units,
      l_q1s14d: routes,
      l_q1s14e: freq,
      l_q1s14f: prn,
      l_q1s14g: nil,

      l_q1s15a: nil,
      l_q1s15b: nil,
      l_q1s15c: units,
      l_q1s15d: routes,
      l_q1s15e: freq,
      l_q1s15f: prn,
      l_q1s15g: nil,

      l_q1s16a: nil,
      l_q1s16b: nil,
      l_q1s16c: units,
      l_q1s16d: routes,
      l_q1s16e: freq,
      l_q1s16f: prn,
      l_q1s16g: nil,

      l_q1s17a: nil,
      l_q1s17b: nil,
      l_q1s17c: units,
      l_q1s17d: routes,
      l_q1s17e: freq,
      l_q1s17f: prn,
      l_q1s17g: nil,

      l_q1s18a: nil,
      l_q1s18b: nil,
      l_q1s18c: units,
      l_q1s18d: routes,
      l_q1s18e: freq,
      l_q1s18f: prn,
      l_q1s18g: nil,

      l_q1s19a: nil,
      l_q1s19b: nil,
      l_q1s19c: units,
      l_q1s19d: routes,
      l_q1s19e: freq,
      l_q1s19f: prn,
      l_q1s19g: nil,

      l_q1s20a: nil,
      l_q1s20b: nil,
      l_q1s20c: units,
      l_q1s20d: routes,
      l_q1s20e: freq,
      l_q1s20f: prn,
      l_q1s20g: nil,

      l_q1s21a: nil,
      l_q1s21b: nil,
      l_q1s21c: units,
      l_q1s21d: routes,
      l_q1s21e: freq,
      l_q1s21f: prn,
      l_q1s21g: nil,

      l_q1s22a: nil,
      l_q1s22b: nil,
      l_q1s22c: units,
      l_q1s22d: routes,
      l_q1s22e: freq,
      l_q1s22f: prn,
      l_q1s22g: nil,

      l_q1s23a: nil,
      l_q1s23b: nil,
      l_q1s23c: units,
      l_q1s23d: routes,
      l_q1s23e: freq,
      l_q1s23f: prn,
      l_q1s23g: nil,

      l_q1s24a: nil,
      l_q1s24b: nil,
      l_q1s24c: units,
      l_q1s24d: routes,
      l_q1s24e: freq,
      l_q1s24f: prn,
      l_q1s24g: nil,

      l_q1s25a: nil,
      l_q1s25b: nil,
      l_q1s25c: units,
      l_q1s25d: routes,
      l_q1s25e: freq,
      l_q1s25f: prn,
      l_q1s25g: nil,

      l_q1s26a: nil,
      l_q1s26b: nil,
      l_q1s26c: units,
      l_q1s26d: routes,
      l_q1s26e: freq,
      l_q1s26f: prn,
      l_q1s26g: nil,

      l_q1s27a: nil,
      l_q1s27b: nil,
      l_q1s27c: units,
      l_q1s27d: routes,
      l_q1s27e: freq,
      l_q1s27f: prn,
      l_q1s27g: nil,

      l_q1s28a: nil,
      l_q1s28b: nil,
      l_q1s28c: units,
      l_q1s28d: routes,
      l_q1s28e: freq,
      l_q1s28f: prn,
      l_q1s28g: nil,

      l_q1s29a: nil,
      l_q1s29b: nil,
      l_q1s29c: units,
      l_q1s29d: routes,
      l_q1s29e: freq,
      l_q1s29f: prn,
      l_q1s29g: nil,

      l_q1s30a: nil,
      l_q1s30b: nil,
      l_q1s30c: units,
      l_q1s30d: routes,
      l_q1s30e: freq,
      l_q1s30f: prn,
      l_q1s30g: nil,

      l_q1s31a: nil,
      l_q1s31b: nil,
      l_q1s31c: units,
      l_q1s31d: routes,
      l_q1s31e: freq,
      l_q1s31f: prn,
      l_q1s31g: nil,

      l_q1s32a: nil,
      l_q1s32b: nil,
      l_q1s32c: units,
      l_q1s32d: routes,
      l_q1s32e: freq,
      l_q1s32f: prn,
      l_q1s32g: nil,

      l_q1s33a: nil,
      l_q1s33b: nil,
      l_q1s33c: units,
      l_q1s33d: routes,
      l_q1s33e: freq,
      l_q1s33f: prn,
      l_q1s33g: nil,

      l_q1s34a: nil,
      l_q1s34b: nil,
      l_q1s34c: units,
      l_q1s34d: routes,
      l_q1s34e: freq,
      l_q1s34f: prn,
      l_q1s34g: nil,

      l_q1s35a: nil,
      l_q1s35b: nil,
      l_q1s35c: units,
      l_q1s35d: routes,
      l_q1s35e: freq,
      l_q1s35f: prn,
      l_q1s35g: nil,

      l_q1s36a: nil,
      l_q1s36b: nil,
      l_q1s36c: units,
      l_q1s36d: routes,
      l_q1s36e: freq,
      l_q1s36f: prn,
      l_q1s36g: nil,

      l_q1s37a: nil,
      l_q1s37b: nil,
      l_q1s37c: units,
      l_q1s37d: routes,
      l_q1s37e: freq,
      l_q1s37f: prn,
      l_q1s37g: nil,

      l_q1s38a: nil,
      l_q1s38b: nil,
      l_q1s38c: units,
      l_q1s38d: routes,
      l_q1s38e: freq,
      l_q1s38f: prn,
      l_q1s38g: nil,

      l_q1s39a: nil,
      l_q1s39b: nil,
      l_q1s39c: units,
      l_q1s39d: routes,
      l_q1s39e: freq,
      l_q1s39f: prn,
      l_q1s39g: nil,

      l_q1s40a: nil,
      l_q1s40b: nil,
      l_q1s40c: units,
      l_q1s40d: routes,
      l_q1s40e: freq,
      l_q1s40f: prn,
      l_q1s40g: nil,

      l_q1s41a: nil,
      l_q1s41b: nil,
      l_q1s41c: units,
      l_q1s41d: routes,
      l_q1s41e: freq,
      l_q1s41f: prn,
      l_q1s41g: nil,

      l_q1s42a: nil,
      l_q1s42b: nil,
      l_q1s42c: units,
      l_q1s42d: routes,
      l_q1s42e: freq,
      l_q1s42f: prn,
      l_q1s42g: nil,

      l_q1s43a: nil,
      l_q1s43b: nil,
      l_q1s43c: units,
      l_q1s43d: routes,
      l_q1s43e: freq,
      l_q1s43f: prn,
      l_q1s43g: nil,

      l_q1s44a: nil,
      l_q1s44b: nil,
      l_q1s44c: units,
      l_q1s44d: routes,
      l_q1s44e: freq,
      l_q1s44f: prn,
      l_q1s44g: nil,

      l_q1s45a: nil,
      l_q1s45b: nil,
      l_q1s45c: units,
      l_q1s45d: routes,
      l_q1s45e: freq,
      l_q1s45f: prn,
      l_q1s45g: nil,

      l_q1s46a: nil,
      l_q1s46b: nil,
      l_q1s46c: units,
      l_q1s46d: routes,
      l_q1s46e: freq,
      l_q1s46f: prn,
      l_q1s46g: nil,

      l_q1s47a: nil,
      l_q1s47b: nil,
      l_q1s47c: units,
      l_q1s47d: routes,
      l_q1s47e: freq,
      l_q1s47f: prn,
      l_q1s47g: nil,

      l_q1s48a: nil,
      l_q1s48b: nil,
      l_q1s48c: units,
      l_q1s48d: routes,
      l_q1s48e: freq,
      l_q1s48f: prn,
      l_q1s48g: nil,

      l_q1s49a: nil,
      l_q1s49b: nil,
      l_q1s49c: units,
      l_q1s49d: routes,
      l_q1s49e: freq,
      l_q1s49f: prn,
      l_q1s49g: nil,

      l_q1s50a: nil,
      l_q1s50b: nil,
      l_q1s50c: units,
      l_q1s50d: routes,
      l_q1s50e: freq,
      l_q1s50f: prn,
      l_q1s50g: nil,

      l_q2: answers_for(section: 'L', question: 2, number: 2),

      m_q1a: (indicators = answers_for(section: 'M', question: '1A', number: 2)),
      m_q1b: indicators,
      m_q1c: indicators,
      m_q1d: indicators,
      m_q1e: indicators,
      m_q1f: indicators,
      m_q1g: indicators,
      m_q1h: indicators,

      m_q2a: nil,
      m_q2b: nil,
      m_q2c: nil,

      n_q1: answers_for(section: 'N', question: 1, number: 2),

      o_q1: answers_for(section: 'O', question: 1, number: 2),

      p_q1: nil,
      p_q2: answers_for(section: 'P', question: 2, number: 15),

      q_q1: nil,
      q_q2: nil,

      r_q1: answers_for(section: 'R', question: 1, number: 4),
      r_q1a: nil,
      r_q1b: nil,
      r_q1c: nil,
      r_q1d: nil,
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
    belongs_to :user, optional: true
    belongs_to :reviewed_by, class_name: 'User', optional: true

    has_one :health_file, class_name: 'Health::ComprehensiveHealthAssessmentFile', foreign_key: :parent_id, dependent: :destroy
    include HealthFiles

    enum status: {not_started: 0, in_progress: 1, complete: 2}

    scope :recent, -> { order(updated_at: :desc).limit(1) }
    scope :reviewed, -> { where.not(reviewed_by_id: nil) }
    scope :incomplete, -> { where(completed_at: nil, reviewed_by_id: nil)}
    scope :complete, -> { where.not(completed_at: nil) }
    scope :completed, -> { complete }

    scope :active, -> do
      reviewed.where(arel_table[:completed_at].gteq(1.years.ago))
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
              hpr_t[:enrollment_start_date].lt(Arel.sql("#{arel_table[:completed_at].to_sql} + INTERVAL '1 year'"))
            )
        )
    end

    # first completed CHA form for each patient
    scope :first_completed, -> do
      where(
        id: order(
          :patient_id,
          completed_at: :asc
        ).group(:patient_id, :id).distinct_on(:patient_id).select(:id)
      )
    end

    # most recent completed CHA form for each patient
    scope :latest_completed, -> do
      where(
        id: order(
          :patient_id,
          completed_at: :desc
        ).group(:patient_id, :id).distinct_on(:patient_id).select(:id)
      )
    end

    attr_accessor :reviewed_by_supervisor, :completed, :file

    attr_accessor *QUESTION_ANSWER_OPTIONS.keys

    before_save :set_answers, :set_reviewed_at

    validate :validate_health_file_if_present

    def complete?
     completed_at.present?
    end
    alias_method :completed?, :complete?

    def active?
      completed_at && completed_at >= 1.years.ago
    end

    def expires_on
      return unless completed_at

      completed_at.to_date + 1.years
    end

    private def set_reviewed_at
      if reviewed_by
        self.reviewed_at = DateTime.current
      end
    end

    def validate_health_file_if_present
      if file.present? && file.invalid?
        errors.add :file, file.errors.messages.try(:[], :file)&.uniq&.join('; ')
      end
    end

    private def set_answers
      hash = self.answers.dup
      QUESTION_ANSWER_OPTIONS.keys.each do |section_question|
        section_code  = section_question.to_s.upcase.split('_').first
        section       = _("CHA #{section_code}_TITLE")
        section_subtitle = _("CHA #{section_code}_SUBTITLE")
        question      = _("CHA #{section_question.upcase}")
        question_header = ''
        unless "CHA #{section_question.upcase}_HEADER" == _("CHA #{section_question.upcase}_HEADER")
          question_header = _("CHA #{section_question.upcase}_HEADER")
        end
        question_sub_header = ''
        unless "CHA #{section_question.upcase}_SUBHEADER" == _("CHA #{section_question.upcase}_SUBHEADER")
          question_sub_header = _("CHA #{section_question.upcase}_SUBHEADER")
        end
        if matches = section_question.match(/(g_q1.)p$/)
          if code = matches.try(:[], 1)&.upcase
            question_header = _("CHA #{code}_HEADER")
          end
        end
        hash[section_code] ||= {}
        hash[section_code][:title] = section
        hash[section_code][:subtitle] = section_subtitle
        hash[section_code][:answers] ||= {}
        hash[section_code][:answers][section_question] ||= {}
        hash[section_code][:answers][section_question][:question] ||= question
        value = send(section_question)
        hash[section_code][:answers][section_question][:answer] = value if value
        hash[section_code][:answers][section_question][:header] = question_header
        hash[section_code][:answers][section_question][:sub_header] = question_sub_header
      end
      hash['A'][:answers][:a_q1][:answer] = patient.client&.name
      hash['A'][:answers][:a_q3][:answer] ||= patient.client&.DOB
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
      editor&.can_edit_patient_items_for_own_agency? || editor&.has_some_patient_access?
    end

    def phone
      answer(:r_q1a)
    end

    def ssn
      answer(:a_q5a)
    end

    def qualifying_activities
      Health::QualifyingActivity.where(source: self, patient: patient)
    end

    def self.encounter_report_details
      {
        source: 'Warehouse',
      }
    end

    # allow keys, but some keys need to allow multiple checkbox selections (b_q2 & b_q4)
    PERMITTED_PARAMS = QUESTION_ANSWER_OPTIONS.keys - [:b_q2, :b_q4, :r_q8] + [{ b_q2: [] }, { b_q4: [] }, { r_q8: [] }]

  end
end
