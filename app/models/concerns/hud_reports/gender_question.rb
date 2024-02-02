###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Required accessors:
#   a_t: Arel Type for the universe model
#

module HudReports::GenderQuestion
  extend ActiveSupport::Concern
  def gender_question(question:, members:, populations:)
    question_sheet(question: question) do |sheet|
      populations.keys.each do |label|
        sheet.add_header(label: label)
      end

      gender_identities.each_pair do |label, gender_cond|
        gender_scope = members.where(gender_cond[1])
        sheet.append_row(label: label) do |row|
          populations.values.each do |pop_cond|
            row.append_cell_members(members: gender_scope.where(pop_cond))
          end
        end
      end
    end
  end
end
