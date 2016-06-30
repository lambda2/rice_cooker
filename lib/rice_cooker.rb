require 'action_controller'

module RiceCooker
  autoload :Helpers,  'rice_cooker/helpers'
  autoload :Filter,   'rice_cooker/filter'
  autoload :Sort,     'rice_cooker/sort'
  autoload :Range,    'rice_cooker/range'
  autoload :VERSION,  'rice_cooker/version'
end

module ActionController
  class Base
    include RiceCooker::Sort
    include RiceCooker::Filter
    include RiceCooker::Range
  end
end
