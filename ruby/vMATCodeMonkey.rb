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

  def initialize out_opt = :print
    case out_opt
      when :pbcopy
        @out = IO.popen('pbcopy', 'w')
      when :print
        @out = $stdout
    end
    @out.puts "// Monkey's work; do not edit by hand!\n\n"
  end

  def coercions  &template_block
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

  #MI_NUMERIC_TYPES.each {|to|
  #    MI_NUMERIC_TYPES.each {|fm|
  #        to_t = to[2, to.length - 2]
  #        fm_t = fm[2, fm.length - 2]
  #        print "- (void)_copy_#{to}_from_#{fm}:(vMAT_Array *)matrix;\n{\n"
  #        print "    copyFrom(self, matrix, #{to_t}, #{fm_t});\n"
  #        print "}\n\n"
  #    }
  #}
    
end
