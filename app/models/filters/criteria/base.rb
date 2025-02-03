class Filters::Criteria::Base
  # model must be included before attributes
  include ActiveModel::Model
  include ActiveModel::Attributes

  def level
    case self.class::LEVEL
    when :client, :project
      self.class::LEVEL
    else
      raise NotImplementedError, "#{self.class} must define LEVEL"
    end
  end

  def project_level?
    level == :project
  end

  def client_level?
    level == :client
  end

  def arel
    Hmis::ArelHelper.instance
  end
end
