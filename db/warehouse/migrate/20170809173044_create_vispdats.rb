class CreateVispdats < ActiveRecord::Migration
  def change
    create_table :vispdats do |t|
      t.references :client, index: true
      t.string :first_name
      t.string :nickname
      t.string :last_name
      t.integer :language_answer
      t.date :dob
      t.string :ssn
      t.boolean :consent
      t.integer :sleep_answer
      t.string :sleep_answer_other
      t.integer :years_homeless
      t.boolean :years_homeless_refused
      t.integer :episodes_homeless
      t.boolean :episodes_homeless_refused
      t.integer :emergency_healthcare
      t.boolean :emergency_healthcare_refused
      t.integer :ambulance
      t.boolean :ambulance_refused
      t.integer :inpatient
      t.boolean :inpatient_refused
      t.integer :crisis_service
      t.boolean :crisis_service_refused
      t.integer :talked_to_police
      t.boolean :talked_to_police_refused
      t.integer :jail
      t.boolean :jail_refused
      t.integer :attacked_answer
      t.integer :threatened_answer
      t.integer :legal_answer
      t.integer :tricked_answer
      t.integer :risky_answer
      t.integer :owe_money_answer
      t.integer :get_money_answer
      t.integer :activities_answer
      t.integer :basic_needs_answer
      t.integer :abusive_answer
      t.integer :leave_answer
      t.integer :chronic_answer
      t.integer :hiv_answer
      t.integer :disability_answer
      t.integer :avoid_help_answer
      t.integer :pregnant_answer
      t.integer :eviction_answer
      t.integer :drinking_answer
      t.integer :mental_answer
      t.integer :head_answer
      t.integer :learning_answer
      t.integer :brain_answer
      t.integer :medication_answer
      t.integer :sell_answer
      t.integer :trauma_answer
      t.string :find_location
      t.string :find_time
      t.integer :when_answer
      t.string :phone
      t.string :email
      t.integer :picture_answer
      t.integer :score
      t.string :recommendation

      t.timestamps null: false
    end
  end
end
