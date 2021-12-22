# frozen_string_literal: true

Class.module_eval do
  def singleton(classname, superclass = nil, &block)
    klass = Class.new(superclass, &block)
    const_set(:"#{classname}Impl", klass)
    const_set(classname, klass.new)
  end
end

require_relative "kql/version"
require_relative "kql/tokenizer"
require_relative "kql/query"
require_relative "kql/filter"
require_relative "kql/combinator"
require_relative "kql/selector"
require_relative "kql/matcher"
require_relative "kql/accessor"
require_relative "kql/operator"
require_relative "kql/mapping"
require_relative "kql/kql.tab"
