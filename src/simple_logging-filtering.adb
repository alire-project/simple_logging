package body Simple_Logging.Filtering is

   --------------------
   -- Default_Filter --
   --------------------

   function Default_Filter (Message  : String;
                            Level    : Levels;
                            Entity   : String;
                            Location : String) return Boolean is
     (True);

   procedure Add_Substring (Str : String) is null;

   procedure Add_Exception (Str : String) is null;

end Simple_Logging.Filtering;
