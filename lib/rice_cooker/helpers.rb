require 'active_support'

module RiceCooker
  module Helpers

    extend ActiveSupport::Concern

    # From https://github.com/josevalim/inherited_resources/blob/master/lib/inherited_resources/class_methods.rb#L315
    def controller_resource_class(controller)
      detected_resource_class = nil

      if controller.respond_to? :name
        detected_resource_class ||= begin
          namespaced_class = controller.name.sub(/Controller$/, '').singularize
          namespaced_class.constantize
        rescue NameError
          nil
        end

        # Second priority is the top namespace model, e.g. EngineName::Article for EngineName::Admin::ArticlesController
        detected_resource_class ||= begin
          namespaced_classes = controller.name.sub(/Controller$/, '').split('::')
          namespaced_class = [namespaced_classes.first, namespaced_classes.last].join('::').singularize
          namespaced_class.constantize
        rescue NameError
          nil
        end

        # Third priority the camelcased c, i.e. UserGroup
        detected_resource_class ||= begin
          camelcased_class = controller.name.sub(/Controller$/, '').gsub('::', '').singularize
          camelcased_class.constantize
        rescue NameError
          nil
        end

      elsif controller.respond_to? :controller_name
        # Otherwise use the Group class, or fail
        detected_resource_class ||= begin
          class_name = controller.controller_name.classify
          class_name.constantize
        rescue NameError => e
          raise unless e.message.include?(class_name)
          nil
        end
      else
        detected_resource_class = nil
      end
      detected_resource_class
    end

    def sortable_fields_for(model)
      if model.respond_to?(:sortable_fields)
        model.sortable_fields.map(&:to_sym)
      else
        model.column_names.map(&:to_sym)
      end
    end

    # Overridable method for available filterable fields
    def filterable_fields_for(model)
      if model.respond_to?(:filterable_fields)
        model.filterable_fields.map(&:to_sym)
      else
        model.column_names.map(&:to_sym)
      end
    end

  end
end