class AddCeEventToFormProcessor < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      add_reference :hmis_form_processors, :ce_event
    end
  end
end
