class AddForQuestionIndex < ActiveRecord::Migration[5.2]
  def change
    add_index :pm_client_projects, [:client_id, :for_question, :report_id, :period], name: :pm_clients_c_id_fq_r_id_p
  end
end
