package Simple_Logging.Decorators with Preelaborate is

   --------------
   -- Defaults --
   --------------
   --  These functions are used by default for log decoration.
   --  They take the log message and modify it somehow.

   function Default_Level_Decorator (Level   : Levels;
                                     Message : String)
                                     return String;
   --  Prefixes the log message with ERROR/Warning/(nothing)/->/-->>.

   function No_Location_Decorator (Entity,
                                   Location,
                                   Message : String) return String;
   --  Does not use the location/entity information, Message is kept as-is.

   Location_Width : Positive range 2 .. Positive'Last := 24;
   Entity_Width   : Positive range 2 .. Positive'Last := 24;

   function Simple_Location_Decorator (Entity,
                                       Location,
                                       Message : String) return String;
   --  Prefixes the log message with fixed-with entity/location.
   --  Uses the previous two declared variables for the width.

   -------------------
   -- Configuration --
   -------------------
   --  These are the functions that the user can set to other preferred values.

   --  The output message is:
   --  Location_Decorator (Level_Decorator (Message))

   Level_Decorator : access function (Level : Levels;
                                      Message : String) return String :=
     Default_Level_Decorator'Access;
   --  Use simple text prefixes for normal levels, markers for verbose levels.

   Location_Decorator : access function (Entity,
                                         Location,
                                         Message : String) return String :=
     No_Location_Decorator'Access;
   --  No entity/location information by default.
   --  See Simple_Location_Decorator above for a "[entity] (location) Msg" option.

end Simple_Logging.Decorators;
