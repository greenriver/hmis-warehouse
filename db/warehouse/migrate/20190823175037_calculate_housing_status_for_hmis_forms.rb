class CalculateHousingStatusForHmisForms < ActiveRecord::Migration[4.2]
  def up
    GrdaWarehouse::HmisForm.
      case_management_notes.
      find_each do |form|
      first_section = form.answers[:sections].first
      if first_section.present?
        answer = form.answers[:sections].first[:questions].select do |question|
          question[:question] == "A-6. Where did you sleep last night?"
        end.first.try(:[], :answer)
        form.update(housing_status: answer)
      end
    end
  end
end
