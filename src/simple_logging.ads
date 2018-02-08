package Simple_Logging with Preelaborate is

   type Levels is (Always,
                   Error,
                   Warning,
                   Info,
                   Detail,
                   Debug);
   --  From most important to less important

   Level : Levels := Info;
   --  Any message at the same level or below will be output to console

   procedure Log (S : String; Level : Levels := Info);
   --  Report a log message

   --  Log by level.
   --  Useful if you want to use a package renaming as prefix, e.g.: Log.Info ("Blah");

   procedure Always  (Msg : String);
   procedure Error   (Msg : String);
   procedure Warning (Msg : String);
   procedure Info    (Msg : String);
   procedure Detail  (Msg : String);
   procedure Debug   (Msg : String);

end Simple_Logging;
