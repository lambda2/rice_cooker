require 'active_support'

module RiceCooker
  module Filter
    extend ActiveSupport::Concern

    FILTER_PARAM = :filter

    class FilterEngine < RiceCooker::Base

      def self.action
        :filtering
      end

      def initialize(unformated_params, model)
        super
        @allowed_keys = (filterable_fields_for(@model) + @params.keys)
      end

      def register_bools
        additional = (filterable_fields_for(@model) - [:created_at, :updated_at])
                     .select { |e| e =~ /_at$/ }
                     .select { |e| @params[e.to_s.gsub(/_at$/, '')].nil? }
        additional.each { |fi| parse_bool(fi) }
      end

      def parse_bool(fi)
        if fi.to_sym == :begin_at
          parse_future_bool fi
        else
          parse_named_bool fi
        end
      end

      def parse_future_bool(fi)
        @params[:future] = {
          proc: FilterEngine.get_future_lambda("#{@model.quoted_table_name}.\"#{fi}\""),
          all: %w(true false),
          description: "Return only #{@model.to_s.underscore.humanize.downcase.pluralize} which begins in the future"
        }
        @allowed_keys << :future
      end

      def parse_named_bool(fi)
        name = fi.to_s.gsub(/_at$/, '')
        @params[name.to_sym] = {
          proc: FilterEngine.get_named_lambda(fi),
          all: %w(true false),
          description: "Return only #{name} #{@model.to_s.underscore.humanize.downcase.pluralize}"
        }
        @allowed_keys << name
      end

      def self.get_future_lambda(db_field)
        lambda do |value|
          value.first == 'true' ? where("#{db_field} >= ?", Time.zone.now) : where("#{db_field} < ?", Time.zone.now)
        end
      end

      def self.get_named_lambda(fi)
        lambda do |value|
          value.first == 'true' ? where.not(fi => nil) : where(fi => nil)
        end
      end

      def process(value, scope, custom, filter)
        params = parse_filtering_param(value, filter)
        apply_filter_to_collection(scope, params, custom)
      end
    end

    module ClassMethods
      def filtered(additional_filtering_params = {})
        cattr_accessor :filtering_keys
        cattr_accessor :custom_filters

        filter = FilterEngine.new(additional_filtering_params, resource_model)

        filter.register_bools

        # On recupere le default
        self.filtering_keys = filter.allowed_keys
        self.custom_filters = filter.params

        has_scope FILTER_PARAM, type: :hash, only: [:index] do |_controller, scope, value|
          scope = filter.process(value, scope, custom_filters, filtering_keys)
          scope
        end
      end

      #
      # Ajoute un filtre custom
      #
      # name: le nom du filtre custom (ex: with_mark)
      # proc: le filtre, prend un arg `val` qui est un tableau des args du filtre
      # all: l'ensemble des valeurs acceptées pour le filtre. Laisser nil ou pour tout accepter
      # description: La description dans la doc
      #
      def register_filter(name, proc, all = nil, description = nil)
        # raise "A '#{name}' filter already exists for class #{self.class}" unless filter_exists?(name)
        custom_filters[name] = {
          proc: proc,
          all: all || [],
          description: description || ''
        }
        filtering_keys << name
      end

      #
      # Raccourci pour un filtre custom qui va filtrer si un champ est nil ou non.
      #
      # name: le nom du filtre custom (ex: with_mark)
      # field: le champ a filtrer sur `nil` ou pas `nil` (ex: final_mark)
      # description: La description dans la doc
      #
      def register_bool_filter(name, field, description = nil)
        # raise "A '#{name}' filter already exists for class #{self.class}" unless filter_exists?(name)
        custom_filters[name] = {
          proc: FilterEngine.get_named_lambda(field),
          all: %w(true false),
          description: description || "Return only #{resource_model.to_s.underscore.humanize.downcase.pluralize} with a #{field}"
        }
        filtering_keys << name
      end

      # Check if the given custom filter name already exists
      def filter_exists?(name)
        !custom_filters[name].nil?
      end
    end
  end
end
