module RiceCooker
  module Sort
    extend ActiveSupport::Concern

    SORT_PARAM = :sort

    # Will be thrown when invalid sort param
    class InvalidSortException < Exception
    end

    # model -> resource_class with inherited resources
    def self.parse_sorting_param sorting_param, model
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
        p "Sort params accepted: #{sorting_param.inspect}"
        sorting_param
      end
      sorting_params.map{|par| [par[:field], par[:direction]]}.to_h
    end

    def self.check_sorting_param(model, sorting_param)
      sort_field = sorting_param[:field]
      sortable_fields = model.sortable_fields

      unless sortable_fields.include? sort_field.to_sym
        raise InvalidSortException.new("The #{sort_field} field is not sortable")
      end
    end

    def self.param_from_defaults(sorting_params)
      sorting_params.map{|k, v| "#{v == :desc ? '-' : ''}#{k}"}.join(',')
    end

    def self.apply_sort_to_collection(collection, sorting_params)
      return collection unless collection.any?
      p "Before apply: #{sorting_params.inspect}"
      collection.order(sorting_params)
    end

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
          default_sort = Sort::param_from_defaults(default_sorting_params)

          has_scope :sort, default: default_sort, :only => [:index] do |controller, scope, value|
            if controller.params[SORT_PARAM].present?
              scope = Sort::apply_sort_to_collection(scope, Sort::parse_sorting_param(value, resource_class))
            else
              scope = Sort::apply_sort_to_collection(scope, default_sorting_params)
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
