require 'test_helper'

class ParserTest < Minitest::Test
  def setup
    @parser = ::KQL::Parser.new
  end

  def test_selectors
    assert_equal q(sel('a')), @parser.parse('a')
    assert_equal q(sel(top)), @parser.parse('top()')
    assert_equal q(sel(tag)), @parser.parse('()')
    assert_equal q(sel(tag('foo'))), @parser.parse('(foo)')
  end

  def test_combined_selectors
    assert_equal q(sel('a', :-, 'b')), @parser.parse('a b')
    assert_equal q(sel('a', :>, 'b')), @parser.parse('a > b')
    assert_equal q(sel('a', :+, 'b')), @parser.parse('a + b')
    assert_equal q(sel('a', :~, 'b')), @parser.parse('a ~ b')
  end

  def test_multiple_selectors
    assert_equal q(sel('a', :-, 'b', :-, 'c')), @parser.parse('a b c')
    assert_equal q(sel('a', :>, 'b', :>, 'c')), @parser.parse('a > b > c')
    assert_equal q(sel('a', :+, 'b', :+, 'c')), @parser.parse('a + b + c')
    assert_equal q(sel('a', :~, 'b', :~, 'c')), @parser.parse('a ~ b ~ c')
    assert_equal q(sel('a', :~, 'b', :+, 'c', :>, 'd', :-, 'e')), @parser.parse('a ~ b + c > d e')
  end

  def test_alternatives
    assert_equal q(sel('a'), sel('b')), @parser.parse('a || b')
    assert_equal q(sel('a', :-, 'aa'), sel('b', :-, 'bb')), @parser.parse('a aa || b bb')
  end

  def test_matchers
    assert_equal q(sel(matchers: [any])), @parser.parse('[]')
    assert_equal q(sel(matchers: [val()])), @parser.parse('[val()]')
    assert_equal q(sel(matchers: [val(1)])), @parser.parse('[val(1)]')
    assert_equal q(sel(matchers: [prop('foo')])), @parser.parse('[prop(foo)]')
    assert_equal q(sel(matchers: [prop('foo')])), @parser.parse('[foo]')
  end

  private

  def q(*alternatives)
    ::KQL::Query.new(alternatives)
  end

  def m(h)
    raise 'Exactly one key is required!' unless h.size == 1

    ::KQL::Mapping.new(h.keys.first, h.values.first)
  end

  def combinator(com)
    case com
    when :- then ::KQL::Combinator::Child
    when :> then ::KQL::Combinator::ImmediateChild
    when :~ then ::KQL::Combinator::Sibling
    when :+ then ::KQL::Combinator::ImmediateSibling
    else raise "unknown combinator #{com}"
    end
  end

  def sel(*args, filter)
    if args.empty?
      filter.is_a?(::KQL::Selector) ? filter : ::KQL::Selector.new(f(filter))
    elsif args.length == 2
      ::KQL::Selector::Combined.new(f(args[0]), combinator(args[1]), sel(filter))
    else
      sel(*args[0...-2], sel(*args[-2..-1], filter))
    end
  end

  def node(name)
    ::KQL::Filter.new(node: name)
  end

  def tag(name = nil)
    return ::KQL::Filter.new(tag: ::KQL::Matcher::AnyTag) if name.nil?

    ::KQL::Filter.new(tag: ::KQL::Matcher::Tag.new(name))
  end

  def top
    ::KQL::Filter::Top
  end

  def f(x)
    case x
    when String then filter(node: x)
    when Hash then filter(**x)
    else x
    end
  end

  def filter(node: nil, tag: nil, matchers: [])
    ::KQL::Filter.new(node: node, tag: tag, matchers: matchers)
  end

  def val(index = nil)
    ::KQL::Accessor::Val.new(index)
  end

  def prop(name)
    ::KQL::Accessor::Prop.new(name)
  end

  def any
    ::KQL::Matcher::Any
  end
end
