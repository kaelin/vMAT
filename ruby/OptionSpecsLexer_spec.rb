require 'rspec'
require '../ruby/OptionSpecsLexer'
require '../ruby/vMATCodeMonkey'

describe 'The lexer for preprocessing option specifications' do

  it 'should handle ruby 1.9-style hash keys.' do
    lexer = OptionSpecsLexer.new
    lexer.scan_setup('sweet:')
    result = lexer.next_token
    result.should == [:syntax_hash_key, ':sweet =>']
  end

  it 'should understand newlines are delimiters.' do
    lexer = OptionSpecsLexer.new
    lexer.scan_setup <<-'EOS'
      one_thing:
      after_another:
    EOS
    result = lexer.enumerate_tokens.to_a
    result.should == [[:syntax_hash_key, ':one_thing =>'], [:eol, "\n"], [:syntax_hash_key, ':after_another =>'],
                      [:eol, "\n"]]
  end

  it 'should allow long specifications to be continued on the next line.' do
    lexer = OptionSpecsLexer.new
    lexer.scan_setup <<-'EOS'
      one_thing:    \
      and_another:
    EOS
    result = lexer.enumerate_tokens.to_a
    result.should == [[:syntax_hash_key, ':one_thing =>'], [:syntax_hash_key, ':and_another =>'], [:eol, "\n"]]
  end

  it 'should handle string literals.' do
    lexer = OptionSpecsLexer.new
    lexer.scan_setup(' "Literally, see." ')
    result = lexer.next_token
    result.should == [:string, '"Literally, see."']
  end

  it 'should handle symbol literals.' do
    lexer = OptionSpecsLexer.new
    lexer.scan_setup(' :literal ')
    result = lexer.next_token
    result.should == [:symbol, ':literal']
  end

  it 'should handle numeric literals.' do
    lexer = OptionSpecsLexer.new
    lexer.scan_setup(' 3. 3.14159 ')
    result = lexer.enumerate_tokens.to_a
    result.should == [[:number, '3.'], [:number, '3.14159']]
  end

  it 'should handle strings, symbols, bare words, commas, and the rocket operator.' do
    lexer = OptionSpecsLexer.new
    lexer.scan_setup <<-'EOS'
      :name => "Kaelin Colclasure", :login => kaelin
    EOS
    result = lexer.enumerate_tokens.to_a
    result.should == [[:symbol, ':name'], [:rocket, '=>'], [:string, '"Kaelin Colclasure"'], [:comma, ','],
                      [:symbol, ':login'], [:rocket, '=>'], [:identifier, 'kaelin'], [:eol, "\n"]]
  end

  it 'should be able to tokenize a complete, preexisting specification!' do
    lexer = OptionSpecsLexer.new
    lexer.scan_setup <<-'EOS'
      "criterion:"  arg: { choice => { "distance" => set(:useInconsistent, false),       \
                                       "inconsistent" => set(:useInconsistent, true) }}, \
                    default: "inconsistent"
      "cutoff:"     flag: set(:useCutoff, true), arg: vector(:double)
      "depth:"      flag: set(:useInconsistent, true), arg: scalar(:index), default: 2
      "maxclust:"   flag: set(:useCutoff, false), arg: vector(:index)
    EOS
    result = lexer.enumerate_tokens.to_a
    result.length.should == 77
  end

end

describe 'The normalized source' do

  it 'should work as input to the old preprocess method.' do
    lexer = OptionSpecsLexer.new
    monkey = VMATCodeMonkey.new(:snippet)
    source = <<-'EOS'
      array_type    default: :double
    EOS
    result = monkey.preprocess(lexer.normalize source)
    result.should == 'array_type => { :default => :double }'
  end

end