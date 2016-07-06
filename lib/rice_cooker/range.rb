require 'active_support'

module RiceCooker
  module Range
    extend ActiveSupport::Concern

    FILTER_PARAM = :range

    module ClassMethods
      include Helpers

      def ranged(additional_ranged_params = {})
        cattr_accessor :ranged_keys
        cattr_accessor :custom_ranges

        # Or:
        # model = self.respond_to?(:resource_class) ? self.resource_class : controller_resource_class(self)
        
        # self.resource_model ||= controller_resource_class(self)

        # On normalize tout ca
        additional_ranged_params = format_additional_param(additional_ranged_params, 'ranged')

        # On recupere tous les filtres autorisés
        allowed_keys = (rangeable_fields_for(self.resource_model) + additional_ranged_params.keys)

        # On recupere le default
        self.ranged_keys = allowed_keys
        self.custom_ranges = additional_ranged_params

        has_scope :range, type: :hash, only: [:index] do |_controller, scope, value|
          params = parse_ranged_param(value, ranged_keys)
          scope = apply_range_to_collection(scope, params, custom_ranges)
          scope
        end
      end
    end
  end
end
