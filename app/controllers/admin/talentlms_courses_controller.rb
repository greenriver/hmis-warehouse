###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class TalentlmsCoursesController < ApplicationController
    before_action :require_can_manage_config!
    before_action :set_course, only: [:update, :edit, :destroy]

    def new
      config = Talentlms::Config.find(params['config']) if params['config']
      @course = course_scope.new(config: config)
    end

    def create
      @course = course_scope.create(course_params)
      respond_with(@course, location: admin_talentlms_path)
    end

    def edit
    end

    def update
      @course.update(course_params)
      respond_with(@course, location: admin_talentlms_path)
    end

    def destroy
      course_scope.remove_course(@course.id)
      respond_with(@course, location: admin_talentlms_path)
    end

    private def course_scope
      Talentlms::Course
    end

    private def set_course
      @course = course_scope.find(params[:id].to_i)
    end

    def course_params
      params.require(:talentlms_course).permit(
        :name,
        :config_id,
        :courseid,
        :months_to_expiration,
        :default,
      )
    end
  end
end
