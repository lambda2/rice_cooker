require 'csv'
require 'active_support'

module RiceCooker
  module Sort
    extend ActiveSupport::Concern

    include Helpers

    SORT_PARAM = :sort


    module ClassMethods

      # 
      # Will handle collection (index) sorting on inherited resource controllers
      # 
      # All endpoints support multiple sort fields by allowing comma-separated (`,`) sort fields.
      # Sort fields are applied in the order specified.
      # The sort order for each sort field is ascending unless it is prefixed with a minus (U+002D HYPHEN-MINUS, “-“), in which case it is descending.
      # 
      def sorted default_sorting_params = {id: :desc}
        begin
          
          cattr_accessor :default_order
          cattr_accessor :sorted_keys
          return unless self.sorted_keys.nil?

          default_sorting_params = {default_sorting_params => :asc} if default_sorting_params.is_a? Symbol
          
          # On recupere le default
          self.default_order = default_sorting_params
          self.sorted_keys = (resource_class.respond_to?(:sortable_fields) ? resource_class.sortable_fields : [])
          default_sort = param_from_defaults(default_sorting_params)

          has_scope :sort, default: default_sort, :only => [:index] do |controller, scope, value|
            if controller.params[SORT_PARAM].present?
              scope = apply_sort_to_collection(scope, parse_sorting_param(value, resource_class))
            else
              scope = apply_sort_to_collection(scope, default_sorting_params)
            end
            scope
          end
          
        rescue NoMethodError => e
          "Just wanna die ⚓️ #{e}"
        end

      end

    end


  end
end
