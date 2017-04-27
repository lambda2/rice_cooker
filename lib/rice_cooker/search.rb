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

      def fuzzy_searched
        cattr_accessor :searching_keys

        # On recupere tous les filtres autorisés
        self.searching_keys = searchable_fields_for(resource_model)
        has_scope :fuzzy, only: [:index] do |_controller, scope, value|
          scope = reduce_fields_where(scope, searching_keys, value)
          scope
        end
      end

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
    end
  end
end
