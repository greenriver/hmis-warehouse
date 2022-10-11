module BuiltForZeroReport
  def self.table_name_prefix
    'built_for_zero_report_'
  end

  def self.all_report_sections
    {
      veterans: 'Veterans Section',
      chronic_veterans: 'Chronic Veterans Section',
      chronic: 'Chronic Section',
      adults: 'All Single Adults (Individuals) Section',
      youth: 'Youth Section',
      families: 'Family Section',
    }
  end

  def self.sections
    return {} unless ::GrdaWarehouse::Config.get(:enable_system_cohorts)

    cohort_keys = {
      veterans: :veteran_cohort,
      chronic_veterans: :chronic_cohort,
      chronic: :chronic_cohort,
      adults: :adult_only_cohort,
      youth: :youth_cohort,
      families: :adult_and_child_cohort,
    }.freeze

    all_report_sections.
      select do |k, _|
        ::GrdaWarehouse::SystemCohorts::Base.find_system_cohort(cohort_keys[k]).present? &&
        ::GrdaWarehouse::Config.get(cohort_keys[k])
      end.
      invert.
      freeze
  end

  def self.section_classes
    {
      'adults' => ::BuiltForZeroReport::Adults,
      'chronic' => ::BuiltForZeroReport::Chronic,
      'families' => ::BuiltForZeroReport::Families,
      'veterans' => ::BuiltForZeroReport::Veterans,
      'chronic_veterans' => ::BuiltForZeroReport::ChronicVeterans,
      'youth' => ::BuiltForZeroReport::Youth,
    }.freeze
  end

  # Returns success or failure string
  def self.submit_via_api!(start_date, end_date, user:)
    credential = BuiltForZeroReport::Credential.first
    data = credential.section_ids.map do |m|
      section = section_classes.values.detect { |sc| m['subpopname'] == sc.sub_population_name }
      sub_population_id = m['id']
      next if section.blank?

      section.new(start_date, end_date, user: user).data.for_api(sub_population_id)
    end.compact
    credential.submit(data.to_json)
  end
end
