class AddFileToReport < ActiveRecord::Migration
  def change
    add_reference :report_results, :file
  end
end
