with GNAT.Source_Info;

private with Ada.Containers.Indefinite_Holders;
private with Ada.Finalization;
private with Ada.Strings.Unbounded;
with Ada.Strings.UTF_Encoding.Wide_Wide_Strings;

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

   --  NOTE: by default, strings are considered UTF-8 and ANSI-aware. If you're
   --  using any other encoding but UTF-8, you must set Visible_Length below.

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

   ANSI_Aware : Boolean := True;
   --  Set to False if not using ANSI to omit some ANSI calls (untested impact
   --  on speed, probably negligible).

   function UTF_8_Length (S : String) return Natural;
   --  Actual length in visible cells of a string encoded with UTF-8

   Visible_Length : access function (S : String) return Natural
     := UTF_8_Length'Access;
   --  Set to a function that says how many terminal cells a string will really
   --  use. Must be set if using ANSI or non-UTF-8 encoding.

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
   --  Time between spinner frame changes. TODO: make this a property of the
   --  spinner itself.

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

   type Any_Spinner is new Wide_Wide_String;
   --  Sequence of chars to loop through for spinner animation

   -----------------
   -- Status line --
   -----------------

   procedure Set_Spinner (Spinner : Any_Spinner);
   --  Set the global spinner model to use. The default spinner will be forced
   --  if ASCII_Only is True. See the Spinners child package for predefined
   --  spinners.

   type Ongoing (<>) is tagged limited private;
   --  The status line is used to present an ongoing activity. This is done
   --  through a scoped type. Several nested statuses can be created, and the
   --  trailing '...' is added by this prompt. The rest of logging subprograms
   --  will emit normally over the status line.

   function Activity (Text              : String;
                      Autocomplete_Text : String := "";
                      Level             : Levels := Info)
                      return Ongoing;
   --  Start an ongoing activity with given Text. If Autocomplete_Text is
   --  provided, it will be used to complete the text when the activity ends.
   --  When ASCII_Only is True, this results in "Done: <Autocomplete_Text>"
   --  being printed; otherwise, a checkmark-prefixed message is printed.
   --  In both cases the status line is cleared. You can also use New_Line to
   --  print a custom message and to jump to the next line, at end or
   --  mid-progress.

   procedure Step (This     : in out Ongoing;
                   New_Text : String := "";
                   Clear    : Boolean := False)
     with Pre => not (Clear and then New_Text /= "");
   --  Say that progress was made, which will advance the spinner. Optionally,
   --  update the text to display in this activity. When Clear, remove this
   --  status contribution (e.g., because we are nesting further and this one
   --  becomes irrelevant)

   procedure New_Line (This : in out Ongoing;
                       Text : String);
   --  Remove the step text and print checkmark + Text and jump to next line.

   -------------
   -- Unicode --
   -------------

   function U (S          : Wide_Wide_String;
               Output_BOM : Boolean := False)
               return Ada.Strings.UTF_Encoding.UTF_8_String
               renames Ada.Strings.UTF_Encoding.Wide_Wide_Strings.Encode;

   function D (S : String)
               return Wide_Wide_String
               renames Ada.Strings.UTF_Encoding.Wide_Wide_Strings.Decode;

private

   use Ada.Strings.Unbounded;

   package Spinner_Holders is new
     Ada.Containers.Indefinite_Holders (Any_Spinner);

   type Ongoing_Data is record
      Start             : Duration;
      Level             : Levels;
      Text              : Unbounded_String;
   end record;
   --  Non-limited data to be stored in collections

   type Ongoing is new Ada.Finalization.Limited_Controlled with record
      Data : Ongoing_Data;

      --  Rest of state not needed to rebuild the status line
      Text_Autocomplete : Unbounded_String;
   end record;
   --  Note: Although activities can be nested, there is only a global spinner
   --  so all that state is in the body.

   function "<" (L, R : Ongoing_Data) return Boolean is
     (L.Start < R.Start or else
      (L.Start = R.Start and then L.Level < R.Level) or else
      (L.Start = R.Start and then L.Level = R.Level and then L.Text < R.Text));

   overriding
   procedure Finalize (This : in out Ongoing);

   function Build_Status_Line (This : in out Ongoing) return String;

   procedure Clear_Status_Line (Old_Status : String := "");
   --  Use the old status if provided, or the current one otherwise

end Simple_Logging;
