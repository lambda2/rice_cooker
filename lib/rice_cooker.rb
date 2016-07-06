require 'action_controller'

module RiceCooker
  autoload :Helpers,      'rice_cooker/helpers'
  autoload :ClassMethods, 'rice_cooker/class_methods'
  autoload :Filter,       'rice_cooker/filter'
  autoload :Sort,         'rice_cooker/sort'
  autoload :Range,        'rice_cooker/range'
  autoload :VERSION,      'rice_cooker/version'
end

module ActionController
  class Base

    def self.rice_cooked(base)
      base.class_eval do
        include RiceCooker::Sort
        include RiceCooker::Filter
        include RiceCooker::Range
        extend  RiceCooker::ClassMethods

        self.class_attribute :resource_model, :instance_writer => false

        protected :resource_model
      end
    end

    rice_cooked(self)

  end
end
