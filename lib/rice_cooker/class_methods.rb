require 'active_support'

module RiceCooker
  module ClassMethods
    protected

    def initialize_model_class!
      # First priority is the namespaced model, e.g. User::Group

      # Handle InhRes computing
      if self.respond_to? :resource_class
        self.resource_model = self.resource_class
        return self.resource_model
      end

      self.resource_model ||= begin
        namespaced_class = name.sub(/Controller$/, '').singularize
        namespaced_class.constantize
      rescue NameError
        nil
      end

      # Second priority is the top namespace model, e.g. EngineName::Article for EngineName::Admin::ArticlesController
      self.resource_model ||= begin
        namespaced_classes = name.sub(/Controller$/, '').split('::')
        namespaced_class = [namespaced_classes.first, namespaced_classes.last].join('::').singularize
        namespaced_class.constantize
      rescue NameError
        nil
      end

      # Third priority the camelcased c, i.e. UserGroup
      self.resource_model ||= begin
        camelcased_class = name.sub(/Controller$/, '').gsub('::', '').singularize
        camelcased_class.constantize
      rescue NameError
        nil
      end

      # Otherwise use the Group class, or fail
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
