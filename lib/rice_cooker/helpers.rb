require 'active_support'

module RiceCooker
  
  # Will be thrown when invalid sort param
  class InvalidSortException < Exception
  end

  class InvalidFilterException < Exception
  end

  class InvalidFilterValueException < Exception
  end

  class InvalidRangeException < Exception
  end

  class InvalidRangeValueException < Exception
  end

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

    # Overridable method for available sortable fields
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

    # Overridable method for available rangeable fields
    def rangeable_fields_for(model)
      if model.respond_to?(:rangeable_fields)
        model.rangeable_fields.map(&:to_sym)
      else
        filterable_fields_for(model)
      end
    end

    # ------------------------ Sort helpers --------------------

    # model -> resource_class with inherited resources
    def parse_sorting_param sorting_param, model
      return {} unless sorting_param.present?

      sorting_params = CSV.parse_line(URI.unescape(sorting_param)).collect do |sort|
        if sort.start_with?('-')
          sorting_param = { field: sort[1..-1].to_s.to_sym }
          sorting_param[:direction] = :desc
        else
          sorting_param = { field: sort.to_s.to_sym }
          sorting_param[:direction] = :asc
        end

        check_sorting_param(model, sorting_param)
        # p "Sort params accepted: #{sorting_param.inspect}"
        sorting_param
      end
      sorting_params.map{|par| [par[:field], par[:direction]]}.to_h
    end

    def check_sorting_param(model, sorting_param)
      sort_field = sorting_param[:field]
      sortable_fields = sortable_fields_for(model)

      unless sortable_fields.include? sort_field.to_sym
        raise InvalidSortException.new("The #{sort_field} field is not sortable")
      end
    end

    def param_from_defaults(sorting_params)
      sorting_params.map{|k, v| "#{v == :desc ? '-' : ''}#{k}"}.join(',')
    end

    def apply_sort_to_collection(collection, sorting_params)
      return collection unless collection.any?
      # p "Before apply: #{sorting_params.inspect}"
      collection.order(sorting_params)
    end

    # ------------------------ Filter helpers --------------------

    # Va transformer le param url en hash exploitable
    def parse_filtering_param filtering_param, allowed_params

      return {} unless filtering_param.present?

      fields = {}

      # Extract the fields for each type from the fields parameters
      if filtering_param.is_a?(Hash)
        filtering_param.each do |field, value|
          resource_fields = value.split(',') unless value.nil? || value.empty?
          fields[field.to_sym] = resource_fields
        end
      else
        fail InvalidFilterException.new("Invalid filter format for #{filtering_param}")
      end
      check_filtering_param(fields, allowed_params)
      fields
    end

    # Our little barrier <3
    def check_filtering_param(filtering_param, allowed)
      🔞 = filtering_param.keys.map(&:to_sym) - allowed.map(&:to_sym)
      fail InvalidFilterException.new("Attributes #{🔞.map(&:to_s).to_sentence} doesn't exists or aren't filterables. Available filters are: #{allowed.to_sentence}") if 🔞.any?
    end

    # On va essayer de garder un format commun, qui est:
    #
    # ```
    # filter: {
    #   proc: -> (values) { * je fais des trucs avec les values * },
    #   all: ['les', 'valeurs', 'aceptées'],
    #   description: "La description dans la doc"
    # }
    # ```
    # 
    # On va donc transformer `additional` dans le format ci-dessus
    # 
    def format_addtional_filtering_param additional
      if additional.is_a? Hash
        additional = additional.map do |field, value|
          if value.is_a?(Hash)
            value = {
              proc: nil,
              all: [],
              description: ""
            }.merge(value)
          elsif value.is_a? Array
            value = {
              proc: value.try(:at, 0),
              all: value.try(:at, 1) || [],
              description: value.try(:at, 2) || ""
            }
          elsif value.is_a? Proc
            value = {
              proc: value,
              all: [],
              description: ""
            }
          else
            raise "Unable to format addional filtering params (got #{additional})"
          end
          [field, value]
        end.to_h
      end
      additional
    end

    def apply_filter_to_collection(collection, filtering_params, additional = {})
      return collection if collection.blank?

      filtering_params.each do |field, value|
        if additional.has_key?(field) and additional[field].has_key?(:proc)
          
          # Si on a fourni des valeurs, on verifie qu'elle matchent
          if additional[field].has_key?(:all) and additional[field][:all].try(:any?)
            allowed = additional[field][:all].map(&:to_s)
            fail InvalidFilterValueException.new("Value #{(value - allowed).to_sentence} is not allowed for filter #{field}, can be #{allowed.to_sentence}") if (value - allowed).any?
          end

          collection = collection.instance_exec(value, &(additional[field][:proc]))
        elsif value.is_a? String or value.is_a? Array
          collection = collection.where(field => value)
        elsif value.is_a? Hash and value.has_key? :proc
          collection
        end
      end
      collection
    end

    # ------------------------ Range helpers --------------------

    # Va transformer le param url en hash exploitable
    def parse_ranged_param ranged_param, allowed_params

      return {} unless ranged_param.present?

      fields = {}

      # Extract the fields for each type from the fields parameters
      if ranged_param.is_a?(Hash)
        ranged_param.each do |field, value|
          resource_fields = value.split(',') unless value.nil? || value.empty?
          fail InvalidRangeException.new("Invalid range format for #{ranged_param}. Too many arguments for filter (#{resource_fields}).") if resource_fields.length > 2
          fail InvalidRangeException.new("Invalid range format for #{ranged_param}. Begin and end must be separated by a comma (,).") if resource_fields.length < 2
          fields[field.to_sym] = resource_fields
        end
      else
        fail InvalidRangeException.new("Invalid range format for #{ranged_param}")
      end
      check_ranged_param(fields, allowed_params)
      fields
    end

    # Our little barrier <3
    def check_ranged_param(ranged_param, allowed)
      🔞 = ranged_param.keys.map(&:to_sym) - allowed.map(&:to_sym)
      fail InvalidRangeException.new("Attributes #{🔞.map(&:to_s).to_sentence} doesn't exists or aren't rangeables. Available ranges are: #{allowed.to_sentence}") if 🔞.any?
    end

    # On va essayer de garder un format commun, qui est:
    #
    # ```
    # range: {
    #   proc: -> (values) { * je fais des trucs avec les values * },
    #   all: ['les', 'valeurs', 'aceptées'],
    #   description: "La description dans la doc"
    # }
    # ```
    # 
    # On va donc transformer `additional` dans le format ci-dessus
    # 
    def format_addtional_ranged_param additional
      if additional.is_a? Hash
        additional = additional.map do |field, value|
          if value.is_a?(Hash)
            value = {
              proc: nil,
              all: [],
              description: ""
            }.merge(value)
          elsif value.is_a? Array
            value = {
              proc: value.try(:at, 0),
              all: value.try(:at, 1) || [],
              description: value.try(:at, 2) || ""
            }
          elsif value.is_a? Proc
            value = {
              proc: value,
              all: [],
              description: ""
            }
          else
            raise "Unable to format addional ranged params (got #{additional})"
          end
          [field, value]
        end.to_h
      end
      additional
    end

    def apply_range_to_collection(collection, ranged_params, additional = {})
      return collection if collection.blank?

      ranged_params.each do |field, value|
        if additional.has_key?(field) and additional[field].has_key?(:proc)
          
          # Si on a fourni des valeurs, on verifie qu'elle matchent
          if additional[field].has_key?(:all) and additional[field][:all].try(:any?)
            allowed = additional[field][:all].map(&:to_s)
            fail InvalidRangeValueException.new("Value #{(value - allowed).to_sentence} is not allowed for range #{field}, can be #{allowed.to_sentence}") if (value - allowed).any?
          end

          collection = collection.instance_exec(value, &(additional[field][:proc]))
        elsif value.is_a? Array
          _from, _to = value.slice(0,2)
          begin
            collection = collection.where(field => _from.._to)
          rescue ArgumentError => e
            fail InvalidRangeValueException.new("Unable to create a range between values '#{_from}' and '#{_to}'")
          end
        elsif value.is_a? Hash and value.has_key? :proc
          collection
        end
      end
      collection
    end
  end
end