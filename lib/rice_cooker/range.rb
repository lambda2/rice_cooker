# require 'active_support'

# =========================
# TODO
# =========================

# module RiceCooker
#   module Range
#     extend ActiveSupport::Concern


#     FILTER_PARAM = :range


#     module ClassMethods

#       include Helpers
      
#       def ranged additional_filtering_params = {}
#         cattr_accessor :filtering_keys
#         cattr_accessor :custom_filters

#         # On normalize tout ca
#         additional_rangeing_params = format_addtional_rangeing_param(additional_rangeing_params)

#         # On recupere tous les filtres autorisés
#         allowed_keys = (rangeable_fields_for(resource_class) + additional_rangeing_params.keys)
        
#         # On fait une sorte de *register_bool_range* sur tous les champs *_at
#         # additional = (resource_class.rangeable_fields - [:created_at, :updated_at])
#         #   .select{|e| e =~ /_at$/}
#         #   .select{|e| additional_rangeing_params[e.to_s.gsub(/_at$/, '')].nil?}
      
#         # if additional.any?
#         #   p "[!] Controller #{self.name} can be graphed on attributes: #{additional.map(&:to_sym).inspect}"
#         # end

#         # additional.each do |fi|
#         #     name = fi.to_s.gsub(/_at$/, '')

#         #     if fi.to_sym == :begin_at
#         #       db_field = "#{resource_class.quoted_table_name}.\"#{fi.to_s}\""
#         #       additional_rangeing_params[:future] = {
#         #         proc: -> (value) {value.first == "true" ? where("#{db_field} >= ?", Time.zone.now) : where("#{db_field} < ?", Time.zone.now) },
#         #         all: ['true', 'false'],
#         #         description: "Return only #{resource_class.to_s.underscore.humanize.downcase.pluralize} which begins in the future"
#         #       }
#         #       allowed_keys << :future
#         #     else
#         #       additional_rangeing_params[name.to_sym] = {
#         #         proc: -> (value) {value.first == "true" ? where.not(fi => nil) : where(fi => nil) },
#         #         all: ['true', 'false'],
#         #         description: "Return only #{name} #{resource_class.to_s.underscore.humanize.downcase.pluralize}"
#         #       }
#         #       allowed_keys << name
#         #     end
#         # end

#         # On recupere le default
#         self.ranged_keys = allowed_keys
#         self.custom_ranges = additional_rangeing_params

#         has_scope :range, :type => :hash, :only => [:index] do |controller, scope, value|
#           params = parse_rangeing_param(value, self.ranged_keys)
#           scope = apply_range_to_collection(scope, params, self.custom_ranges)
#           scope
#         end

#       end

#     end


#   end
# end
