###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Reporting
  class RunHudReportJob < BaseJob
    def perform(class_name, options)
      @generator = class_name.constantize.new(options)
      @generator.class.questions.values.each do |clazz|
        clazz.new(@generator).run!
      end
    end
  end
end
