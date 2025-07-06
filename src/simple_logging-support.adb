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
     (if Visible_Length (Str) >= Len
      then Str
      else Str & String'(1 .. Len - Visible_Length (Str) => Char));

   ----------------
   -- ANSI_Scrub --
   ----------------

   function ANSI_Scrub (Sequence : String) return String is
      Result : String (Sequence'Range) := (others => ' ');
      Pos    : Natural := Result'First - 1;
      In_ESC : Boolean := False;
   begin
      for I in Sequence'Range loop
         if In_ESC then
            if Sequence (I) = 'm' then
               In_ESC := False;
            end if;
         else
            if Sequence (I) = ASCII.ESC then
               In_ESC := True;
            else
               Pos := Pos + 1;
               Result (Pos) := Sequence (I);
            end if;
         end if;
      end loop;

      return Result (Result'First .. Pos);
   end ANSI_Scrub;

end Simple_Logging.Support;
