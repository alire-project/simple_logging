package body Simple_Logging.Support is

   -----------
   -- Elide --
   -----------

   function Elide (Str : String; Len : Natural; Ellipsis : String := "..")
                   return String is
     (if Str'Length <= Len
      then Str
      else Ellipsis &
           Str (Str'First + (Str'Length - Len + Ellipsis'Length) ..
                Str'Last));
   
   ----------
   -- Rpad --
   ----------

   function Rpad (Str : String; Len : Natural; Char : Character := ' ')
                  return String is
     (if Str'Length >= Len
      then Str
      else Str & String'(1 .. Len - Str'Length => Char));

end Simple_Logging.Support;
