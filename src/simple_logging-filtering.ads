package Simple_Logging.Filtering with Preelaborate is

   --  Filtering enables to accept/filter out messages that will get displayed.
   --  By default, no filtering occurs.
   --  See below how to configure the default filter.

   function Default_Filter (Message  : String;
                            Level    : Levels;
                            Entity   : String;
                            Location : String) return Boolean;
   --  The default filter accepts everything, unless configured with the calls
   --  below.
   --  The implementation doesn't strive to be super-efficient; it only
   --  guarantees logarithmic degradation on look-up times.

   -------------------
   -- Configuration --
   -------------------

   --  The following function can be changed to an entirely new filter.
   --  Otherwise, see below for configuration options for the default filter.

   Accept_Message : access function (Message  : String;
                                     Level    : Levels;
                                     Entity   : String;
                                     Location : String) return Boolean :=
     Default_Filter'Access;

   type Filtering_Modes is (Blacklist, Whitelist);
   --  In blacklist mode, by default all passes but explicitly blacklisted.
   --  In whitelist mode, nothing passes but whitelisted.
   --  En each mode, you can further add exceptions to the list that operate
   --  in the contrary mode.

   Mode : Filtering_Modes := Blacklist;
   --  MOde for the Default_Filter

   procedure Add_Substring (Str : String);
   --  Something that will be blacklisted/whitelisted.
   --  It case-insensitively checks the Location and the Entity of the message.

   procedure Add_Exception (Str : String);
   --  Add an exception to the regular mode. For example, in Blacklist mode:
   --  Add_Substring ("foo"); -- blacklists messages containing "foo"
   --  Add_Exception ("bar"); -- unless they contain "bar" too.
   --  In whitelist mode, something similar but in reverse will happen.

   function Add_From_String (Str : String;
                             Say : Boolean := False) return Boolean;
   --  Process an entire string (e.g. coming from a command-line argument) to
   --  configure filtering. String syntax is: (+|-)[scope][[,](+|-)scope]...
   --  Will return False if syntax is wrong. Lists will be emptied in that case.
   --  If Say = True, the mode/scopes will be written to stdout for reference.
   --  Examples:
   --    + (empty whitelist, nothing will pass)
   --    +foo,-bar (whitelist foo, except bar)
   --    - (empty blacklist, nothing will be blocked)
   --    -foo,+bar (blacklist foo, except bar)
   --    -foo+bar (commas are optional)
   --  The very first sign sets the mode to whitelist (+) or blacklist (-).

end Simple_Logging.Filtering;
