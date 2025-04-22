with GNAT.Source_Info;

private with Ada.Finalization;
private with Ada.Strings.Unbounded;
private with Ada.Strings.UTF_Encoding.Wide_Wide_Strings;

package Simple_Logging with Preelaborate is

   --  NOTE: this library is thread-unsafe. Using it with multithreaded
   --  applications will likely result in mangled output.

   --  Since the purpose is to have simultaneously "simple" yet flexible
   --  logging, this package enables the configuration of a single logger
   --  to console.
   --  That said, a number of customization options are available with the
   --  Decorators/Filtering child packages.

   --  Strings should be encoded in the expected terminal encoding, which in
   --  this day and age should be UTF-8 for both Linux and Windows. This is
   --  likely to change in the future to require Unicode encoding so text
   --  lenghts can be computed properly.

   type Levels is (Always,
                   Error,
                   Warning,
                   Info,
                   Detail,
                   Debug);
   --  From most important to less important
   --  Or, from less verbose to more verbose

   Level : Levels := Info;
   --  Any message at the same level or below will be output to console

   Is_TTY : Boolean := False;
   --  Set this to True when you know log is not being redirected. This flag
   --  suppresses the use of busy statuses (see below) which, by relying
   --  on ASCII.CR, will greatly pollute logfiles.

   ASCII_Only : Boolean := True;
   --  Restrict the deliberate use of non-ASCII chars (currently only for the
   --  busy status spinner).

   Stdout_Level : Levels := Always;
   --  Any level < Stdout_Level will be output to stderr, except for Always
   --  (see below).

   Treat_Always_As_Error : Boolean := False;
   --  When True, Stdout_Level also applies to the Always level

   Spinner_Period : Duration := 0.1;
   --  Time between spinner frame changes

   procedure Log (Message  : String;
                  Level    : Levels := Info;
                  Entity   : String := Gnat.Source_Info.Enclosing_Entity;
                  Location : String := Gnat.Source_Info.Source_Location);
   --  Report a log message

   --  Log by level.
   --  Useful if you want to use a package renaming as prefix,
   --  e.g. : Log.Info ("Blah");

   procedure Always  (Msg      : String;
                      Entity   : String := Gnat.Source_Info.Enclosing_Entity;
                      Location : String := Gnat.Source_Info.Source_Location);
   procedure Error   (Msg      : String;
                      Entity   : String := Gnat.Source_Info.Enclosing_Entity;
                      Location : String := Gnat.Source_Info.Source_Location);
   procedure Warning (Msg      : String;
                      Entity   : String := Gnat.Source_Info.Enclosing_Entity;
                      Location : String := Gnat.Source_Info.Source_Location);
   procedure Info    (Msg      : String;
                      Entity   : String := Gnat.Source_Info.Enclosing_Entity;
                      Location : String := Gnat.Source_Info.Source_Location);
   procedure Detail  (Msg      : String;
                      Entity   : String := Gnat.Source_Info.Enclosing_Entity;
                      Location : String := Gnat.Source_Info.Source_Location);
   procedure Debug   (Msg      : String;
                      Entity   : String := Gnat.Source_Info.Enclosing_Entity;
                      Location : String := Gnat.Source_Info.Source_Location);
   procedure Never   (Msg      : String;
                      Entity   : String := Gnat.Source_Info.Enclosing_Entity;
                      Location : String := Gnat.Source_Info.Source_Location)
   is null; -- Quietly drop

   -----------------
   -- Status line --
   -----------------

   type Ongoing (<>) is tagged limited private;
   --  The status line is used to present an ongoing activity. This is done
   --  through a scoped type. Several nested statuses can be created, and the
   --  trailing '...' is added by this prompt. The rest of logging subprograms
   --  will emit normally over the status line.

   function Activity (Text : String;
                      Level : Levels := Info) return Ongoing;

   procedure Step (This     : in out Ongoing;
                   New_Text : String := "";
                   Clear    : Boolean := False)
     with Pre => not (Clear and then New_Text /= "");
   --  Say that progress was made, which will advance the spinner. Optionally,
   --  update the text to display in this activity. When Clear, remove this
   --  status contribution (e.g., because we are nesting further and this one
   --  becomes irrelevant)

private

   function U (S          : Wide_Wide_String;
               Output_BOM : Boolean := False)
               return Ada.Strings.UTF_Encoding.UTF_8_String
               renames Ada.Strings.UTF_Encoding.Wide_Wide_Strings.Encode;

   use Ada.Strings.Unbounded;

   type Ongoing_Data is record
      Start : Duration;
      Level : Levels;
      Text  : Unbounded_String;
   end record;
   --  Non-limited data to be stored in collections

   type Ongoing is new Ada.Finalization.Limited_Controlled with record
      Data : Ongoing_Data;
   end record;

   function "<" (L, R : Ongoing_Data) return Boolean is
     (L.Start < R.Start or else
      (L.Start = R.Start and then L.Level < R.Level) or else
      (L.Start = R.Start and then L.Level = R.Level and then L.Text < R.Text));

   overriding
   procedure Finalize (This : in out Ongoing);

   function Build_Status_Line return String;

   procedure Clear_Status_Line (Old_Status : String := "");
   --  Use the old status if provided, or the current one otherwise

end Simple_Logging;
