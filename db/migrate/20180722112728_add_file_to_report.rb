class AddFileToReport < ActiveRecord::Migration[4.2]
  def change
    add_reference :report_results, :file
  end
end
