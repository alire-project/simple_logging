package body Simple_Logging.Artsy is

   Sandbox : constant array (Long_Long_Integer'(0) .. 16) of Wide_Wide_String (1 .. 2)
     := ( 0 => "  ",
          1 => "⡀ ",
          2 => "⣀ ",
          3 => "⣀⡀",
          4 => "⣀⣀",
          5 => "⣀⣠",
          6 => "⣀⣤",
          7 => "⣠⣤",
          8 => "⣤⣤",
          9 => "⣦⣤",
         10 => "⣶⣤",
         11 => "⣶⣦",
         12 => "⣶⣶",
         13 => "⣶⣾",
         14 => "⣶⣿",
         15 => "⣾⣿",
         16 => "⣿⣿");

   ---------------------
   -- Braille_Sandbox --
   ---------------------

   function Braille_Sandbox (Pos, Max : Long_Long_Integer)
                             return Wide_Wide_String
   is (Sandbox
       (Long_Long_Integer'Max
          (0,
             Long_Long_Integer'Min
               (Sandbox'Last, (Pos * Sandbox'Last + Max / 2) / Max))));

end Simple_Logging.Artsy;
