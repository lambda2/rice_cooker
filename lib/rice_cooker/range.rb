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

        resource_class ||= controller_resource_class(self) unless respond_to?(:resource_class)

        # On normalize tout ca
        additional_ranged_params = format_addtional_ranged_param(additional_ranged_params)

        # On recupere tous les filtres autorisés
        allowed_keys = (rangeable_fields_for(resource_class) + additional_ranged_params.keys)

        # On fait une sorte de *register_bool_range* sur tous les champs *_at
        # additional = (resource_class.rangeable_fields - [:created_at, :updated_at])
        #   .select{|e| e =~ /_at$/}
        #   .select{|e| additional_ranged_params[e.to_s.gsub(/_at$/, '')].nil?}

        # if additional.any?
        #   p "[!] Controller #{self.name} can be graphed on attributes: #{additional.map(&:to_sym).inspect}"
        # end

        # additional.each do |fi|
        #     name = fi.to_s.gsub(/_at$/, '')

        #     if fi.to_sym == :begin_at
        #       db_field = "#{resource_class.quoted_table_name}.\"#{fi.to_s}\""
        #       additional_ranged_params[:future] = {
        #         proc: -> (value) {value.first == "true" ? where("#{db_field} >= ?", Time.zone.now) : where("#{db_field} < ?", Time.zone.now) },
        #         all: ['true', 'false'],
        #         description: "Return only #{resource_class.to_s.underscore.humanize.downcase.pluralize} which begins in the future"
        #       }
        #       allowed_keys << :future
        #     else
        #       additional_ranged_params[name.to_sym] = {
        #         proc: -> (value) {value.first == "true" ? where.not(fi => nil) : where(fi => nil) },
        #         all: ['true', 'false'],
        #         description: "Return only #{name} #{resource_class.to_s.underscore.humanize.downcase.pluralize}"
        #       }
        #       allowed_keys << name
        #     end
        # end

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
