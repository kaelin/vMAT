#  clusterOptions.mk
#  vMAT
#
#  Created by Kaelin Colclasure on 4/26/13.
#  Copyright (c) 2013 Kaelin Colclasure. All rights reserved.

require 'vMATCodeMonkey'

VMATCodeMonkey.new.options_processor <<'EOS', :static
"criterion:"  arg: {                                                              \
                choice => {                                                       \
                    "distance"     => set(:useInconsistent, false),               \
                    "inconsistent" => set(:useInconsistent, true)                 \
                }                                                                 \
              },                                                                  \
              default: "inconsistent"
"cutoff:"     flag: set(:useCutoff, true), arg: vector(:double)
"depth:"      flag: set(:useInconsistent, true), arg: scalar(:index), default: 2
"maxclust:"   flag: set(:useCutoff, false), arg: vector(:index)
EOS
