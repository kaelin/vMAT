
vMAT API Conventions
====================

### Options Arrays

TBD.

### Flexible Indexes

TBD.

### Multiple Return Values

When a **vMAT** function needs to return multiple values, it will return an `NSArray`. Very often, not all of the values the function _can_ return are needed, and thus computing and returning them would be a waste of CPU cycles and memory. So **vMAT** functions that return multiple values _also_ allow uninteresting values to be _suppressed_. The option syntax for suppressing unwanted return values looks like this:

    NSArray * onlyUniqued = vMAT_unique(matrix, @[ @"want:", @"[~, ~, _]" ]);
    vMAT_Array * matY = onlyUniqued[2];

The interpretation of this options array (`@[ @"want:", @"[~, ~, _]" ]`) works like this:

  - The `@"want:"` tells the function that the option is present, and that the next element in the options array contains the _want specification_.
  - The _want specification_ string is interpolated into a vector of logical values; `false` where the corresponding element in the returned array can be suppressed, and `true` where it should be returned.
    - The string is split into individual entries delimited by commas; there _must_ be as many entries as the function has return values, or an exception is thrown.
    - Within each entry, leading space and `'['` characters are ignored.
    - If the first non-ignored character of an entry is `'~'`, the corresponding element of the logical vector is `false`.
    - Otherwise, the corresponding element of the logical vector is `true`; use `'_'` (an underscore, meaning _fill-in-the-blank_) or the name of the variable the returned element will be assigned to as a mnemonic annotation.

These interpolation rules leave a lot of room for creativity and/or abuse; try to refrain from either. Good _want specifications_ should be obvious in their intent. Assiduously eschew obfuscation.

