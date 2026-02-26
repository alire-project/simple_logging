package Simple_Logging.Spinners with Preelaborate is

   --  This package provides spinner definitions for use with the status line
   --  functionality of Simple_Logging.

   --  ASCII safe
   Classic : constant Any_Spinner := "/-\|";

   --  Unicode spinners
   Braille_6    : constant Any_Spinner := "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏";
   Braille_8    : constant Any_Spinner := "⡇⠇⠏⠋⠛⠙⠹⠸⢸⢰⣰⣠⣤⣄⣆⡆";
   Clocks       : constant Any_Spinner := "🕐🕑🕒🕓🕔🕕🕖🕗🕘🕙🕚🕛";
   Eight        : constant Any_Spinner := "⠋⠛⠙⠛⠚⠞⠖⠶⠦⢦⢤⣤⣠⣤⣄⣤⡤⡴⠴⠶⠲⠳⠓⠛";
   Eight_Fast   : constant Any_Spinner := "⠋⠙⠚⠖⠦⢤⣠⣄⡤⠴⠲⠓";
   Eight_Short  : constant Any_Spinner := "⠋⠉⠙⠘⠚⠒⠖⠆⠦⠤⢤⢠⣠⣀⣄⡄⡤⠤⠴⠰⠲⠒⠓⠃";
   Halves       : constant Any_Spinner := "◐◓◑◒";
   Moon         : constant Any_Spinner := "🌑🌒🌓🌔🌕🌖🌗🌘";
   Quarters     : constant Any_Spinner := "◴◷◶◵";
   Snake        : constant Any_Spinner := "⡇⠇⠏⠋⠛⠙⠛⠚⠞⠖⠶⠦⢦⢤⣤⣄⣆⡆";
   Squares      : constant Any_Spinner := "◰◳◲◱";
   Triangles    : constant Any_Spinner := "◢◣◤◥";

end Simple_Logging.Spinners;