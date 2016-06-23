require 'active_support'

module RiceCooker
  module Filter
    extend ActiveSupport::Concern

    FILTER_PARAM = :filter

    module ClassMethods
      include Helpers

      def filtered(additional_filtering_params = {})
        cattr_accessor :filtering_keys
        cattr_accessor :custom_filters

        resource_class ||= controller_resource_class(self) unless respond_to?(:resource_class)

        # On normalize tout ca
        additional_filtering_params = format_addtional_filtering_param(additional_filtering_params)

        # On recupere tous les filtres autorisés
        allowed_keys = (filterable_fields_for(resource_class) + additional_filtering_params.keys)

        # On fait une sorte de *register_bool_filter* sur tous les champs *_at
        additional = (filterable_fields_for(resource_class) - [:created_at, :updated_at])
                     .select { |e| e =~ /_at$/ }
                     .select { |e| additional_filtering_params[e.to_s.gsub(/_at$/, '')].nil? }

        additional.each do |fi|
          name = fi.to_s.gsub(/_at$/, '')

          if fi.to_sym == :begin_at
            db_field = "#{resource_class.quoted_table_name}.\"#{fi}\""
            additional_filtering_params[:future] = {
              proc: -> (value) { value.first == 'true' ? where("#{db_field} >= ?", Time.zone.now) : where("#{db_field} < ?", Time.zone.now) },
              all: %w(true false),
              description: "Return only #{resource_class.to_s.underscore.humanize.downcase.pluralize} which begins in the future"
            }
            allowed_keys << :future
          else
            additional_filtering_params[name.to_sym] = {
              proc: -> (value) { value.first == 'true' ? where.not(fi => nil) : where(fi => nil) },
              all: %w(true false),
              description: "Return only #{name} #{resource_class.to_s.underscore.humanize.downcase.pluralize}"
            }
            allowed_keys << name
          end
        end

        # On recupere le default
        self.filtering_keys = allowed_keys
        self.custom_filters = additional_filtering_params

        has_scope :filter, type: :hash, only: [:index] do |_controller, scope, value|
          params = parse_filtering_param(value, filtering_keys)
          scope = apply_filter_to_collection(scope, params, custom_filters)
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
      def register_filter(name, proc, all = nil, description = nil)
        raise "A '#{name}' filter already exists for class #{self.class}" unless custom_filters[name].nil?
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
        raise "A '#{name}' filter already exists for class #{self.class}" unless custom_filters[name].nil?
        custom_filters[name] = {
          proc: -> (value) { value.first == 'true' ? where.not(field => nil) : where(field => nil) },
          all: %w(true false),
          description: description || "Return only #{resource_class.to_s.underscore.humanize.downcase.pluralize} with a #{field}"
        }
        filtering_keys << name
      end
    end
  end
end
