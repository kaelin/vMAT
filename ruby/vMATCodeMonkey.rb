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
        @out.puts "// vMATCodeMonkey's work; do not edit by hand!\n\n"
      when :snippet
        @out = $stdout
      else
        raise ArgumentError, "#{out_opt} is not an option!"
    end
    @todo = []
    initialize_options_processor
  end

  def named_coercions(&template_block)
    MI_NUMERIC_TYPE_NAMES.each do |to|
      @out.puts yield to
      @out.puts "\n"
    end
  end

  def named_types(&template_block)
    MI_NUMERIC_TYPE_NAMES.each do |type|
      @out.puts yield type
    end
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
    case level
      when :dec
        @indent_level -= 1
      when :inc
        @indent_level += 1
      when :last
        # rest
      else
        @indent_level = level
    end
    ' ' * @indent_level * 4
  end

  def options_processor(specs, *declspecs)
    src_specs = specs
    specs = instance_eval '{' + preprocess(specs) + '}'
    fn = File.basename @caller_file, '.mk'
    specs[:fn] = fn
    @todo.each { |proc| proc.call(specs) }
    specs.tap { |x| x.delete(:fn) }
    @out.puts indent(0) + options_processor_codegen(:options_results_struct, {:fn => fn})
    @out.puts indent(0) + options_processor_codegen(:options_function_prologue, {:fn => fn, :declspecs => declspecs})
    indent(1)
    @out.puts comment src_specs
    @out.puts indent + options_processor_codegen(:options_inits, {})
    @out.puts indent + options_processor_codegen(:options_flags, {})
    @out.puts indent + options_processor_codegen(:options_locals, {})
    @out.puts indent + options_processor_codegen(:options_normalization, {})
    specs.each { |key, spec|
      @out.puts indent + '// ' + key.to_s + ' ' + spec.to_s + "\n"
      @out.puts options_processor_codegen(key, spec)
    }
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

  def later_with_spec(key, evaluate_block)
    @todo += [lambda { |specs| evaluate_block.call(specs[key]) }]
    key
  end

  #
  # Methods for options_processor specs (called at instance_eval time).
  #

  def array_type
    later_with_spec :array_type_ie, lambda { |spec| evaluate_array_type spec }
  end

  def set(flag, val)
    evaluate_set(flag, val)
    { :set_ie => [flag, val] }
  end

  def vector(spec)
    { :vector_ie => spec }
  end

  #
  # Evaluate options_processor specs.
  #

  def initialize_options_processor
    @options_flags = []
    @options_locals = ['NSMutableArray * remainingOptions = nil;', 'NSUInteger optidx = NSNotFound;']
    @options_slots = ['NSMutableArray * remainingOptions;']
    @options_inits = ['resultsOut->remainingOptions = nil;']
  end

  def evaluate_array_type(spec)
    @options_slots += ['vMAT_MIType type;']
    default = spec[:default] || :none
    @options_inits += ["resultsOut->type = mi#{default.to_s.upcase};"]
  end

  def evaluate_set(flag, val)
    unless @options_flags.include? flag
      @options_flags += [flag]
      @options_slots += ["bool #{flag};"]
    end
  end

  #
  # Generate code from options_processor specs.
  #

  def options_processor_codegen(name, spec)
    case name
      when String
        indent + "There was one?\n"
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
    indent(:inc)
    @options_slots.each do |slot|
      out += "\n#{indent}#{slot}"
    end
    indent(:dec)
    out += "\n#{indent}};\n\n"
    out += "#define WITH_#{fn}(options, opts) struct #{fn} opts; #{fn}(options, &opts)\n\n"
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

  def options_inits_codegen(name, spec)
    out = '// Initialize resultsOut struct'
    @options_inits.each do |init|
      out += "\n#{indent}#{init}"
    end
    out
  end

  def options_flags_codegen(name, spec)
    out = '// Flags: ' + @options_flags.to_s
    @options_flags.each do |flag|
      out += "\n#{indent}bool #{flag}_wasSet = false;"
      out += "\n#{indent}resultsOut->#{flag} = false;"
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

  def options_normalization_codegen(name, spec)
    "// Options array normalization\n" + <<-'EOS'
    if ([options count] > 0) {
        remainingOptions = [options mutableCopy];
        resultsOut->remainingOptions = remainingOptions;
        options = nil;
    }
    else return;
    EOS
  end

  def array_type_ie_codegen(name, spec)
    <<-'EOS'
    if ((optidx = [remainingOptions indexOfObject:@"like:"]) != NSNotFound) {
        NSCParameterAssert([remainingOptions count] > optidx + 1);
        vMAT_Array * like = remainingOptions[optidx + 1];
        NSCParameterAssert([like respondsToSelector:@selector(type)]);
        resultsOut->type = like.type;
        [remainingOptions removeObjectsInRange:NSMakeRange(optidx, 2)];
    }
    else {
        NSString * spec = remainingOptions[0];
        NSCParameterAssert([spec respondsToSelector:@selector(lowercaseString)]);
        resultsOut->type = vMAT_MITypeNamed(spec);
        [remainingOptions removeObjectAtIndex:0];
    }
    EOS
  end

end
