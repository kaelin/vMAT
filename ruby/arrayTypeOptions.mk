#  arrayTypeOptions.mk
#  vMAT
#
#  Created by Kaelin Colclasure on 4/23/13.
#  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.

require_relative 'vMATCodeMonkey'

VMATCodeMonkey.new(:pbcopy).options_processor <<EOS
  array_type    default: :double
EOS

VMATCodeMonkey.new.options_processor <<EOS, :static
  "criterion:"  arg: { choice => { "distance" => set(:useInconsistent, false), "inconsistent" => set(:useInconsistent, true) }}, default: "inconsistent"
  "cutoff:"     flag: set(:useCutoff, true), arg: vector(:double)
  "depth:"      flag: set(:useInconsistent, true), arg: scalar(:index), default: 2
  "maxclust:"   flag: set(:useCutoff, false), arg: vector(:index)
  "xaperiment:" arg: choice("black", "white", "red"), default: "white", flag: set(:greatSuccess, true)
  "xachangeme:" arg: string, default: "unspecified"
EOS
