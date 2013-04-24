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
    @caller_file = caller(1)[0].split(':')[0]
    case out_opt
      when :pbcopy
        @out = IO.popen('pbcopy', 'w')
      when :print
        @out = $stdout
      else
        raise ArgumentError, "#{out_opt} is not an option!"
    end
    @out.puts "// vMATCodeMonkey's work; do not edit by hand!\n\n"
    initialize_options_processor
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
          else
            raise ArgumentError, "Take two arguments, or four; those are your options!"
        end
        @out.puts "\n"
      end
    end
  end

  def comment(specs)
    lines = specs.split(/,?\r?\n/)
    lines.map! do |line|
      line = indent + '// ' + line.strip
      line
    end
    lines.join("\n")
  end

  def indent(level = :last)
    @indent_level = level unless level == :last
    ' ' * @indent_level * 4
  end

  def options_processor(specs, *declspecs)
    src_specs = specs
    specs = instance_eval '{' + preprocess(specs) + '}'
    fn = File.basename @caller_file, '.rb'
    @out.puts indent(0) + options_processor_codegen(:options_results_struct, {fn: fn})
    @out.puts indent(0) + options_processor_codegen(:options_function_prologue, {fn: fn, declspecs: declspecs})
    indent(1)
    @out.puts comment src_specs
    @out.puts indent(1) + "{\n"
    @out.puts indent(2) + options_processor_codegen(:options_flags, {})
    @out.puts indent(2) + options_processor_codegen(:options_locals, {})
    specs.each { |key, spec|
      @out.puts indent(2) + '// ' + key.to_s + ' ' + spec.to_s + "\n"
      @out.puts options_processor_codegen(key, spec)
    }
    @out.puts indent(1) + "}\n"
    @out.puts indent(0) + options_processor_codegen(:options_function_epilogue, {})
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
  # Methods for options_processor specs (called at instance_eval time).
  #

  def set(flag, val)
    evaluate_set(flag, val)
    { set_thingie_from_instance_eval: [flag, val] }
  end

  def vector(spec)
    { vector_thingie_from_instance_eval: spec }
  end

  #
  # Evaluate options_processor specs.
  #

  def initialize_options_processor
    @options_flags = []
    @options_locals = ['NSUInteger optidx = NSNotFound;']
  end

  def evaluate_set(flag, val)
    @options_flags += [flag] unless @options_flags.include? flag
  end

  #
  # Generate code from options_processor specs.
  #

  def options_processor_codegen(name, spec)
    case name
      when String
        indent(2) + "There was one?\n"
      when Symbol
        selector = "#{name}_codegen"
        self.send selector, name, spec
      else
        raise ArgumentError, "#{name} is neither a Symbol nor a String!"
    end
  end

  def options_results_struct_codegen(name, spec)
    fn = spec[:fn]
    out = "struct #{fn} {"
    out += "\n#{indent}}\n\n"
    out
  end

  def options_function_prologue_codegen(name, spec)
    fn = spec[:fn]
    declespecs = spec[:declspecs] + [:void]
    out = declespecs.join(' ')
    out += "\n#{indent}#{fn}(NSArray * options, struct #{fn} * resultsOut)"
    out += "\n#{indent}{"
    out
  end

  def options_function_epilogue_codegen(name, spec)
    out = "}\n\n"
    out
  end

  def options_flags_codegen(name, spec)
    out = '// Flags: ' + @options_flags.to_s
    @options_flags.each do |flag|
      out += "\n#{indent}// #{flag}"
    end
    out
  end

  def options_locals_codegen(name, spec)
    out = '// Locals'
    @options_locals.each do |local|
      out += "\n#{indent}#{local}"
    end
    out
  end

  def array_type_codegen(name, spec)
    <<-'EOS'
        vMAT_MIType type = miDOUBLE;
        if (options == nil) return type; // Hoist this
        if ((optidx = [options indexOfObject:@"like:"]) != NSNotFound) {
            NSCParameterAssert([options count] > optidx + 1);
            vMAT_Array * like = options[optidx + 1];
            NSCParameterAssert([like respondsToSelector:@selector(type)]);
            type = like.type;
        }
        else {
            if ([options count] < 1) return type;
            NSString * spec = options[0];
            NSCParameterAssert([spec respondsToSelector:@selector(caseInsensitiveCompare:)]);
            type = vMAT_MITypeNamed(spec);
        }
    EOS
  end

end
