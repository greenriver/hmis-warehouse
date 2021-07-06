class CreatePscFeedbackSurvey < ActiveRecord::Migration[5.2]
  def change
    create_table :psc_feedback_surveys do |t|
      t.references :client
      t.references :user

      t.date :conversation_on
      t.string :location
      t.string :listened_to_me
      t.string :cared_about_me
      t.string :knowledgeable
      t.string :i_was_included
      t.string :i_decided
      t.string :supporting_my_needs
      t.string :sensitive_to_culture
      t.string :would_return
      t.string :more_calm_and_control
      t.string :satisfied
      t.string :comments

      t.timestamps
      t.datetime :deleted_at
    end
  end
end
