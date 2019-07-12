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

end Simple_Logging.Support;
