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
    fy2026_instance_ids = HudReports::ReportInstance.where(report_name: REPORT_NAME).pluck(:id)

    RENAMES.each do |old_label, new_label|
      HudReports::ReportCell.where(report_instance_id: fy2026_instance_ids, question: old_label).
        update_all(question: new_label)
    end

    rename_instance_json(fy2026_instance_ids, RENAMES)
  end

  def down
    fy2026_instance_ids = HudReports::ReportInstance.where(report_name: REPORT_NAME).pluck(:id)

    RENAMES.each do |old_label, new_label|
      HudReports::ReportCell.where(report_instance_id: fy2026_instance_ids, question: new_label).
        update_all(question: old_label)
    end

    rename_instance_json(fy2026_instance_ids, RENAMES.invert)
  end

  private

  def rename_instance_json(instance_ids, renames)
    HudReports::ReportInstance.where(id: instance_ids).find_each do |instance|
      changed = false

      [:question_names, :build_for_questions, :remaining_questions].each do |col|
        arr = instance.public_send(col)
        next unless arr.is_a?(Array)

        renamed = arr.map { |v| renames.fetch(v, v) }
        next if renamed == arr

        instance.public_send(:"#{col}=", renamed)
        changed = true
      end

      instance.save!(validate: false) if changed
    end
  end
end
