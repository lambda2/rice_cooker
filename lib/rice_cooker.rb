require 'action_controller'

module RiceCooker
  autoload :Helpers, 'rice_cooker/helpers'
  autoload :ClassMethods, 'rice_cooker/class_methods'
  autoload :Filter, 'rice_cooker/filter'
  autoload :Sort, 'rice_cooker/sort'
  autoload :Range, 'rice_cooker/range'
  autoload :Search, 'rice_cooker/search'
  autoload :VERSION, 'rice_cooker/version'

  def self.rice_cooked(base)
    base.class_eval do
      include RiceCooker::Sort
      include RiceCooker::Filter
      include RiceCooker::Range
      include RiceCooker::Search
      extend  RiceCooker::ClassMethods

      class_attribute :resource_model, instance_writer: false

      protected :resource_model
    end
  end
end

module ActionController
  class Base
    RiceCooker.rice_cooked(self)
  end
end
