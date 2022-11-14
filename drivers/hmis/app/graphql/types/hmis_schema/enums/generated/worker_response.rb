# header
module Types
  class HmisSchema::Enums::WorkerResponse < Types::BaseEnum
    description 'R19.A'
    graphql_name 'WorkerResponse'
    value NO, '(0) No', value: 0
    value YES, '(1) Yes', value: 1
    value WORKER_DOES_NOT_KNOW, '(2) Worker does not know', value: 2
  end
end
