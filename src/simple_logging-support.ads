package Simple_Logging.Support with Preelaborate is

   -----------
   -- Elide --
   -----------

   function Elide (Str : String; Len : Natural; Ellipsis : String := "..")
                   return String;
   --  If Str'Lenght > Len, return "..remainder_of_string".

   ----------
   -- Rpad --
   ----------

   function Rpad (Str : String; Len : Natural; Char : Character := ' ')
                  return String;
   --  Left-justify String by padding with Char on the right.

   function ANSI_Scrub (Sequence : String) return String;
   --  Remove ANSI control characters from a string

end Simple_Logging.Support;
