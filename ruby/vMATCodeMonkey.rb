#  vMATCodeMonkey.rb
#  vMAT
#
#  Created by Kaelin Colclasure on 4/23/13.
#  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.

class VMATCodeMonkey

  MI_NUMERIC_TYPES = %w[
    miINT8
    miUINT8
    miINT16
    miUINT16
    miINT32
    miUINT32
    miSINGLE
    miDOUBLE
    miINT64
    miUINT64
  ]

  MI_NUMERIC_TYPE_NAMES = MI_NUMERIC_TYPES.map { |mi| mi[2, mi.length - 2].downcase } + [ "index", "logical" ]

  def initialize(out_opt = :print)
    case out_opt
      when :pbcopy
        @out = IO.popen('pbcopy', 'w')
      when :print
        @out = $stdout
    end
    @out.puts "// vMATCodeMonkey's work; do not edit by hand!\n\n"
  end

  def coercions(&template_block)
    MI_NUMERIC_TYPES.each do |to|
      MI_NUMERIC_TYPES.each do |fm|
        case template_block.arity
          when 2
            @out.puts yield to, fm
          when 4
            to_t = to[2, to.length - 2]
            fm_t = fm[2, fm.length - 2]
            @out.puts yield to, fm, to_t, fm_t
        end
        @out.puts "\n"
      end
    end
  end

  def comment(specs)
    lines = specs.split(/,?\r?\n/)
    lines.map! do |line|
      line = indent(1) + '// ' + line.strip
      line
    end
    lines.join("\n")
  end

  def indent(level)
    ' ' * level * 4
  end

  def options_processor(specs)
    @out.puts comment specs
    specs = instance_eval '{' + preprocess(specs) + '}'
    @out.puts indent(1) + "{\n"
    specs.each { |key, spec|
      @out.puts indent(2) + '// ' + key.to_s + ' ' + spec.to_s + "\n"
    }
    @out.puts indent(1) + "}\n\n"
  end

  #
  # Preprocess options specs to reduce the required syntactical clutter.
  #

  def preprocess(specs)
    lines = specs.split(/,?\r?\n/)
    lines.map! do |line|
      parts = line.strip.split(/\s+/)
      parts[0] = "'" + parts[0] + "'" if parts[0][0] == '-'
      parts.insert(1, '=>') if parts[1] != '=>'
      parts.insert(2, '{').insert(-1, '}') if parts[2] != '{'
      parts.join(' ')
    end
    lines.join(',')
  end

  #
  # These methods are to be called from specs at instance_eval time.
  #

  def set(name, val)
    { set_thingie_from_instance_eval: [name, val] }
  end

  def vector(spec)
    { vector_thingie_from_instance_eval: spec }
  end

end
