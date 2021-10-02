require 'test_helper'

class ParserTest < Minitest::Test
  def setup
    @parser = ::KQL::Parser.new
  end

  def test_selectors
    assert_equal q(::KQL::Selector.new(::KQL::Filter.new(node: 'a'))),
                 @parser.parse('a')
    assert_equal q(::KQL::Selector.new(::KQL::Filter::Top)),
                 @parser.parse('top()')
    assert_equal q(::KQL::Selector.new(::KQL::Filter.new(matchers: ::KQL::Matcher::Any))),
                 @parser.parse('[]')
    assert_equal q(::KQL::Selector.new(::KQL::Filter.new(tag: ::KQL::Matcher::AnyTag))),
                 @parser.parse('()')
    assert_equal q(::KQL::Selector.new(::KQL::Filter.new(tag: ::KQL::Matcher::Tag.new('foo')))),
                 @parser.parse('(foo)')
  end

  private

  def q(*alternatives)
    ::KQL::Query.new(alternatives)
  end

  def m(h)
    raise 'Exactly one key is required!' unless h.size == 1

    ::KQL::Mapping.new(h.keys.first, h.values.first)
  end
end
