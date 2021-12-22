# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "kql"
require "kdl"

require "minitest/autorun"

class Minitest::Test
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

  def assert_query_fetches(query, expected)
    actual = @parser.parse(query).execute(document)
    actual = actual.first if actual.is_a?(Array) && actual.size == 1
    actual = simplify(actual)
    assert expected == actual, "expected:\n#{to_string(expected)}\n\nactual:\n#{to_string(actual)}"
  end

  def simplify(x)
    case x
    when ::KDL::Value then x.value
    when Array then x.map { |e| simplify(e) }
    when Hash then x.transform_values { |e| simplify(e) }
    else x
    end
  end

  def to_string(thing)
    if thing.is_a?(Array)
      if thing[0].is_a?(::KDL::Node)
        thing.map(&:to_s).join(",\n")
      else
        "[#{thing.map(&:inspect).join(',')}]"
      end
    else
      thing.to_s
    end
  end
end
