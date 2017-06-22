require 'active_support'

# require "pry"

module RiceCooker
  module ClassMethods
    protected

    def initialize_model_class!
      # First priority is the namespaced model, e.g. User::Group
      # binding.pry

      # Handle InhRes computing
      # puts "[#{self}] In initialization, resource_class: #{self.respond_to?(:resource_class) && self.resource_class.inspect}"
      if self.respond_to?(:resource_class) && self.resource_class
        self.resource_model = self.resource_class
        return self.resource_model
      end
      # binding.pry

      # puts "[1/5] Resource model: #{self.resource_model.inspect}"
      self.resource_model ||= begin
        namespaced_class = name.sub(/Controller$/, '').singularize
        namespaced_class.constantize
      rescue NameError
        nil
      end

      # Second priority is the top namespace model, e.g. EngineName::Article for EngineName::Admin::ArticlesController
      # puts "[2/5] Resource model: #{self.resource_model.inspect}"
      self.resource_model ||= begin
        namespaced_classes = name.sub(/Controller$/, '').split('::')
        namespaced_class = [namespaced_classes.first, namespaced_classes.last].join('::').singularize
        namespaced_class.constantize
      rescue NameError
        nil
      end

      # Second second priority is the top namespace model, e.g. EngineName::Article for EngineName::Admin::ArticlesController
      # puts "[3/5] Resource model: #{self.resource_model.inspect}"
      self.resource_model ||= begin
        namespaced_class = name.sub(/Controller$/, '').split('::')[1..3].join('::').singularize
        namespaced_class.constantize
      rescue NameError
        nil
      end

      # Third priority the camelcased c, i.e. UserGroup
      # puts "[4/5] Resource model: #{self.resource_model.inspect}"
      self.resource_model ||= begin
        camelcased_class = name.sub(/Controller$/, '').gsub('::', '').singularize
        camelcased_class.constantize
      rescue NameError
        nil
      end

      # Otherwise use the Group class, or fail
      # puts "[5/5] Resource model: #{self.resource_model.inspect}"
      self.resource_model ||= begin
        class_name = controller_name.classify
        class_name.constantize
      rescue NameError => e
        raise unless e.message.include?(class_name)
        nil
      end

      # We prevent for creating a resource wich is not a model
      if self.resource_model
        begin
          self.resource_model = nil unless self.resource_model < ActiveRecord::Base
        rescue
          nil
        end
      end
    end

    def inherited(base) #:nodoc:
      super(base)
      base.send :initialize_model_class!
    end
  end
end
