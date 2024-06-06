class HmisExternalApis::TcHmis::Importers::SpdatAssessmentFormDefinitionBuilder < HmisUtil::CustomAssessmentFormDefinitionBuilder
  def perform
    form_definition = Hmis::Form::Definition.where(
      identifier: 'tc-spdat',
      role: 'CUSTOM_ASSESSMENT',
      version: 0,
      status: Hmis::Form::Definition::DRAFT,
    ).first_or_initialize

    @score_questions = []
    content = build_content(prefix: 'spdat') do
      JSON.parse({ item: [
        assessment_group,
        # page 1
        mental_health_group,
        physical_health_group,
        medication_group,
        substance_use_group,
        # page 2
        abuse_and_trauma_group,
        risk_of_harm_group,
        risky_or_exploitive_situations_group,
        emergency_services_group,
        # page 3
        legal_group,
        managing_tenancy_group,
        money_management_group,
        social_relationships_group,
        # page 4
        life_skills_group,
        meaningful_activity_group,
        history_of_homelessness_group,
        spdat_group,
      ] }.to_json)
    end

    HmisUtil::JsonForms.new.validate_definition(content)
    form_definition.definition = content
    form_definition.save!
  end

  def new_score_question(...)
    item = super(...)
    @score_questions << item
    item
  end

  def assessment_group
    absent_question = assessment_is_for_absent_client
    new_group_item(
      title: 'Assessment',
      children: [
        new_date_question(title: 'Assessment Date', assessment_date: true, required: true),
        absent_question,
        assessment_absent_days(conditional_id: absent_question.link_id),
        assessment_event,
      ],
    )
  end

  def assessment_is_for_absent_client
    new_yes_no_question(
      title: 'Is this assessment being completed for a dismissed client or a client who is no longer in contact?',
      required: true,
      cded: register_cded(key: __callee__),
    )
  end

  def assessment_absent_days(conditional_id:)
    new_integer_question(
      title: 'How long has the client been out of contact (in days)?',
      cded: register_cded(key: __callee__, field_type: 'integer'),
      extra_attrs: {
        'enable_behavior' => 'ALL',
        'enable_when' => [
          {
            'question' => conditional_id,
            'operator' => 'EQUAL',
            'answer_code' => 'YES',
          },
        ],
      },
    )
  end

  def spdat_group
    new_group_item(
      title: 'Assessment Details & Score',
      children: [
        new_integer_question(title: 'Time Spent (Minutes)', cded: register_cded(key: 'time_spent_minutes', field_type: 'integer')),
        new_integer_question(title: 'Travel Time (Minutes)', cded: register_cded(key: 'travel_time_minutes', field_type: 'integer'), required: false),
        client_contact_location_and_method,
        new_text_question(
          title: 'SPDAT Notes',
          cded: register_cded(key: 'score_notes'),
          required: false,
        ),
        new_score_display(
          cded: register_cded(key: 'total_score', field_type: 'integer'),
          visible_when_read_only: true,
          sum_questions: @score_questions.map(&:link_id),
          content: new_list(
            title: '<h2>SPDAT Score: ${value}</h2>',
            items: [
              '0-19: No housing intervention',
              '20-39: Rapid Re-Housing',
              '40-60: Permanent Supportive Housing/Housing First',
            ],
          ),
        ),
      ],
    )
  end

  def client_contact_location_and_method
    new_select_question(title: 'Contact Location / Method', required: true).tap do |question|
      question.cded = register_cded(key: __callee__)
      [
        { code: "Face to face - Worker's Office" },
        { code: 'Face to face - Community' },
        { code: "Face to face - Landlord's Office" },
        { code: 'Face to face - Other Professional Provider' },
        { code: 'Face to face - Client No Show' },
        { code: 'Phone - Conversation' },
        { code: 'Phone - Message Left' },
        { code: 'Phone - No Answer/No Message' },
        { code: 'Social Media' },
        { code: 'Text Message' },
        { code: 'Email' },
        { code: 'Letter/Note' },
      ].each do |attrs|
        question.add_choice(**attrs)
      end
    end
  end

  def assessment_event
    new_select_question(title: 'Which SPDAT is this?', required: true).tap do |question|
      question.cded = register_cded(key: __callee__)
      [
        { code: 'Intake' },
        { code: 'Housing' },
        { code: '30 Days' },
        { code: '3 Months' },
        { code: '6 Months' },
        { code: '9 Months' },
        { code: '12 Months' },
        { code: '15 Months' },
        { code: '18 Months' },
        { code: '21 Months' },
        { code: '24 Months' },
        { code: 'Re-Housing' },
        { code: 'Significant Change' },
        { code: 'Exit' },
      ].each do |attrs|
        question.add_choice(**attrs)
      end
    end
  end

  def mental_health_group
    new_group_item(
      title: 'Mental Health & Wellness & Cognitive Functioning',
      children: [
        mental_health_prompts,
        mental_health_score,
        mental_health_notes,
      ],
    )
  end

  def mental_health_prompts
    new_display_item(
      content: new_list(
        title: 'Mental Health & Wellness & Cognitive Functioning Prompts',
        items: [
          'Have you ever received any help with your mental wellness?',
          'Do you feel you are getting all the help you need for your mental health or stress?',
          'Has a doctor ever prescribed you pills for nerves, anxiety, depression or anything like that?',
          "Have you ever gone to an emergency room or stayed in a hospital because you weren't feeling 100% emotionally?",
          'Do you have trouble learning or paying attention?',
          'Have you ever had testing done to identify learning disabilities?',
          'Do you know if, when pregnant with you, your mother did anything that we now know can have negative effects on the baby?',
          'Have you ever hurt your brain or head?',
          'Do you have any documents or papers about your mental health or brain functioning?',
          'Are there other professionals we could speak with that have knowledge of your mental health?',
        ],
      ),
    )
  end

  def mental_health_score
    new_score_question(title: 'Mental Health & Wellness & Cognitive Functioning Scoring').tap do |question|
      question.cded = register_cded(key: __callee__)
      question.add_score_choice(
        score: 4,
        help: new_list(
          title: '<em>Any</em> of the following',
          items: [
            'Serious and persistent mental illness (2+ hospitalizations in a mental facility or psychiatric ward in the past 2 years) and not in a heightened state of recovery currently',
            'Major barriers to performing tasks and functions of daily living or communicating intent because of a brain injury, learning disability or developmental disability',
          ],
        ),
      )
      question.add_score_choice(
        score: 3,
        help: new_list(
          title: '<em>Any</em> of the following',
          items: [
            'Heightened concerns about state of mental health, but fewer than 2 hospitalizations, and/or without knowledge of presence of a diagnosable mental health condition',
            'Diminished ability to perform tasks and functions of daily living or communicating intent because of a brain injury, learning disability or developmental disability',
          ],
        ),
      )
      question.add_score_choice(
        score: 2,
        help: new_list(
          title: 'While there may be concern for overall mental health or mild impairments to performing tasks and functions of daily living or communicating intent, <em>all</em> of the following are true',
          items: [
            'No major concerns about safety or ability to be housed without intensive supports to assist with mental health or cognitive functioning',
            'No major concerns for the health and safety of others because of mental health or cognitive functioning ability',
            'No compelling reason for screening by an expert in mental health or cognitive functioning prior to housing to fully understand capacity',
          ],
        ),
      )
      question.add_score_choice(
        score: 1,
        help: 'In a heightened state of recovery, has a Wellness Recovery Action Plan (WRAP) or similar plan for promoting wellness, understands symptoms and strategies for coping with them, <em>and</em> is engaged with mental health supports as necessary',
      )
      question.add_score_choice(
        score: 0,
        help: 'No mental health or cognitive functioning issues disclosed, suspected or observed',
      )
    end
  end

  def mental_health_notes
    new_text_question(title: 'Mental Health & Wellness & Cognitive Functioning Notes').tap do |question|
      question.cded = register_cded(key: __callee__)
    end
  end

  def physical_health_group
    new_group_item(
      title: 'Physical Health & Wellness',
      children: [
        physical_health_prompts,
        physical_health_score,
        physical_health_notes,
      ],
    )
  end

  def physical_health_prompts
    new_display_item(
      content: new_list(
        title: 'Physical Health & Wellness Prompts',
        items: [
          'How is your health?',
          'Are you getting any help with your health? How often?',
          'Do you feel you are getting all the care you need for your health?',
          'Any illness like diabetes, HIV, Hep C or anything like that going on?',
          'Ever had a doctor tell you that you have problems with blood pressure or heart or lungs or anything like that?',
          'When was the last time you saw a doctor? What was that for?',
          'Do you have a clinic or doctor that you usually go to?',
          'Anything going on right now with your health that you think would prevent you from living a full, healthy, happy life?',
          'Are there other professionals we could speak with that have knowledge of your health?',
          'Do you have any documents or papers about your health or past stays in hospital because of your health?',
        ],
      ),
    )
  end

  def physical_health_score
    new_score_question(title: 'Physical Health & Wellness Scoring').tap do |question|
      question.cded = register_cded(key: __callee__)
      question.add_score_choice(
        score: 4,
        help: new_list(
          title: '<em>Any</em> of the following',
          items: [
            'Co-occurring chronic health conditions',
            'Attempting a treatment protocol for a chronic health condition, but the treatment is not improving health',
            'Palliative health condition',
          ],
        ),
      )
      question.add_score_choice(
        score: 3,
        help: new_list(
          title: 'Presence of a health issue with <em>any</em> of the following',
          items: [
            'Not connected with professional resources to assist with a real or perceived serious health issue, by choice',
            'Single chronic or serious health concern but does not connect with professional resources because of insufficient community resources (e.g. lack of availability or affordability)',
            'Unable to follow the treatment plan as a direct result of homeless status',
          ],
        ),
      )
      question.add_score_choice(
        score: 2,
        help: new_html('Presence of a relatively minor physical issue, which is managed and/or cared for with appropriate professional resources or through informed self-care. <em>Or</em>, Presence of a physical health issue, for which appropriate treatment protocols are followed, but there is still a moderate impact on their daily living'),
      )
      question.add_score_choice(
        score: 1,
        help: new_list(
          title: 'Single chronic or serious health condition, but all of the following are true',
          items: [
            'Able to manage the health issue and live a relatively active and healthy life',
            'Connected to appropriate health supports',
            'Educated and informed on how to manage the health issue, take medication as necessary related to the condition, and consistently follow these requirements',
          ],
        ),
      )
      question.add_score_choice(
        score: 0,
        help: new_html('No serious or chronic health condition disclosed, observed or suspected. <em>Or</em>, if any minor health condition, they are managed appropriately'),
      )
    end
  end

  def physical_health_notes
    new_text_question(title: 'Physical Health & Wellness Notes').tap do |question|
      question.cded = register_cded(key: 'physical_health_notes')
    end
  end

  def medication_group
    new_group_item(
      title: 'Medication',
      children: [
        medication_prompts,
        medication_score,
        medication_notes,
      ],
    )
  end

  def medication_prompts
    new_display_item(
      content: new_list(
        title: 'Medication Prompts',
        items: [
          'Have you recently been prescribed any medications by a health care professional?',
          'Do you take any medications prescribed to you by a doctor?',
          'Have you ever sold some or all of your prescription?',
          'Have you ever had a doctor prescribe you medication that you didn’t have filled at a pharmacy or didn’t take?',
          'Were any of your medications changed in the last month? If yes: How did that make you feel?',
          'Do other people ever steal your medications?',
          'Do you ever share your medications with other people?',
          'How do you store your medications and make sure you take the right medication at the right time each day?',
          'What do you do if you realize you’ve forgotten to take your medications? Do you have any papers or documents about the medications you take?',
        ],
      ),
    )
  end

  def medication_score
    new_score_question(title: 'Medication Scoring').tap do |question|
      question.cded = register_cded(key: __callee__)
      question.add_score_choice(
        score: 4,
        help: new_list(
          title: '<em>Any</em> of the following',
          items: [
            'In the past 30 days, started taking prescription which is having a negative impact on day to day living socialization or mood',
            'Shares or sells prescription, but keeps less than is sold or shared',
            'Regularly misuses medication (e.g. frequently forgets; often takes the wrong dosage; uses some or all of medication to get high)',
            'Has had a medication prescribed in the last 90 days that remains unfilled, for any reason',
          ],
        ),
      )
      question.add_score_choice(
        score: 3,
        help: new_list(
          title: '<em>Any</em> of the following',
          items: [
            'In the past 30 days, started taking prescription which is not having a negative impact on day to day living, socialization or mood',
            'Shares or sells prescription, but keeps more than is sold or shared',
            'Requires intensive assistance to manage or take medications (e.g., assistance organizing in a pillbox; working with pharmacist to blister-pack; adapting the living environment to be more conductive to taking medications at the right time for the right purpose, like keeping nighttime medications on the bedside table and morning medications by the coffeemaker)',
            'Medications are stored and distributed by a third party',
          ],
        ),
      )
      question.add_score_choice(
        score: 2,
        help: new_list(
          title: '<em>Any</em> of the following',
          items: [
            'Fails to take medication at the appropriate time or appropriate dosage, 1-2 times per week',
            'Self-manages medications except for requiring reminders of assistance for refills',
            'Successfully self-managing medication for fewer than 30 consecutive days',
          ],
        ),
      )
      question.add_score_choice(
        score: 1,
        help: 'Successfully self-managing medications for more than 30, but less than 180, consecutive days',
      )
      question.add_score_choice(
        score: 0,
        help: new_list(
          title: '<em>Any</em> of the following',
          items: [
            'No medication prescribed to them',
            'Successfully self-managing medication for 181+ consecutive days',
          ],
        ),
      )
    end
  end

  def medication_notes
    new_text_question(title: 'Medication Notes').tap do |question|
      question.cded = register_cded(key: __callee__)
    end
  end

  def substance_use_group
    new_group_item(
      title: 'Substance Use',
      children: [
        substance_use_prompts,
        substance_use_score,
        substance_use_notes,
      ],
    )
  end

  def substance_use_prompts
    new_display_item(
      content: new_list(
        title: 'Substance Use Prompts',
        items: [
          'When was the last time you had a drink or used drugs?',
          'Is there anything we should keep in mind related to drugs or alcohol?',
          '[If they disclose use of drugs and/or alcohol] How frequently would you say you use [specific substance] in a week?',
          'Ever have a doctor tell you that your health may be at risk because you drink or use drugs? Have you engaged with anyone professionally related to your substance use that we could speak with?',
          'Ever get into fights, fall down and bang your head, or pass out when drinking or using other drugs?',
          'Have you ever used alcohol or other drugs in a way that may be considered less than safe?',
          'Do you ever end up doing things you later regret after you have gotten really hammered?',
          'Do you ever drink mouthwash or cooking wine or hand sanitizer or anything like that?',
        ],
      ),
    )
  end

  def substance_use_score
    new_score_question(title: 'Substance Use Scoring').tap do |question|
      question.cded = register_cded(key: __callee__)
      question.add_score_choice(
        score: 4,
        help: new_list(
          title: 'In a life-threatening health situation as a direct result of substance use, <em>or</em>, in the past 30 days, <em>any</em> of the following are true',
          items: [
            'Substance use is almost daily (21+ times) <em>and</em> often to the point of complete inebriation',
            'Binge drinking, non-beverage alcohol use, or inhalant use 4+ times',
            'Substance use resulting in passing out 2+ times',
          ],
        ),
      )
      question.add_score_choice(
        score: 3,
        help: new_list(
          title: 'Experiencing serious health impacts as a direct result of substance use, though not (yet) in a life-threatening position as a result, or, In the past 30 days, any of the following are true:',
          items: [
            'Drug use reached the point of complete inebriation 12+ times',
            'Alcohol use usually exceeded the consumption threshold (at least 5+ times), but usually not to the point of complete inebriation',
            'Binge drinking, non-beverage alcohol use, or inhalant use 1-3 times',
          ],
        ),
      )
      question.add_score_choice(
        score: 2,
        help: new_list(
          title: 'In the past 30 days, <em>any</em> of the following are true:',
          items: [
            'Drug use reached the point of complete inebriation fewer than 12 times',
            'Alcohol use exceeded the consumption threshold fewer than 5 times',
          ],
        ),
      )
      question.add_score_choice(
        score: 1,
        help: 'In the past 365 days, no alcohol use beyond consumption threshold, <em>or</em>, If making claims to sobriety, no substance use in the past 30 days',
      )
      question.add_score_choice(
        score: 0,
        help: 'In the past 365 days, no substance use',
      )
    end
  end

  def substance_use_notes
    new_text_question(title: 'Substance Use Notes').tap do |question|
      question.cded = register_cded(key: __callee__)
    end
  end

  def abuse_and_trauma_group
    new_group_item(
      title: 'Experience of Abuse & Trauma',
      children: [
        abuse_and_trauma_preamble,
        abuse_and_trauma_prompts,
        abuse_and_trauma_score,
        abuse_and_trauma_notes,
      ],
    )
  end

  def abuse_and_trauma_preamble
    new_display_item(
      content: new_html('<em>To avoid re-traumatizing the participant, ask selected approved questions as written. Do not probe for details of the trauma/abuse. This section is entirely self-reported.</em>'),
    )
  end

  def abuse_and_trauma_prompts
    new_display_item(
      content: new_list(
        title: 'Experience of Abuse & Trauma Prompts',
        items: [
          '“I don’t need you to go into any details, but has there been any point in your life where you experienced emotional, physical, sexual or psychological abuse?”',
          '“Are you currently or have you ever received professional assistance to address that abuse?”',
          '“Does the experience of abuse or trauma impact your day to day living in any way?”',
          '“Does the experience of abuse or trauma impact your ability to hold down a job, maintain housing or engage in meaningful relationships with friends or family?”',
          '“Have you ever found yourself feeling or acting in a certain way that you think is caused by a history of abuse or trauma?”',
          '“Have you ever become homeless as a direct result of experiencing abuse or trauma?”',
        ],
      ),
    )
  end

  def abuse_and_trauma_score
    new_score_question(title: 'Experience of Abuse & Trauma Scoring').tap do |question|
      question.cded = register_cded(key: __callee__)
      question.add_score_choice(
        score: 4,
        help: 'A reported experience of abuse or trauma, believed to be a direct cause of their homelessness',
      )
      question.add_score_choice(
        score: 3,
        help: new_html('The experience of abuse or trauma is <em>not</em> believed to be a direct cause of homelessness, but abuse or trauma (experienced before, during, or after homelessness) <em>is</em> impacting daily functioning and/or ability to get out of homelessness'),
      )
      question.add_score_choice(
        score: 2,
        help: new_list(
          title: '<em>Any</em> of the following',
          items: [
            'A reported experience of abuse or trauma, but is not believed to impact daily functioning and/or ability to get out of homelessness',
            'Engaged in therapeutic attempts at recovery, but does not consider self to be recovered',
          ],
        ),
      )
      question.add_score_choice(
        score: 1,
        help: 'A reported experience of abuse or trauma, and considers self to be recovered',
      )
      question.add_score_choice(
        score: 0,
        help: 'No reported experience of abuse or trauma',
      )
    end
  end

  def abuse_and_trauma_notes
    new_text_question(title: 'Experience of Abuse & Trauma  Notes').tap do |question|
      question.cded = register_cded(key: __callee__)
    end
  end

  def risk_of_harm_group
    new_group_item(
      title: 'Risk of Harm to Self or Others Prompts',
      children: [
        risk_of_harm_prompts,
        risk_of_harm_score,
        risk_of_harm_notes,
      ],
    )
  end

  def risk_of_harm_prompts
    new_display_item(
      content: new_list(
        title: 'Risk of Harm to Self or Others Prompts',
        items: [
          'Do you have thoughts about hurting yourself or anyone else? Have you ever acted on these thoughts? When was the last time?',
          'What was occurring when you had these feelings or took these actions?',
          'Have you ever received professional help – including maybe a stay at hospital – as a result of thinking about or attempting to hurt yourself or others? How long ago was that? Does that happen often?',
          'Have you recently left a situation you felt was abusive or unsafe? How long ago was that? Have you been in any fights recently - whether you started it or someone else did? How long ago was that? How often do you get into fights?',
        ],
      ),
    )
  end

  def risk_of_harm_score
    new_score_question(title: 'Experience of Abuse & Trauma Scoring').tap do |question|
      question.cded = register_cded(key: __callee__)
      question.add_score_choice(
        score: 4,
        help: new_list(
          title: '<em>Any</em> of the following',
          items: [
            'In the past 90 days, left an abusive situation',
            'In the past 90 days, attempted, threatened, or actually harmed self or others',
            'In the past 30 days, involved in a physical altercation (instigator or participant)',
          ],
        ),
      )
      question.add_score_choice(
        score: 3,
        help: new_list(
          title: '<em>Any</em> of the following',
          items: [
            'In the past 180 days, left an abusive situation, but no exposure to abuse in the past 90 days',
            'Most recently attempted, threatened, or actually harmed self or others in the past 180 days, but not in the past 30 days',
            'In the past 365 days, involved in a physical altercation (instigator or participant), but not in the past 30 days',
          ],
        ),
      )
      question.add_score_choice(
        score: 2,
        help: new_list(
          title: '<em>Any</em> of the following',
          items: [
            'In the past 365 days, left an abusive situation, but no exposure to abuse in the past 180 days',
            'Most recently attempted, threatened or actually harmed self or others in the past 365 days, but not in the past 180 days',
            '366+ days ago, 4+ involvements in physical altercations',
          ],
        ),
      )
      question.add_score_choice(
        score: 1,
        help: '366+ days ago, 1-3 involvements in physical alterations',
      )
      question.add_score_choice(
        score: 0,
        help: 'Reports no instance of harming self, being harmed, or harming others',
      )
    end
  end

  def risk_of_harm_notes
    new_text_question(title: 'Risk of Harm to Self or Others Notes').tap do |question|
      question.cded = register_cded(key: __callee__)
    end
  end

  def risky_or_exploitive_situations_group
    new_group_item(
      title: 'Involvement in Higher Risk and/or Exploitive Situations',
      children: [
        risky_or_exploitive_situations_prompts,
        risky_or_exploitive_situations_score,
        risky_or_exploitive_situations_notes,
      ],
    )
  end

  def risky_or_exploitive_situations_prompts
    new_display_item(
      content: new_list(
        title: 'Involvement in Higher Risk and/or Exploitive Situations Prompts',
        items: [
          'Does anybody force or trick you to do something that you don’t want to do?',
          'Do you ever do stuff that could be considered dangerous like drinking until you pass out outside, or delivering drugs for someone, having sex without a condom with a casual partner, or anything like that?',
          'Do you ever find yourself in situations that may be considered at a high risk for violence?',
          'Do you ever sleep outside? How do you dress and prepare for that? Where do you tend to sleep?',
        ],
      ),
    )
  end

  def risky_or_exploitive_situations_score
    new_score_question(title: 'Involvement in Higher Risk and/or Exploitive Situations Scoring').tap do |question|
      question.cded = register_cded(key: __callee__)
      question.add_score_choice(
        score: 4,
        help: new_list(
          title: '<em>Any</em> of the following',
          items: [
            'In the past 90 days, left an abusive situation',
            'In the past 90 days, attempted, threatened, or actually harmed self or others',
            'In the past 30 days, involved in a physical altercation (instigator or participant)',
          ],
        ),
      )
      question.add_score_choice(
        score: 3,
        help: new_list(
          title: '<em>Any</em> of the following',
          items: [
            'In the past 180 days, engaged in 4-9 higher risk and/or exploitive events',
            'In the past 180 days, left an abusive situation, but not in the past 90 days',
          ],
        ),
      )
      question.add_score_choice(
        score: 2,
        help: new_list(
          title: '<em>Any</em> of the following',
          items: [
            'In the past 180 days, engaged in 1-3 higher risk and/or exploitive events',
            '181+ days ago, left an abusive situation',
          ],
        ),
      )
      question.add_score_choice(
        score: 1,
        help: 'Any involvement in higher risk and/or exploitive situations occurred more than 180 days ago but less than 365 days ago',
      )
      question.add_score_choice(
        score: 0,
        help: 'In the past 365 days, no involvement in higher risk and/or exploitive events',
      )
    end
  end

  def risky_or_exploitive_situations_notes
    new_text_question(title: 'Involvement in Higher Risk and/or Exploitive Situations Notes').tap do |question|
      question.cded = register_cded(key: __callee__)
    end
  end

  def emergency_services_group
    new_group_item(
      title: 'Interaction with Emergency Services',
      children: [
        emergency_services_prompts,
        emergency_services_score,
        emergency_services_notes,
      ],
    )
  end

  def emergency_services_prompts
    new_display_item(
      content: new_list(
        title: 'Interaction with Emergency Services Prompts',
        items: [
          'How often do you go to emergency rooms?',
          'How many times have you had the police speak to you over the past 180 days?',
          'Have you used an ambulance or needed the fire department at any time in the past 180 days?',
          'How many times have you called or visited a crisis team or a crisis counselor in the last 180 days?',
          'How many times have you been admitted to hospital in the last 180 days? How long did you stay?',
        ],
      ),
    )
  end

  def emergency_services_score
    new_score_question(title: 'Interaction with Emergency Services Scoring').tap do |question|
      question.cded = register_cded(key: __callee__)
      question.add_score_choice(
        score: 4,
        help: 'In the past 180 days, cumulative total of 10+ interactions with emergency services',
      )
      question.add_score_choice(
        score: 3,
        help: 'In the past 180 days, cumulative total of 4-9 interactions with emergency services',
      )
      question.add_score_choice(
        score: 2,
        help: 'In the past 180 days, cumulative total of 1-3 interactions with emergency services',
      )
      question.add_score_choice(
        score: 1,
        help: 'Any interaction with emergency services occurred more than 180 days ago but less than 365 days ago',
      )
      question.add_score_choice(
        score: 0,
        help: 'In the past 365 days, no interactions with emergency services',
      )
    end
  end

  def emergency_services_notes
    new_text_question(title: 'Interaction with Emergency Services Notes').tap do |question|
      question.cded = register_cded(key: __callee__)
    end
  end

  def legal_group
    new_group_item(
      title: 'Legal',
      children: [
        legal_services_prompts,
        legal_services_score,
        legal_services_notes,
      ],
    )
  end

  def legal_services_prompts
    new_display_item(
      content: new_list(
        title: 'Legal Prompts',
        items: [
          'Do you have any “legal stuff” going on?',
          'Have you had a lawyer assigned to you by a court?',
          'Do you have any upcoming court dates? Do you think there’s a chance you will do time?',
          'Any involvement with family court or child custody matters?',
          'Any outstanding fines?',
          'Have you paid any fines in the last 12 months for anything?',
          'Have you done any community service in the last 12 months?',
          'Is anybody expecting you to do community service for anything right now?',
          'Did you have any legal stuff in the last year that got dismissed?',
          'Is your housing at risk in any way right now because of legal issues?',
        ],
      ),
    )
  end

  def legal_services_score
    new_score_question(title: 'Legal Scoring').tap do |question|
      question.cded = register_cded(key: __callee__)
      question.add_score_choice(
        score: 4,
        help: new_list(
          title: '<em>Any</em> of the following',
          items: [
            'Current outstanding legal issue(s), likely to result in fines of $500+',
            'Current outstanding legal issue(s), likely to result in incarceration of 3+ months (cumulatively), inclusive of any time held on remand',
          ],
        ),
      )
      question.add_score_choice(
        score: 3,
        help: new_list(
          title: '<em>Any</em> of the following',
          items: [
            'Current outstanding legal issue(s), likely to result in fines less than $500',
            'Current outstanding legal issue(s), likely to result in incarceration of less than 90 days (cumulatively), inclusive of any time held on remand',
          ],
        ),
      )
      question.add_score_choice(
        score: 2,
        help: new_list(
          title: '<em>Any</em> of the following',
          items: [
            'In the past 365 days, relatively minor legal issue has occurred and was resolved through community service or payment of fine(s)',
            'Currently outstanding relatively minor legal issue that is unlikely to result in incarceration (but may result in community service)',
          ],
        ),
      )
      question.add_score_choice(
        score: 1,
        help: 'There are no current legal issues, <em>and</em> any legal issues that have historically occurred have been resolved without community service, payment of fine, or incarceration',
      )
      question.add_score_choice(
        score: 0,
        help: 'No legal issues within the past 365 days, <em>and</em> currently no conditions of release',
      )
    end
  end

  def legal_services_notes
    new_text_question(title: 'Legal Notes').tap do |question|
      question.cded = register_cded(key: __callee__)
    end
  end

  def managing_tenancy_group
    new_group_item(
      title: 'Managing Tenancy',
      children: [
        managing_tenancy_prompts,
        new_display_item(content: 'NOTE: Housing matters include: conflict with landlord and/or neighbors, damages to the unit, payment of rent on time and in full. Payment of rent through a third party is not considered to be a short-coming or deficiency in the ability to pay rent.'),
        managing_tenancy_score,
        managing_tenancy_notes,
      ],
    )
  end

  def managing_tenancy_prompts
    new_display_item(
      content: new_list(
        title: 'Managing Tenancy Prompts',
        items: [
          'Are you currently homeless?',
          '[If the person is housed] Do you have an eviction notice?',
          '[If the person is housed] Do you think that your housing is at risk?',
          'How is your relationship with your neighbors?',
          'How do you normally get along with landlords?',
          'How have you been doing with taking care of your place?',
        ],
      ),
    )
  end

  def managing_tenancy_score
    new_score_question(title: 'Managing Tenancy Scoring').tap do |question|
      question.cded = register_cded(key: __callee__)
      question.add_score_choice(
        score: 4,
        help: new_list(
          title: '<em>Any</em> of the following',
          items: [
            'Currently homeless',
            'In the next 30 days, will be re-housed or return to homelessness',
            'In the past 365 days, was re-housed 6+ times',
            'In the past 90 days, support worker(s) have been cumulatively involved 10+ times with housing matters',
          ],
        ),
      )
      question.add_score_choice(
        score: 3,
        help: new_list(
          title: '<em>Any</em> of the following',
          items: [
            'In the next 60 days, will be re-housed or return to homelessness, but not in the next 30 days',
            'In the past 365 days, was re-housed 3-5 times',
            'In the past 90 days, support worker(s) have been cumulatively involved 4-9 times with housing matters',
          ],
        ),
      )
      question.add_score_choice(
        score: 2,
        help: new_list(
          title: '<em>Any</em> of the following',
          items: [
            'In the past 365 days, was re-housed 2 times',
            'In the past 180 days, was re-housed 1+ times, but not in the past 60 days',
            'Continuously housed for at least 90 days but not more than 180 days',
            'In the past 90 days, support worker(s) have been cumulatively involved 1-3 times with housing matters',
          ],
        ),
      )
      question.add_score_choice(
        score: 1,
        help: new_list(
          title: '<em>Any</em> of the following',
          items: [
            'In the past 365 days, was re-housed 1 time',
            'Continuously housed, with no assistance on housing matters, for at least 180 days but not more than 365 days',
          ],
        ),
      )
      question.add_score_choice(
        score: 0,
        help: 'Continuously housed, with no assistance on housing matters, for at least 365 days',
      )
    end
  end

  def managing_tenancy_notes
    new_text_question(title: 'Managing Tenancy Notes').tap do |question|
      question.cded = register_cded(key: __callee__)
    end
  end

  def money_management_group
    new_group_item(
      title: 'Personal Administration & Money Management',
      children: [
        money_management_prompts,
        money_management_score,
        money_management_notes,
      ],
    )
  end

  def money_management_prompts
    new_display_item(
      content: new_list(
        title: 'Personal Administration & Money Management Prompts',
        items: [
          'How are you with taking care of money?',
          'How are you with paying bills on time and taking care of other financial stuff?',
          'Do you have any street debts?',
          'Do you have any drug or gambling debts?',
          'Is there anybody that thinks you owe them money?',
          'Do you budget every single month for every single thing you need? Including cigarettes? Booze? Drugs?',
          'Do you try to pay your rent before paying for anything else?',
          'Are you behind in any payments like child support or student loans or anything like that?',
        ],
      ),
    )
  end

  def money_management_score
    new_score_question(title: 'Personal Administration & Money Management Scoring').tap do |question|
      question.cded = register_cded(key: __callee__)
      question.add_score_choice(
        score: 4,
        help: new_list(
          title: '<em>Any</em> of the following',
          items: [
            'Cannot create or follow a budget, regardless of supports provided',
            'Does not comprehend financial obligations',
            'Does not have an income (including formal and informal sources)',
            'Not aware of the full amount spent on substances, if they use substances',
            'Substantial real or perceived debts of $1,000+, past due or requiring monthly payments',
          ],
        ),
      )
      question.add_score_choice(
        score: 3,
        help: new_list(
          title: '<em>Any</em> of the following',
          items: [
            'Requires intensive assistance to create and manage a budget (including any legally mandated guardian/trustee that provides assistance or manages access to money)',
            'Only understands their financial obligations with the assistance of a 3rd party',
            'Not budgeting for substance use, if they are a substance user',
            'Real or perceived debts of $900 or less, past due or requiring monthly payments',
          ],
        ),
      )
      question.add_score_choice(
        score: 2,
        help: new_list(
          title: '<em>Any</em> of the following',
          items: [
            'In the past 365 days, source of income has changed 2+ times',
            'Budgeting to the best of ability (including formal and informal sources), but still short of money every month for essential needs',
            'Voluntarily receives assistance creating and managing a budget or restricts access to their own money (e.g. guardian/trusteeship)',
            'Has been self-managing financial resources and taking care of associated administrative tasks for less than 90 days',
          ],
        ),
      )
      question.add_score_choice(
        score: 1,
        help: 'Has been self-managing financial resources and taking care of associated administrative tasks for at least 90 days, but for less than 180 days',
      )
      question.add_score_choice(
        score: 0,
        help: 'Has been self-managing financial resources and taking care of associated administrative tasks for at least 180 days',
      )
    end
  end

  def money_management_notes
    new_text_question(title: 'Personal Administration & Money Management Notes').tap do |question|
      question.cded = register_cded(key: __callee__)
    end
  end

  def social_relationships_group
    new_group_item(
      title: 'Social Relationships & Networks Prompt',
      children: [
        social_relationships_prompts,
        social_relationships_score,
        social_relationships_notes,
      ],
    )
  end

  def social_relationships_prompts
    new_display_item(
      content: new_list(
        title: 'Social Relationships & Networks Prompt',
        items: [
          'Tell me about your friends, family or other people in your life. How often do you get together or chat?',
          'When you go to doctor’s appointments or meet with other professionals like that, what is that like?',
          'Are there any people in your life that you feel are just using you?',
          'Are there any of your closer friends that you feel are always asking you for money, smokes, drugs, food or anything like that?',
          'Have you ever had people crash at your place that you did not want staying there?',
          'Have you ever been threatened with an eviction or lost a place because of something that friends or family did in your apartment?',
          'Have you ever been concerned about not following your lease agreement because of your friends or family?',
        ],
      ),
    )
  end

  def social_relationships_score
    new_score_question(title: 'Social Relationships & Networks Scoring').tap do |question|
      question.cded = register_cded(key: __callee__)
      question.add_score_choice(
        score: 4,
        help: new_list(
          title: '<em>Any</em> of the following',
          items: [
            'In the past 90 days, left an exploitive, abusive or dependent relationship',
            'Friends, family or other people are placing security of housing at imminent risk, or impacting life, wellness, or safety',
            'No friends or family and demonstrates no ability to follow social norms',
            'Currently homeless and would classify most of friends and family as homeless',
          ],
        ),
      )
      question.add_score_choice(
        score: 3,
        help: new_list(
          title: '<em>Any</em> of the following',
          items: [
            'In the past 90-180 days, left an exploitive, abusive or dependent relationship',
            'Friends, family or other people are having some negative consequences on wellness or housing stability',
            'No friends or family but demonstrates the ability to follow social norms',
            'Meeting new people with an intention of forming friendships',
            'Reconnecting with previous friends or family members, but experiencing difficulty advancing the relationship',
            'Currently homeless and would classify some of friends and family as being housed, while others are homeless',
          ],
        ),
      )
      question.add_score_choice(
        score: 2,
        help: new_list(
          title: '<em>Any</em> of the following',
          items: [
            'More than 180 days ago, left an exploitive, abusive or dependent relationship',
            'Developing relationships with new people but not yet fully trusting them',
            'Currently homeless and would classify friends and family as being housed',
          ],
        ),
      )
      question.add_score_choice(
        score: 1,
        help: "Has been housed for less than 180 days, <em>and</em> is engaged with friends or family, who are having no negative consequences on the individual's housing stability",
      )
      question.add_score_choice(
        score: 0,
        help: "Has been housed for at least 180 days, <em>and</em> is engaged with friends or family, who are having no negative consequences on the individual's housing stability",
      )
    end
  end

  def social_relationships_notes
    new_text_question(title: 'Social Relationships & Networks Notes').tap do |question|
      question.cded = register_cded(key: __callee__)
    end
  end

  def life_skills_group
    new_group_item(
      title: 'Self Care & Daily Living Skills',
      children: [
        life_skills_prompts,
        life_skills_score,
        life_skills_notes,
      ],
    )
  end

  def life_skills_prompts
    new_display_item(
      content: new_list(
        title: 'Self Care & Daily Living Skills Prompt',
        items: [
          'Do you have any worries about taking care of yourself?',
          'Do you have any concerns about cooking, cleaning, laundry or anything like that?',
          'Do you ever need reminders to do things like shower or clean up?',
          'Describe your last apartment.',
          'Do you know how to shop for nutritious food on a budget?',
          'Do you know how to make low cost meals that can result in leftovers to freeze or save for another day?',
          'Do you tend to keep all of your clothes clean?',
          'Have you ever had a problem with mice or other bugs like cockroaches as a result of a dirty apartment?',
          'When you have had a place where you have made a meal, do you tend to clean up dishes and the like before they get crusty?',
        ],
      ),
    )
  end

  def life_skills_score
    new_score_question(title: 'Self Care & Daily Living Skills Scoring').tap do |question|
      question.cded = register_cded(key: __callee__)
      question.add_score_choice(
        score: 4,
        help: new_list(
          title: '<em>Any</em> of the following',
          items: [
            'No insight into how to care for themselves, their apartment or their surroundings',
            'Currently homeless and relies upon others to meet basic needs (e.g. access to shelter, showers, toilet, laundry, food, and/or clothing) on almost a daily basis',
            'Engaged in hoarding or collecting behavior and is not aware that this is an issue in her/his life',
          ],
        ),
      )
      question.add_score_choice(
        score: 3,
        help: new_list(
          title: '<em>Any</em> of the following',
          items: [
            'Has insight into some areas of how to care for themselves, their apartment or their surroundings, but misses other areas because of lack of insight',
            'In the past 180 days, relied upon others to meet basic needs (e.g. access to shelter, showers, toilet, laundry, food, and/or clothing), 14+ days in any 30-day period',
            'Engaged in hoarding or collecting behavior and is aware that this is an issue in her/his life',
          ],
        ),
      )
      question.add_score_choice(
        score: 2,
        help: new_list(
          title: '<em>Any</em> of the following',
          items: [
            'Fully aware and has insight in all that is required to take care of themselves, their apartment or their surroundings, but has not yet mastered the skills or time management to fully execute this on a regular basis',
            'In the past 180 days, relied upon others to meet basic needs (e.g. access to shelter, showers, toilet, laundry, food, and/or clothing), fewer than 14 days in any 30-day period',
          ],
        ),
      )
      question.add_score_choice(
        score: 1,
        help: 'In the past 365 days, accessed community resources 4 or fewer times, and is fully taking care of all their daily needs',
      )
      question.add_score_choice(
        score: 0,
        help: 'For the past 365+ days, fully taking care of all their daily needs independently',
      )
    end
  end

  def life_skills_notes
    new_text_question(title: 'Self Care & Daily Living Skills Notes').tap do |question|
      question.cded = register_cded(key: __callee__)
    end
  end

  def meaningful_activity_group
    new_group_item(
      title: 'Meaningful Daily Activity',
      children: [
        meaningful_activity_prompts,
        meaningful_activity_score,
        meaningful_activity_notes,
      ],
    )
  end

  def meaningful_activity_prompts
    new_display_item(
      content: new_list(
        title: 'Meaningful Daily Activity Prompt',
        items: [
          'How do you spend your day?',
          'How do you spend your free time?',
          'Does that make you feel happy/fulfilled?',
          'How many days a week would you say you have things to do that make you feel happy/fulfilled?',
          'How much time in a week would you say you are totally bored?',
          'When you wake up in the morning, do you tend to have an idea of what you plan to do that day?',
          'How much time in a week would you say you spend doing stuff to fill up the time rather than doing things that you love?',
          'Are there any things that get in the way of you doing the sorts of activities you would like to be doing?',
        ],
      ),
    )
  end

  def meaningful_activity_score
    new_score_question(title: 'Meaningful Daily Activity Scoring').tap do |question|
      question.cded = register_cded(key: __callee__)
      question.add_score_choice(
        score: 4,
        help: 'No planned, legal activities described as providing fulfillment or happiness',
      )
      question.add_score_choice(
        score: 3,
        help: 'Discussing, exploring, signing up for and/or preparing for new activities or to re-engage with planned, legal activities that used to provide fulfillment or happiness',
      )
      question.add_score_choice(
        score: 2,
        help: 'Attempting new or re-engaging with planned, legal activities that used to provide fulfillment or happiness, but uncertain that activities selected are currently providing fulfillment or happiness, or the individual is not fully committed to continuing activities',
      )
      question.add_score_choice(
        score: 1,
        help: 'Has planned, legal activities described as providing fulfillment or happiness 1-3 days per week',
      )
      question.add_score_choice(
        score: 0,
        help: 'Has planned, legal activities described as providing fulfillment or happiness 4+ days per week',
      )
    end
  end

  def meaningful_activity_notes
    new_text_question(title: 'Meaningful Daily Activity Notes').tap do |question|
      question.cded = register_cded(key: __callee__)
    end
  end

  def history_of_homelessness_group
    new_group_item(
      title: 'History of Homelessness',
      children: [
        history_of_homelessness_prompts,
        history_of_homelessness_score,
        history_of_homelessness_notes,
      ],
    )
  end

  def history_of_homelessness_prompts
    new_display_item(
      content: new_list(
        title: 'History of Homelessness Prompt',
        items: [
          'How long have you been homeless?',
          'How many times have you been homeless in your life other than this most recent time?',
          'Have you spent any time sleeping on a friend’s couch or floor? And if so, during those times did you consider that to be your permanent address?',
          'Have you ever spent time sleeping in a car or alleyway or garage or barn or bus shelter or anything like that?',
          'Have you ever spent time sleeping in an abandoned building?',
          'Were you ever in hospital or jail for a period of time when you didn’t have a permanent address to go to when you got out?',
        ],
      ),
    )
  end

  def history_of_homelessness_score
    new_score_question(title: 'History of Homelessness Scoring').tap do |question|
      question.cded = register_cded(key: __callee__)
      question.add_score_choice(
        score: 4,
        help: 'Over the past 10 years, cumulative total of 5+ years of homelessness',
      )
      question.add_score_choice(
        score: 3,
        help: 'Over the past 10 years, cumulative total of 2+ years but fewer than 5 years of homelessness',
      )
      question.add_score_choice(
        score: 2,
        help: 'Over the past 4 years, cumulative total of 30+ days but fewer than 2 years of homelessness',
      )
      question.add_score_choice(
        score: 1,
        help: 'Over the past 4 years, cumulative total of 7+ days but fewer than 30 days of homelessness',
      )
      question.add_score_choice(
        score: 0,
        help: ' Over the past 4 years, cumulative total of 7 or fewer days of homelessness',
      )
    end
  end

  def history_of_homelessness_notes
    new_text_question(title: 'History of Homelessness Notes').tap do |question|
      question.cded = register_cded(key: __callee__)
    end
  end
end
