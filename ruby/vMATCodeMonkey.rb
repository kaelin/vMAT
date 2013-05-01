#  vMATCodeMonkey.rb
#  vMAT
#
#  Created by Kaelin Colclasure on 4/23/13.
#  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.

require 'pp'
require 'OptionSpecsLexer'

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
    specs.each do |key, spec|
      @out.puts indent + '// ' + key.to_s + ' ' + spec.to_s + "\n"
      @out.puts options_processor_codegen(key, spec)
    end
    @out.puts indent(0) + options_processor_codegen(:options_function_epilogue, {})
  end

  #
  # Preprocess options specs to reduce the required syntactical clutter.
  #

  def preprocess(specs)
    lexer = OptionSpecsLexer.new
    specs = lexer.normalize specs
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

  def shake_tree(specs, key)
    parent = find_parent(specs, key)
    parent ? { parent => specs[parent] } : nil
  end

  def find_parent(specs, key, keypath = [])
    specs.each do |k, v|
      if k == key
        return (keypath + [k])[0]
      elsif v.is_a?(Hash)
        branch = find_parent(v, key, keypath + [k])
        unless branch.nil?
          return branch
        end
      end
    end
    nil
  end

  def later_with_spec(key, evaluate_block)
    case evaluate_block.arity
      when 1
        @todo += [lambda { |specs| evaluate_block.call(shake_tree specs, key) }]
      when 2
        @todo += [lambda { |specs| evaluate_block.call(specs, key) }]
      else
        raise ArgumentError, "Take one or two arguments; no more, no less."
    end
    key
  end

  #
  # Methods for options_processor specs (called at instance_eval time).
  #

  def array_type
    later_with_spec :array_type_ie, lambda { |spec| evaluate_array_type spec }
  end

  $choice_ie = 'choice_ie0'

  def choice(*alternatives)
    choice_ie = $choice_ie.succ!.to_sym
    later_with_spec choice_ie, lambda { |specs, key| evaluate_choice(specs, key) }
    if alternatives.empty?
      choice_ie
    else
      { choice_ie => alternatives }
    end
  end

  $scalar_ie = 'scalar_ie0'

  def scalar(type)
    scalar_ie = $scalar_ie.succ!.to_sym
    later_with_spec scalar_ie, lambda { |specs, key| evaluate_scalar(specs, key) }
    { scalar_ie => type, :type => type }
  end

  $set_ie = 'set_ie0'

  def set(flag, val)
    set_ie = $set_ie.succ!.to_sym
    evaluate_set(flag, val)
    { set_ie => [flag, val] }
  end

  $string_ie = 'string_ie0'

  def string
    string_ie = $string_ie.succ!.to_sym
    later_with_spec string_ie, lambda { |specs, key| evaluate_string(specs, key) }
    { string_ie => '' }
  end

  $vector_ie = 'vector_ie0'

  def vector(type)
    vector_ie = $vector_ie.succ!.to_sym
    later_with_spec vector_ie, lambda { |specs, key| evaluate_vector(specs, key) }
    { vector_ie => type, :type => type }
  end

  #
  # Evaluate options_processor specs.
  #

  def initialize_options_processor
    @options_flags = []
    @options_flag_defaults = {}
    @options_locals = ['__block NSMutableArray * remainingOptions = nil;',
                       '__block NSUInteger optidx = NSNotFound;',
                       'id (^ optarg)() = ^ { NSCParameterAssert([remainingOptions count] > optidx + 1); return remainingOptions[optidx + 1]; };']
    @options_slots = ['NSMutableArray * remainingOptions;']
    @options_inits = ['resultsOut->remainingOptions = nil;']
    @options_optarg_unused = true
  end

  def evaluation_preamble(specs, key)
    spec = shake_tree specs, key
    root = spec.keys[0]
    slot = /\w+/.match(root)[0]
    rest = spec[root]
    specs[root][:arg][:key] = key
    specs[root][:arg][:slot] = slot
    @options_optarg_unused = false
    return spec, root, slot, rest
  end

  def evaluate_array_type(spec)
    @options_slots += ['vMAT_MIType type;']
    default = spec[:array_type_ie][:default] || :none
    @options_inits += ["resultsOut->type = mi#{default.to_s.upcase};"]
    @options_optarg_unused = false
  end

  def evaluate_choice(specs, key)
    spec, root, slot, rest = evaluation_preamble(specs, key)
    kind = rest[:arg][key].is_a?(Hash) ? :choice_with_flags : :choice
    specs[root][:arg][:kind] = kind
    @options_slots += ["NSString * #{slot};"]
    default = rest[:default]
    if default.nil?
      @options_inits += ["resultsOut->#{slot} = nil;"]
    else
      @options_inits += ["resultsOut->#{slot} = @\"#{default}\";"]
      if kind == :choice_with_flags
        choices = rest[:arg][rest[:arg][:key]]
        setter = Hash[*choices[default].to_a[0][1]]
        @options_flag_defaults.merge!(setter)
      end
    end
  end

  def evaluate_scalar(specs, key)
    spec, root, slot, rest = evaluation_preamble(specs, key)
    specs[root][:arg][:kind] = :scalar_or_vector
    @options_slots += ["vMAT_Array * #{slot};"]
    default = rest[:default]
    if default.nil?
      @options_inits += ["resultsOut->#{slot} = nil;"]
    else
      type = rest[:arg][:type]
      @options_inits += ["resultsOut->#{slot} = vMAT_coerce(@#{default}, @[ @\"#{type}\" ]);"]
    end
  end

  def evaluate_set(flag, val)
    unless @options_flags.include? flag
      @options_flags += [flag]
      @options_slots += ["bool #{flag};"]
    end
  end

  def evaluate_string(specs, key)
    spec, root, slot, rest = evaluation_preamble(specs, key)
    specs[root][:arg][:kind] = :string
    @options_slots += ["NSString * #{slot};"]
    default = rest[:default]
    if default.nil?
      @options_inits += ["resultsOut->#{slot} = nil;"]
    else
      @options_inits += ["resultsOut->#{slot} = @\"#{default}\";"]
    end
  end

  def evaluate_vector(specs, key)
    spec, root, slot, rest = evaluation_preamble(specs, key)
    specs[root][:arg][:kind] = :scalar_or_vector
    @options_slots += ["vMAT_Array * #{slot};"]
    @options_inits += ["resultsOut->#{slot} = nil;"]
  end

  #
  # Generate code from options_processor specs.
  #

  def options_processor_codegen(name, spec)
    case name
      when String
        out = "#{indent}if ((optidx = [remainingOptions indexOfObject:@\"#{name}\"]) != NSNotFound) {\n"
        indent(:inc)
        spec.each do |key, rest|
          out += indent + options_processor_codegen(key, rest)
        end
        out += "#{indent(:dec)}}\n"
        out
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
      default = @options_flag_defaults[flag] || false
      out += "\n#{indent}bool #{flag}_wasSet = false;"
      out += "\n#{indent}resultsOut->#{flag} = #{default};"
    end
    out
  end

  def options_locals_codegen(name, spec)
    out = '// Locals'
    if @options_optarg_unused
      @options_locals.delete_at(2)
    end
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
        vMAT_Array * like = optarg();
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

  def arg_codegen(name, spec)
    case spec[:kind]
      when :choice
        out = "// Choice is good... Have some.\n"
      when :choice_with_flags
        out = options_processor_codegen(spec[:kind], spec)
      when :scalar_or_vector
        out = "resultsOut->#{spec[:slot]} = vMAT_coerce(optarg(), @[ @\"#{spec[:type]}\" ]);\n"
      when :string
        out = "resultsOut->#{spec[:slot]} = [optarg() description];\n"
      else
        raise ArgumentError, "#{spec[:kind]}?"
    end
    out += "#{indent}[remainingOptions removeObjectsInRange:NSMakeRange(optidx, 2)];\n"
    out
  end

  def choice_with_flags_codegen(name, spec)
    respec = spec[spec[:key]]
    out = "{\n#{indent(:inc)}NSMutableArray * remainingOptions = [@[ optarg(), optarg() ] mutableCopy];\n"
    out += "#{indent}NSUInteger optidx = NSNotFound;\n"
    respec.each do |key, rest|
      out += options_processor_codegen(key, { :flag => rest, :arg => { :slot => spec[:slot], :kind => :string } })
    end
    out += "#{indent(:dec)}}\n"
    out
  end

  def default_codegen(name, spec)
    "// Default #{spec}\n"
  end

  def flag_codegen(name, spec)
    flag = spec[spec.keys[0]][0]
    val = spec[spec.keys[0]][1]
    out = "if (#{flag}_wasSet) NSCParameterAssert(#{val} == resultsOut->#{flag});\n"
    out += "#{indent}else { resultsOut->#{flag} = #{val}; #{flag}_wasSet = true; }\n"
    out
  end

end
