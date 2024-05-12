class IndexAdditionalEnrollmentSlugs < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    [
      'CustomServices',
      'CustomCaseNote',
      'CustomAssessments',
    ].each do |table_name|
      add_index table_name.to_sym, :enrollment_slug, algorithm: :concurrently
      # index_query = <<~SQL
      #   CREATE INDEX CONCURRENTLY #{table_name.downcase}_en_slug_idx
      #   ON "#{table_name}"."enrollment_slug"
      # SQL
      # add_index table_name.to_sym, :enrollment_slug, algorithm: :concurrently
      # safety_assured do
      #   execute(index_query)
      # end
    end
  end
end
