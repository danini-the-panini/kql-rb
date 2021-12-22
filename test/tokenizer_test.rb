require "test_helper"

class TokenizerTest < Minitest::Test
  def test_identifier
    assert_equal t(:IDENT, "foo"), ::KQL::Tokenizer.new("foo").next_token
    assert_equal t(:IDENT, "foo-bar123"), ::KQL::Tokenizer.new("foo-bar123").next_token
  end

  def test_string
    assert_equal t(:STRING, "foo"), ::KQL::Tokenizer.new('"foo"').next_token
    assert_equal t(:STRING, "foo\nbar"), ::KQL::Tokenizer.new('"foo\nbar"').next_token
  end

  def test_number
    assert_equal t(:INTEGER, 123), ::KQL::Tokenizer.new("123").next_token
    assert_equal t(:FLOAT, 1.23), ::KQL::Tokenizer.new("1.23").next_token
  end

  def test_boolean
    assert_equal t(:TRUE, true), ::KQL::Tokenizer.new("true").next_token
    assert_equal t(:FALSE, false), ::KQL::Tokenizer.new("false").next_token
  end

  def test_null
    assert_equal t(:NULL, nil), ::KQL::Tokenizer.new("null").next_token
  end

  def test_symbols
    assert_equal t(:LPAREN, '('), ::KQL::Tokenizer.new('(').next_token
    assert_equal t(:RPAREN, ')'), ::KQL::Tokenizer.new(')').next_token
    assert_equal t(:LBRACKET, '['), ::KQL::Tokenizer.new('[').next_token
    assert_equal t(:RBRACKET, ']'), ::KQL::Tokenizer.new(']').next_token
    assert_equal t(:COMMA, ','), ::KQL::Tokenizer.new(',').next_token
  end

  def test_complex_symbols
    assert_equal t(:EQUALS, '='), ::KQL::Tokenizer.new('=').next_token
    assert_equal t(:MAP, '=>'), ::KQL::Tokenizer.new('=>').next_token
    assert_equal t(:LT, '<'), ::KQL::Tokenizer.new('<').next_token
    assert_equal t(:LTE, '<='), ::KQL::Tokenizer.new('<=').next_token
    assert_equal t(:GT, '>'), ::KQL::Tokenizer.new('>').next_token
    assert_equal t(:GTE, '>='), ::KQL::Tokenizer.new('>=').next_token
    assert_equal t(:OR, '||'), ::KQL::Tokenizer.new('||').next_token
    assert_equal t(:STARTS_WITH, '^='), ::KQL::Tokenizer.new('^=').next_token
    assert_equal t(:ENDS_WITH, '$='), ::KQL::Tokenizer.new('$=').next_token
    assert_equal t(:INCLUDES, '*='), ::KQL::Tokenizer.new('*=').next_token
  end

  def test_multiple_tokens
    tokenizer = ::KQL::Tokenizer.new("dependencies > [] => (name(), values(), props())")

    assert_equal t(:IDENT, 'dependencies'), tokenizer.next_token
    assert_equal t(:GT, '>'), tokenizer.next_token
    assert_equal t(:LBRACKET, '['), tokenizer.next_token
    assert_equal t(:RBRACKET, ']'), tokenizer.next_token
    assert_equal t(:MAP, '=>'), tokenizer.next_token
    assert_equal t(:LPAREN, '('), tokenizer.next_token
    assert_equal t(:NAME, 'name()'), tokenizer.next_token
    assert_equal t(:COMMA, ','), tokenizer.next_token
    assert_equal t(:VALUES, 'values()'), tokenizer.next_token
    assert_equal t(:COMMA, ','), tokenizer.next_token
    assert_equal t(:PROPS, 'props()'), tokenizer.next_token
    assert_equal t(:RPAREN, ')'), tokenizer.next_token
    assert_equal [false, nil], tokenizer.next_token
  end

  def test_val
    tokenizer = ::KQL::Tokenizer.new('[val()]')

    assert_equal t(:LBRACKET, '['), tokenizer.next_token
    assert_equal t(:VAL, 'val'), tokenizer.next_token
    assert_equal t(:LPAREN, '('), tokenizer.next_token
    assert_equal t(:RPAREN, ')'), tokenizer.next_token
    assert_equal t(:RBRACKET, ']'), tokenizer.next_token
    assert_equal [false, nil], tokenizer.next_token
  end

  def test_val_index
    tokenizer = ::KQL::Tokenizer.new('[val(3)]')

    assert_equal t(:LBRACKET, '['), tokenizer.next_token
    assert_equal t(:VAL, 'val'), tokenizer.next_token
    assert_equal t(:LPAREN, '('), tokenizer.next_token
    assert_equal t(:INTEGER, 3), tokenizer.next_token
    assert_equal t(:RPAREN, ')'), tokenizer.next_token
    assert_equal t(:RBRACKET, ']'), tokenizer.next_token
    assert_equal [false, nil], tokenizer.next_token
  end

  def test_prop
    tokenizer = ::KQL::Tokenizer.new('[prop(foo)]')

    assert_equal t(:LBRACKET, '['), tokenizer.next_token
    assert_equal t(:PROP, 'prop'), tokenizer.next_token
    assert_equal t(:LPAREN, '('), tokenizer.next_token
    assert_equal t(:IDENT, 'foo'), tokenizer.next_token
    assert_equal t(:RPAREN, ')'), tokenizer.next_token
    assert_equal t(:RBRACKET, ']'), tokenizer.next_token
    assert_equal [false, nil], tokenizer.next_token
  end

  def test_prop_bare
    tokenizer = ::KQL::Tokenizer.new('[foo]')

    assert_equal t(:LBRACKET, '['), tokenizer.next_token
    assert_equal t(:IDENT, 'foo'), tokenizer.next_token
    assert_equal t(:RBRACKET, ']'), tokenizer.next_token
    assert_equal [false, nil], tokenizer.next_token
  end

  def test_prop_bare_val
    tokenizer = ::KQL::Tokenizer.new('[val]')

    assert_equal t(:LBRACKET, '['), tokenizer.next_token
    assert_equal t(:IDENT, 'val'), tokenizer.next_token
    assert_equal t(:RBRACKET, ']'), tokenizer.next_token
    assert_equal [false, nil], tokenizer.next_token
  end

  def test_prop_bare_prop
    tokenizer = ::KQL::Tokenizer.new('[prop]')

    assert_equal t(:LBRACKET, '['), tokenizer.next_token
    assert_equal t(:IDENT, 'prop'), tokenizer.next_token
    assert_equal t(:RBRACKET, ']'), tokenizer.next_token
    assert_equal [false, nil], tokenizer.next_token
  end

  def test_prop_matcher
    tokenizer = ::KQL::Tokenizer.new('[prop(foo) = 1]')

    assert_equal t(:LBRACKET, '['), tokenizer.next_token
    assert_equal t(:PROP, 'prop'), tokenizer.next_token
    assert_equal t(:LPAREN, '('), tokenizer.next_token
    assert_equal t(:IDENT, 'foo'), tokenizer.next_token
    assert_equal t(:RPAREN, ')'), tokenizer.next_token
    assert_equal t(:EQUALS, '='), tokenizer.next_token
    assert_equal t(:INTEGER, 1), tokenizer.next_token
    assert_equal t(:RBRACKET, ']'), tokenizer.next_token
    assert_equal [false, nil], tokenizer.next_token
  end

  def test_prop_bare_matcher
    tokenizer = ::KQL::Tokenizer.new('[foo = 1]')

    assert_equal t(:LBRACKET, '['), tokenizer.next_token
    assert_equal t(:IDENT, 'foo'), tokenizer.next_token
    assert_equal t(:EQUALS, '='), tokenizer.next_token
    assert_equal t(:INTEGER, 1), tokenizer.next_token
    assert_equal t(:RBRACKET, ']'), tokenizer.next_token
    assert_equal [false, nil], tokenizer.next_token
  end

  def test_prop_bare_val_matcher
    tokenizer = ::KQL::Tokenizer.new('[val = 1]')

    assert_equal t(:LBRACKET, '['), tokenizer.next_token
    assert_equal t(:IDENT, 'val'), tokenizer.next_token
    assert_equal t(:EQUALS, '='), tokenizer.next_token
    assert_equal t(:INTEGER, 1), tokenizer.next_token
    assert_equal t(:RBRACKET, ']'), tokenizer.next_token
    assert_equal [false, nil], tokenizer.next_token
  end

  def test_prop_bare_prop_matcher
    tokenizer = ::KQL::Tokenizer.new('[prop = 1]')

    assert_equal t(:LBRACKET, '['), tokenizer.next_token
    assert_equal t(:IDENT, 'prop'), tokenizer.next_token
    assert_equal t(:EQUALS, '='), tokenizer.next_token
    assert_equal t(:INTEGER, 1), tokenizer.next_token
    assert_equal t(:RBRACKET, ']'), tokenizer.next_token
    assert_equal [false, nil], tokenizer.next_token
  end

  private

  def t(type, value, line = nil, col = nil)
    [type, ::KQL::Tokenizer::Token.new(type, value, line, col)]
  end
end
