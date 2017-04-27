require 'active_support'

module RiceCooker
  # Will be thrown when invalid sort param
  class InvalidSortException < Exception
  end

  class InvalidFilterException < Exception
  end

  class InvalidFilterValueException < Exception
  end

  class InvalidSearchException < Exception
  end

  class InvalidSearchValueException < Exception
  end

  class InvalidRangeException < Exception
  end

  class InvalidRangeValueException < Exception
  end

  module Helpers
    extend ActiveSupport::Concern

    # Overridable method for available sortable fields
    def sortable_fields_for(model)
      if model.respond_to?(:sortable_fields)
        model.sortable_fields.map(&:to_sym)
      elsif model.respond_to?(:column_names)
        model.column_names.map(&:to_sym)
      else
        []
      end
    end

    # Overridable method for available filterable fields
    def filterable_fields_for(model)
      if model.respond_to?(:filterable_fields)
        model.filterable_fields.map(&:to_sym)
      elsif model.respond_to?(:column_names)
        model.column_names.map(&:to_sym)
      else
        []
      end
    end

    # Overridable method for available searchable fields
    def searchable_fields_for(model)
      if model.respond_to?(:searchable_fields)
        model.searchable_fields.map(&:to_sym)
      else
        filterable_fields_for(model)
      end
    end

    # Overridable method for available fuzzy fields
    def fuzzy_fields_for(model)
      if model.respond_to?(:fuzzy_fields)
        model.fuzzy_fields.map(&:to_sym)
      else
        searchable_fields_for(model)
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
    def parse_sorting_param(sorting_param, model)
      return {} unless sorting_param.present?

      sorting_params = CSV.parse_line(URI.unescape(sorting_param)).collect do |sort|
        sorting_param = if sort.start_with?('-')
                          { field: sort[1..-1].to_s.to_sym, direction: :desc }
                        else
                          { field: sort.to_s.to_sym, direction: :asc }
                        end

        check_sorting_param(model, sorting_param)
        sorting_param
      end
      sorting_params.map { |par| [par[:field], par[:direction]] }.to_h
    end

    def check_sorting_param(model, sorting_param)
      sort_field = sorting_param[:field]
      sortable_fields = sortable_fields_for(model)

      unless sortable_fields.include? sort_field.to_sym
        raise InvalidSortException, "The #{sort_field} field is not sortable"
      end
    end

    def param_from_defaults(sorting_params)
      sorting_params.map { |k, v| "#{v == :desc ? '-' : ''}#{k}" }.join(',')
    end

    def apply_sort_to_collection(collection, sorting_params)
      return collection unless collection.any?
      # p "Before apply: #{sorting_params.inspect}"
      collection.order(sorting_params)
    end

    # ------------------------ Filter helpers --------------------

    # Va transformer le param url en hash exploitable
    def parse_filtering_param(filtering_param, allowed_params)
      return {} unless filtering_param.present?

      fields = {}

      # Extract the fields for each type from the fields parameters
      if filtering_param.is_a?(Hash)
        filtering_param.each do |field, value|
          resource_fields = value.split(',') unless value.nil? || value.empty?
          fields[field.to_sym] = resource_fields
        end
      else
        raise InvalidFilterException, "Invalid filter format for #{filtering_param}"
      end
      check_filtering_param(fields, allowed_params)
      fields
    end

    # Our little barrier <3
    def check_filtering_param(filtering_param, allowed)
      🔞 = filtering_param.keys.map(&:to_sym) - allowed.map(&:to_sym)
      raise InvalidFilterException, "Attributes #{🔞.map(&:to_s).to_sentence} doesn't exists or aren't filterables. Available filters are: #{allowed.to_sentence}" if 🔞.any?
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
    def format_additional_param(additional, context_format = 'filtering')
      if additional.is_a? Hash
        additional = additional.map do |field, value|
          if value.is_a?(Hash)
            value = {
              proc: nil,
              all: [],
              description: ''
            }.merge(value)
          elsif value.is_a? Array
            value = {
              proc: value.try(:at, 0),
              all: value.try(:at, 1) || [],
              description: value.try(:at, 2) || ''
            }
          elsif value.is_a? Proc
            value = {
              proc: value,
              all: [],
              description: ''
            }
          else
            raise "Unable to format addional #{context_format} params (got #{additional})"
          end
          [field, value]
        end.to_h
      end
      additional
    end

    def apply_filter_to_collection(collection, filtering_params, additional = {})
      return collection if collection.nil?

      filtering_params.each do |field, value|
        if additional.key?(field) && additional[field].key?(:proc)

          # Si on a fourni des valeurs, on verifie qu'elle matchent
          if additional[field].key?(:all) && additional[field][:all].try(:any?)
            allowed = additional[field][:all].map(&:to_s)
            raise InvalidFilterValueException, "Value #{(value - allowed).to_sentence} is not allowed for filter #{field}, can be #{allowed.to_sentence}" if (value - allowed).any?
          end

          collection = collection.instance_exec(value, &(additional[field][:proc]))
        elsif value.is_a?(String) || value.is_a?(Array)
          collection = collection.where(field => value)
        elsif value.is_a?(Hash) && value.key?(:proc)
          collection
        end
      end
      collection
    end


    # ------------------------ Search helpers --------------------

    # Va transformer le param url en hash exploitable
    def parse_searching_param(searching_param, allowed_params)
      return {} unless searching_param.present?

      fields = {}

      # Extract the fields for each type from the fields parameters
      if searching_param.is_a?(Hash)
        searching_param.each do |field, value|
          resource_fields = value.split(',') unless value.nil? || value.empty?
          fields[field.to_sym] = resource_fields
        end
      else
        raise InvalidSearchException, "Invalid search format for #{searching_param}"
      end
      check_searching_param(fields, allowed_params)
      fields
    end

    # Our little barrier <3
    def check_searching_param(searching_param, allowed)
      🔞 = searching_param.keys.map(&:to_sym) - allowed.map(&:to_sym)
      raise InvalidSearchException, "Attributes #{🔞.map(&:to_s).to_sentence} doesn't exists or aren't searchables. Available searchs are: #{allowed.to_sentence}" if 🔞.any?
    end

    # On va essayer de garder un format commun, qui est:
    #
    # ```
    # search: {
    #   proc: -> (values) { * je fais des trucs avec les values * },
    #   all: ['les', 'valeurs', 'aceptées'],
    #   description: "La description dans la doc"
    # }
    # ```
    #
    # On va donc transformer `additional` dans le format ci-dessus
    #
    def format_additional_param(additional, context_format = 'searching')
      if additional.is_a? Hash
        additional = additional.map do |field, value|
          if value.is_a?(Hash)
            value = {
              proc: nil,
              all: [],
              description: ''
            }.merge(value)
          elsif value.is_a? Array
            value = {
              proc: value.try(:at, 0),
              all: value.try(:at, 1) || [],
              description: value.try(:at, 2) || ''
            }
          elsif value.is_a? Proc
            value = {
              proc: value,
              all: [],
              description: ''
            }
          else
            raise "Unable to format addional #{context_format} params (got #{additional})"
          end
          [field, value]
        end.to_h
      end
      additional
    end

    def reduce_where(col, field, value)
      reducer = nil
      value.each do |v|
        query = col.model.arel_table[field.to_sym].matches("%#{v.to_s}%")
        reducer = (reducer ? reducer.or(query) : query)
      end
      col.where(reducer)
    end

    def reduce_fields_where(col, fields, value)
      reducer = nil
      fields.each do |f|
        case col.model.columns.select{|e| e.name.to_sym == f.to_sym}.first.type
        when :string
          query = col.model.arel_table[f.to_sym].matches("%#{value.to_s}%")
        when :integer
          query = col.model.arel_table[f.to_sym].eq(value.to_i)
        when :boolean
          query = false
        else
          query = col.model.arel_table[f.to_sym].eq(value.to_s)
        end

        reducer = (reducer ? reducer.or(query) : query)
      end
      col.where(reducer)
    end

    def apply_search_to_collection(col, searching_params, additional = {})
      return col if col.nil?

      searching_params.each do |field, value|
        if additional.key?(field) && additional[field].key?(:proc)
          col = col.instance_exec(value, &(additional[field][:proc]))
        elsif value.is_a?(String)
          col = (col.where(col.model.arel_table[field.to_sym].matches("%#{value.join(' ')}%")) rescue col)
        elsif value.is_a?(Array)
          col = reduce_where(col, field, value)
        elsif value.is_a?(Hash) && value.key?(:proc)
          col
        end
      end
      col
    end

    # ------------------------ Range helpers --------------------

    # Va transformer le param url en hash exploitable
    def parse_ranged_param(ranged_param, allowed_params)
      return {} unless ranged_param.present?

      fields = {}

      # Extract the fields for each type from the fields parameters
      if ranged_param.is_a?(Hash)
        ranged_param.each do |field, value|
          resource_fields = value.split(',') unless value.nil? || value.empty?
          raise InvalidRangeException, "Invalid range format for #{ranged_param}. Too many arguments for filter (#{resource_fields})." if resource_fields.length > 2
          raise InvalidRangeException, "Invalid range format for #{ranged_param}. Begin and end must be separated by a comma (,)." if resource_fields.length < 2
          fields[field.to_sym] = resource_fields
        end
      else
        raise InvalidRangeException, "Invalid range format for #{ranged_param}"
      end
      check_ranged_param(fields, allowed_params)
      fields
    end

    # Our little barrier <3
    def check_ranged_param(ranged_param, allowed)
      🔞 = ranged_param.keys.map(&:to_sym) - allowed.map(&:to_sym)
      raise InvalidRangeException, "Attributes #{🔞.map(&:to_s).to_sentence} doesn't exists or aren't rangeables. Available ranges are: #{allowed.to_sentence}" if 🔞.any?
    end

    def apply_range_to_collection(collection, ranged_params, additional = {})
      return collection if collection.nil?

      ranged_params.each do |field, value|
        if additional.key?(field) && additional[field].key?(:proc)

          # Si on a fourni des valeurs, on verifie qu'elle matchent
          if additional[field].key?(:all) && additional[field][:all].try(:any?)
            allowed = additional[field][:all].map(&:to_s)
            raise InvalidRangeValueException, "
              Value #{(value - allowed).to_sentence} is not allowed for range #{field}, can be #{allowed.to_sentence}
            " if (value - allowed).any?
          end
          collection = collection.instance_exec(value.try(:first), value.try(:last), &(additional[field][:proc]))
        elsif value.is_a? Array
          from, to = value.slice(0, 2)
          begin
            collection = collection.where(field => from..to)
          rescue ArgumentError
            raise InvalidRangeValueException, "
              Unable to create a range between values '#{from}' and '#{to}'
            "
          end
        elsif value.is_a?(Hash) && value.key?(:proc)
          collection
        end
      end
      collection
    end
  end
end
