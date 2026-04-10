# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Removes the Q\d+: numeric prefixes from FY2026 HOPWA CAPER question labels.
# These labels are persisted in hud_report_cells.question (universe rows) and in
# the json/jsonb arrays on hud_report_instances (question_names, build_for_questions, remaining_questions).
class RenameHopwaCaperFy2026QuestionLabels < ActiveRecord::Migration[7.2]
  REPORT_NAME = 'HOPWA CAPER - FY 2026'

  RENAMES = {
    'Q1: Demographics and Prior Living Situation' => 'Demographics and Prior Living Situation',
    'Q2: TBRA' => 'TBRA',
    'Q3: STRMU' => 'STRMU',
    'Q4: PHP' => 'PHP',
    'Q5: Housing Information Services' => 'Housing Information Services',
    'Q6: Supportive Services' => 'Supportive Services',
    'Q7: Access To Care' => 'Access To Care',
    'Q9: ST-TFBH' => 'ST-TFBH',
    'Q10: P-FBH' => 'P-FBH',
  }.freeze

  def up
    fy2026_instance_ids = HudReports::ReportInstance.where(report_name: REPORT_NAME).select(:id)

    RENAMES.each do |old_label, new_label|
      # Universe rows on report cells
      HudReports::ReportCell.where(report_instance_id: fy2026_instance_ids, question: old_label).
        update_all(question: new_label)

      # JSON arrays on report instances — replace each old string in-place
      HudReports::ReportInstance.where(id: fy2026_instance_ids).find_each do |instance|
        changed = false

        [:question_names, :build_for_questions, :remaining_questions].each do |col|
          arr = instance.send(col)
          next unless arr.is_a?(Array) && arr.include?(old_label)

          instance.send(:"#{col}=", arr.map { |v| v == old_label ? new_label : v })
          changed = true
        end

        instance.save!(validate: false) if changed
      end
    end
  end

  def down
    fy2026_instance_ids = HudReports::ReportInstance.where(report_name: REPORT_NAME).select(:id)

    RENAMES.each do |old_label, new_label|
      HudReports::ReportCell.where(report_instance_id: fy2026_instance_ids, question: new_label).
        update_all(question: old_label)

      HudReports::ReportInstance.where(id: fy2026_instance_ids).find_each do |instance|
        changed = false

        [:question_names, :build_for_questions, :remaining_questions].each do |col|
          arr = instance.send(col)
          next unless arr.is_a?(Array) && arr.include?(new_label)

          instance.send(:"#{col}=", arr.map { |v| v == new_label ? old_label : v })
          changed = true
        end

        instance.save!(validate: false) if changed
      end
    end
  end
end
