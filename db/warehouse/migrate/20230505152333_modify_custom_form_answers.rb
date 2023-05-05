class ModifyCustomFormAnswers < ActiveRecord::Migration[6.1]
  def change
    # Add a reference to CustomDataElementDefinitions
    add_column :CustomFormAnswers, :custom_data_element_definition_id, :integer, null: false, comment: 'Definition for this data element'
    # Instead of linking the data element to the CustomForm, link it to the FormProcessor
    remove_column :CustomFormAnswers, :custom_form_id, :integer
    add_column :CustomFormAnswers, :form_processor_id, :integer, index: true, null: false
    # Remove unnecessary columns
    remove_column :CustomFormAnswers, :key, :string # Not needed because its defined in CustomDataElementDefinitions
    remove_column :CustomFormAnswers, :link_id, :string # Not needed
  end
end
