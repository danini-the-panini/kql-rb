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
    assert_equal q(sel(matchers: [val(0)])), @parser.parse('[val()]')
    assert_equal q(sel(matchers: [val(1)])), @parser.parse('[val(1)]')
    assert_equal q(sel(matchers: [prop('foo')])), @parser.parse('[prop(foo)]')
    assert_equal q(sel(matchers: [prop('foo')])), @parser.parse('[foo]')
  end

  def test_binary_matchers
    assert_equal q(sel(matchers: [m(val(0), :==, 1)])), @parser.parse('[val() = 1]')
    assert_equal q(sel(matchers: [m(prop('name'), :==, 1)])), @parser.parse('[prop(name) = 1]')
    assert_equal q(sel(matchers: [m(prop('name'), :==, 1)])), @parser.parse('[name = 1]')
    assert_equal q(sel(matchers: [m(::KQL::Accessor::Name, :==, 'foo')])), @parser.parse('[name() = "foo"]')
    assert_equal q(sel(matchers: [m(::KQL::Accessor::Tag, :==, 'foo')])), @parser.parse('[tag() = "foo"]')
    assert_equal q(sel(matchers: [m(val(0), :!=, 1)])), @parser.parse('[val() != 1]')
    assert_equal q(sel(matchers: [m(val(0), :==, ::KQL::Matcher::Tag.new('foo'))])), @parser.parse('[val() = (foo)]')
  end

  def test_rawstring
    assert_equal q(sel(matchers: [m(val(0), :==, 'foo')])), @parser.parse('[val() = r"foo"]')
    assert_equal q(sel(matchers: [m(val(0), :==, 'foo')])), @parser.parse('[val() = r#"foo"#]')
    assert_equal q(sel(matchers: [m(val(0), :==, 'foo')])), @parser.parse('[val() = r##"foo"##]')
  end

  def test_numeric_matchers
    assert_equal q(sel(matchers: [m(val(0), :>, 1)])), @parser.parse('[val() > 1]')
    assert_equal q(sel(matchers: [m(val(0), :>=, 1)])), @parser.parse('[val() >= 1]')
    assert_equal q(sel(matchers: [m(val(0), :<, 1)])), @parser.parse('[val() < 1]')
    assert_equal q(sel(matchers: [m(val(0), :<=, 1)])), @parser.parse('[val() <= 1]')
  end

  def test_string_matchers
    assert_equal q(sel(matchers: [m(val(0), :A=, 'foo')])), @parser.parse('[val() ^= "foo"]')
    assert_equal q(sel(matchers: [m(val(0), :z=, 'foo')])), @parser.parse('[val() $= "foo"]')
    assert_equal q(sel(matchers: [m(val(0), :i=, 'foo')])), @parser.parse('[val() *= "foo"]')
  end

  def test_mapping
    assert_equal map(sel('a') => props()), @parser.parse('a => props()')
    assert_equal map(sel('a') => [props(), values()]), @parser.parse('a => (props(), values())')
  end

  private

  def q(*alternatives)
    ::KQL::Query.new(alternatives)
  end

  def map(x)
    raise 'exactly one key required' unless x.size == 1

    ::KQL::Mapping.new([sel(x.keys.first)].flatten, x.values.first)
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

  def operator(op)
    case op
    when :== then ::KQL::Operator::Equals
    when :!= then ::KQL::Operator::NotEquals
    when :>= then ::KQL::Operator::GreaterThanOrEqual
    when :>  then ::KQL::Operator::GreaterThan
    when :<= then ::KQL::Operator::LessThanOrEqual
    when :<  then ::KQL::Operator::LessThan
    when :A= then ::KQL::Operator::StartsWith
    when :z= then ::KQL::Operator::EndsWith
    when :i= then ::KQL::Operator::Includes
    else "raise unknown operator #{op}"
    end
  end

  def sel(*args, filter)
    if args.empty?
      case filter
      when ::KQL::Selector then filter
      when Array then filter.map { |f| sel(f) }
      else ::KQL::Selector.new(f(filter))
      end
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

  def val(index)
    ::KQL::Accessor::Val.new(index)
  end

  def prop(name)
    ::KQL::Accessor::Prop.new(name)
  end

  def any
    ::KQL::Matcher::Any
  end

  def props
    ::KQL::Accessor::Props
  end

  def values
    ::KQL::Accessor::Values
  end

  def m(acc, op, val)
    val = val.is_a?(::KQL::Matcher) ? val : ::KQL::Matcher::Value.new(val)
    ::KQL::Matcher::Comparison.new(acc, operator(op), val)
  end
end
