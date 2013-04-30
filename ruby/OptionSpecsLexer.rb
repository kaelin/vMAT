#--
# DO NOT MODIFY!!!!
# This file is automatically generated by rex 1.0.5
# from lexical definition file "OptionSpecsLexer.rex".
#++

require 'racc/parser'
class OptionSpecsLexer < Racc::Parser
  require 'strscan'

  class ScanError < StandardError ; end

  attr_reader   :lineno
  attr_reader   :filename
  attr_accessor :state

  def scan_setup(str)
    @ss = StringScanner.new(str)
    @lineno =  1
    @state  = nil
  end

  def action
    yield
  end

  def scan_str(str)
    scan_setup(str)
    do_parse
  end
  alias :scan :scan_str

  def load_file( filename )
    @filename = filename
    open(filename, "r") do |f|
      scan_setup(f.read)
    end
  end

  def scan_file( filename )
    load_file(filename)
    do_parse
  end


  def next_token
    return if @ss.eos?
    
    # skips empty actions
    until token = _next_token or @ss.eos?; end
    token
  end

  def _next_token
    text = @ss.peek(1)
    @lineno  +=  1  if text == "\n"
    token = case @state
    when nil
      case
      when (text = @ss.scan(/\d+(\.\d*)/))
         action { [:number, text] }

      when (text = @ss.scan(/\w+:/))
         action { [:syntax_hash_key, ":#{text[0, text.length - 1]} =>"] }

      when (text = @ss.scan(/\:\w+/))
         action { [:symbol, text] }

      when (text = @ss.scan(/\w+/))
         action { [:identifier, text] }

      when (text = @ss.scan(/\"(\\.|[^\\"])*\"/))
         action { [:string, text] }

      when (text = @ss.scan(/=>/))
         action { [:rocket, text] }

      when (text = @ss.scan(/,/))
         action { [:comma, text] }

      when (text = @ss.scan(/{/))
         action { [:open_curly, text] }

      when (text = @ss.scan(/}/))
         action { [:close_curly, text] }

      when (text = @ss.scan(/\(/))
         action { [:open_paren, text] }

      when (text = @ss.scan(/\)/))
         action { [:close_paren, text] }

      when (text = @ss.scan(/\[/))
         action { [:close_square, text] }

      when (text = @ss.scan(/\]/))
         action { [:close_square, text] }

      when (text = @ss.scan(/\\\s+/))
         action { }

      when (text = @ss.scan(/\n/))
         action { [:eol, text] }

      when (text = @ss.scan(/\s+/))
         action { }

      else
        text = @ss.string[@ss.pos .. -1]
        raise  ScanError, "can not match: '" + text + "'"
      end  # if

    else
      raise  ScanError, "undefined state: '" + state.to_s + "'"
    end  # case state
    token
  end  # def _next_token

  def enumerate_tokens
    Enumerator.new { |token|
      loop {
        t = next_token
        break if t.nil?
        token << t
      }
    }
  end
  def normalize(source)
    scan_setup source
    out = ""
    enumerate_tokens.each do |token|
      out += ' ' + token[1]
    end
    out
  end
end # class
