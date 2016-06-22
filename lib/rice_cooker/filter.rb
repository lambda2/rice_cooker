require 'active_support'

module RiceCooker
  module Filter
    extend ActiveSupport::Concern

    include Helpers

    FILTER_PARAM = :filter

    class InvalidFilterException < Exception
    end

    class InvalidFilterValueException < Exception
    end

    # Va transformer le param url en hash exploitable
    def self.parse_filtering_param filtering_param, allowed_params

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
      Filter::check_filtering_param(fields, allowed_params)
      fields
    end

    # Our little barrier <3
    def self.check_filtering_param(filtering_param, allowed)
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
    def self.format_addtional_filtering_param additional
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

    def self.apply_filter_to_collection(collection, filtering_params, additional = {})
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

    module ClassMethods

      def filtered additional_filtering_params = {}
        cattr_accessor :filtering_keys
        cattr_accessor :custom_filters

        # On normalize tout ca
        additional_filtering_params = Filter::format_addtional_filtering_param(additional_filtering_params)

        # On recupere tous les filtres autorisés
        allowed_keys = (filterable_fields_for(resource_class) + additional_filtering_params.keys)
        
        # On fait une sorte de *register_bool_filter* sur tous les champs *_at
        additional = (resource_class.filterable_fields - [:created_at, :updated_at])
          .select{|e| e =~ /_at$/}
          .select{|e| additional_filtering_params[e.to_s.gsub(/_at$/, '')].nil?}
      
        # if additional.any?
        #   p "[!] Controller #{self.name} can be graphed on attributes: #{additional.map(&:to_sym).inspect}"
        # end

        additional.each do |fi|
            name = fi.to_s.gsub(/_at$/, '')

            if fi.to_sym == :begin_at
              db_field = "#{resource_class.quoted_table_name}.\"#{fi.to_s}\""
              additional_filtering_params[:future] = {
                proc: -> (value) {value.first == "true" ? where("#{db_field} >= ?", Time.zone.now) : where("#{db_field} < ?", Time.zone.now) },
                all: ['true', 'false'],
                description: "Return only #{resource_class.to_s.underscore.humanize.downcase.pluralize} which begins in the future"
              }
              allowed_keys << :future
            else
              additional_filtering_params[name.to_sym] = {
                proc: -> (value) {value.first == "true" ? where.not(fi => nil) : where(fi => nil) },
                all: ['true', 'false'],
                description: "Return only #{name} #{resource_class.to_s.underscore.humanize.downcase.pluralize}"
              }
              allowed_keys << name
            end
        end

        # On recupere le default
        self.filtering_keys = allowed_keys
        self.custom_filters = additional_filtering_params

        has_scope :filter, :type => :hash, :only => [:index] do |controller, scope, value|
          params = Filter::parse_filtering_param(value, self.filtering_keys)
          scope = Filter::apply_filter_to_collection(scope, params, self.custom_filters)
          scope
        end

      end

      #
      # Ajoute un filtre custom
      # 
      # name: le nom du filtre custom (ex: with_mark)
      # proc: le filtre, prend un arg `val` qui est un tableau des args du filtre
      # all: l'ensemble des valeurs acceptées pour le filtre. Laisser nil ou [] pour tout accepter
      # description: La description dans la doc
      # 
      def register_filter name, proc, all = nil, description = nil
        raise "A '#{name}' filter already exists for class #{self.class}" unless self.custom_filters[name].nil?
        self.custom_filters[name] = {
          proc: proc,
          all: all || [],
          description: description || ""
        }
        self.filtering_keys << name
      end

      #
      # Raccourci pour un filtre custom qui va filtrer si un champ est nil ou non.
      # 
      # name: le nom du filtre custom (ex: with_mark)
      # field: le champ a filtrer sur `nil` ou pas `nil` (ex: final_mark)
      # description: La description dans la doc
      # 
      def register_bool_filter name, field, description = nil
        raise "A '#{name}' filter already exists for class #{self.class}" unless self.custom_filters[name].nil?
        self.custom_filters[name] = {
          proc: -> (value) {value.first == "true" ? where.not(field => nil) : where(field => nil) },
          all: ['true', 'false'],
          description: description || "Return only #{resource_class.to_s.underscore.humanize.downcase.pluralize} with a #{field}"
        }
        self.filtering_keys << name
      end

    end


  end
end
