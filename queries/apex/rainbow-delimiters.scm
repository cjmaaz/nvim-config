; rainbow-delimiters.nvim does not ship an Apex query.
; Generic direct-child pairs cover Apex blocks, calls, literals, and indexing.
(_
  "{" @delimiter
  "}" @delimiter) @container

(_
  "(" @delimiter
  ")" @delimiter) @container

(_
  "[" @delimiter
  "]" @delimiter) @container

(type_arguments
  "<" @delimiter
  ">" @delimiter) @container
