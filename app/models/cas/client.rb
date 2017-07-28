module Cas
  class Client < CasBase
    has_one :project_client, primary_key: :id, foreign_key: :client_id
    has_many :client_opportunity_matches
  end
end
