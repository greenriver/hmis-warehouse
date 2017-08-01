module Admin
  class MissingGradesController < ApplicationController
    before_action :require_can_edit_dq_grades!
    before_action :load_grade, only: [:edit, :update, :destroy]

    def index
      @grades = grade_scope
        .order(letter: :asc)
    end

    def new
      @grade = grade_source.new
    end

    def edit

    end

    def update
      @grade.assign_attributes(grade_params)
      if @grade.save 
        redirect_to(admin_data_quality_grades_path, notice: 'Grade updated')
      else
        flash[:error] = 'Please review the form problems below'
        render :edit
      end
    end

    def create
      @grade = grade_source.new(grade_params)
      if @grade.save 
        redirect_to(admin_data_quality_grades_path, notice: 'Grade created')
      else
        flash[:error] = 'Please review the form problems below'
        render :edit
      end
    end

    def destroy
      @grade.destroy
      redirect_to(admin_data_quality_grades_path, notice: 'Grade deleted')
    end

    def load_grade
      @grade = grade_scope.find(params[:id].to_i)
    end

    def grade_scope
      grade_source.all
    end

    def grade_source
      GrdaWarehouse::Grades::Missing
    end

    def grade_params
      params.require(:grade).
        permit(
          :grade,
          :percentage_low,
          :percentage_high,
          :color,
          :weight
        )
    end

  end
end
