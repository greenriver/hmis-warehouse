# frozen_string_literal: true

module Hmis::WorkflowExecution
  MessageResult = Struct.new(:success?, :reversible?)
end
