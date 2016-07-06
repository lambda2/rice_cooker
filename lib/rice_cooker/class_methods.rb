require 'active_support'
require 'pry'

module RiceCooker

  module ClassMethods

    protected

    def initialize_model_class!
      # First priority is the namespaced model, e.g. User::Group
      self.resource_model ||= begin
        namespaced_class = self.name.sub(/Controller$/, '').singularize
        namespaced_class.constantize
      rescue NameError
        nil
      end

      # Second priority is the top namespace model, e.g. EngineName::Article for EngineName::Admin::ArticlesController
      self.resource_model ||= begin
        namespaced_classes = self.name.sub(/Controller$/, '').split('::')
        namespaced_class = [namespaced_classes.first, namespaced_classes.last].join('::').singularize
        namespaced_class.constantize
      rescue NameError
        nil
      end

      # Third priority the camelcased c, i.e. UserGroup
      self.resource_model ||= begin
        camelcased_class = self.name.sub(/Controller$/, '').gsub('::', '').singularize
        camelcased_class.constantize
      rescue NameError
        nil
      end

      # Otherwise use the Group class, or fail
      self.resource_model ||= begin
        class_name = self.controller_name.classify
        class_name.constantize
      rescue NameError => e
        raise unless e.message.include?(class_name)
        nil
      end

      if self.resource_model
        begin
          self.resource_model = nil unless (self.resource_model < ActiveRecord::Base)
        rescue
          nil
        end
      end

      p "Model for #{self} is #{self.resource_model} !"
    end

    def inherited(base) #:nodoc:
      p "#{self.to_s} inherit #{base.to_s} !"
      if base.to_s == 'dTeamsController'
        puts caller.select{|e| e['intra/api']}
      end
      super(base)
      base.send :initialize_model_class!
    end

    def handle_errors

    end

  end
end
