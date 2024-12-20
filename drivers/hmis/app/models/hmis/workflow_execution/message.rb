# messages generated during a workflow
module Hmis::WorkflowExecution
  Message = Struct.new(:type, :params, :step, keyword_init: true)
end
