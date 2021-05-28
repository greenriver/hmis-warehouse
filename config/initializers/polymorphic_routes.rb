# FIX for CVE-2021-22885
module ActionDispatch
  module Routing
    module PolymorphicRoutes
      class HelperMethodBuilder
        alias_method :action_dispatch_handle_list, :handle_list
        def handle_list(list)
          clean_list = list.map do |parent|
            parent.is_a?(String) ? parent.to_sym : parent
          end
          action_dispatch_handle_list(clean_list)
        end
      end
    end
  end
end
