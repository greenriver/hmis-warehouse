module GrdaWarehouse::HMIS
  class Assessment <  Base
    dub 'assessments'
    self.abstract_class = true

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :staff
    belongs_to :data_source, class_name: GrdaWarehouse::DataSource.name, foreign_key: :data_source_id, primary_key: GrdaWarehouse::DataSource.primary_key
    has_many :answers, inverse_of: :assessment, dependent: :delete_all
    has_many :questions, through: :answers

    alias_attribute :created_date, :response_created_at
  end
end