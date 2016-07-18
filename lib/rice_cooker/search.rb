require 'active_support'

module RiceCooker
  module Search
    extend ActiveSupport::Concern

    FILTER_PARAM = :search

    module ClassMethods
      include Helpers

      def searched(additional_searching_params = {})
        cattr_accessor :searching_keys
        cattr_accessor :custom_searchs

        # On normalize tout ca
        additional_searching_params = format_additional_param(additional_searching_params, 'filtering')

        # On recupere tous les filtres autorisés
        allowed_keys = (searchable_fields_for(resource_model) + additional_searching_params.keys)

        # On recupere le default
        self.searching_keys = allowed_keys
        self.custom_searchs = additional_searching_params

        has_scope :search, type: :hash, only: [:index] do |_controller, scope, value|
          params = parse_searching_param(value, searching_keys)
          scope = apply_search_to_collection(scope, params, custom_searchs)
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
      def register_search(name, proc, all = nil, description = nil)
        raise "A '#{name}' search already exists for class #{self.class}" unless custom_searchs[name].nil?
        custom_searchs[name] = {
          proc: proc,
          all: all || [],
          description: description || ''
        }
        searching_keys << name
      end

      #
      # Raccourci pour un filtre custom qui va filtrer si un champ est nil ou non.
      #
      # name: le nom du filtre custom (ex: with_mark)
      # field: le champ a filtrer sur `nil` ou pas `nil` (ex: final_mark)
      # description: La description dans la doc
      #
      def register_bool_search(name, field, description = nil)
        raise "A '#{name}' search already exists for class #{self.class}" unless custom_searchs[name].nil?
        custom_searchs[name] = {
          proc: -> (value) { value.first == 'true' ? where.not(field => nil) : where(field => nil) },
          all: %w(true false),
          description: description || "Return only #{resource_model.to_s.underscore.humanize.downcase.pluralize} with a #{field}"
        }
        searching_keys << name
      end
    end
  end
end
