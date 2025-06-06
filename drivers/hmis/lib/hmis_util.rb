# frozen_string_literal: true

module HmisUtil
  def self.current_hud_year
    # check for property in the database
    if defined?(@db_current_hud_year)
      return @db_current_hud_year if @db_current_hud_year
    else
      @db_current_hud_year = AppConfigProperty.where(key: 'current_hud_year').first&.value
    end

    # infer from current time
    cutoff_date = Rails.env.production? ? Date.new(2025, 10, 1) : Date.new(2025, 9, 1)
    return '2024' if Date.current < cutoff_date

    return '2026'
  end

  def self.current_assessment_form_rules
    TodoOrDie('Update after FY2026 changeover', by: '2025-11-01')

    case current_hud_year
    when '2024'
      HmisUtil::HudAssessmentFormRules2024.new
    when '2026'
      HmisUtil::HudAssessmentFormRules2026.new
    else
      raise "cannot determine form rules for year '#{current_hud_year}'"
    end
  end
end
