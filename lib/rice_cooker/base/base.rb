
module RiceCooker
  class Base
    include Helpers
    attr_accessor :params
    attr_accessor :model
    attr_accessor :allowed_keys

    def initialize(unformated_params, model)
      @params = format_additional_param((unformated_params || {}), self.class.action)
      @model = model
      @allowed_keys = []
    end

    def self.action
      raise "You must override action"
    end
  end
end
