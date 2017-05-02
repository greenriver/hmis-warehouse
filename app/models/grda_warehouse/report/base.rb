# provides some conviences method to all the view models
module GrdaWarehouse::Report
  class Base < GrdaWarehouseBase
    self.abstract_class = true

    # add one useful association for every view subclass
    def self.inherited(subclass)
      subclass.primary_key = :id
      cn = subclass.name.index('Demographic') ? 'GrdaWarehouse::Hud::Client' : subclass.original_class_name
      belongs_to :original, primary_key: :id, foreign_key: :id, class_name: cn
      super
    end

    # some convenience methods, because we seem to need to provide primary and foreign keys for all these relationships even though they're inferrable

    def self.belongs(model)
      n = basename.to_s.pluralize.to_sym
      belongs_to model, primary_key: :id, foreign_key: "#{model}_id".to_sym, inverse_of: n
    end

    def self.many(model)
      has_many model, primary_key: :id, foreign_key: "#{basename}_id".to_sym, inverse_of: basename
    end

    def self.one(model)
      has_one model, primary_key: :id, foreign_key: "#{basename}_id".to_sym, inverse_of: basename
    end

    def self.basename
      model_name.element.to_sym
    end

    # the corresponding model in the GrdaWarehouse::Hud, or other, namespace
    def self.original_class_name
      @original_class ||= "GrdaWarehouse::Hud::#{ name.gsub /.*::/, '' }"
    end

    def readonly?
      true
    end
  end
end