with GNAT.Source_Info;

private with Ada.Finalization;

package Simple_Logging with Preelaborate is

   --  NOTE: this library is thread-unsafe. Using it with multithreaded
   --  applications will likely result in mangled output.

   --  Since the purpose is to have simultaneously "simple" yet flexible
   --  logging, this package enables the configuration of a single logger
   --  to console.
   --  That said, a number of customization options are available with the
   --  Decorators/Filtering child packages.

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

   procedure Step (This : in out Ongoing);
   --  Say that progress was made, which will advance the spinner

private

   type Ongoing_Data (Len : Natural) is record
      Level : Levels;
      Text  : String (1 .. Len);
   end record;
   --  Non-limited data to be stored in collections

   type Ongoing (Len : Natural)
   is new Ada.Finalization.Limited_Controlled with record
      Data : Ongoing_Data (Len => Len);
   end record;

   function "<" (L, R : Ongoing_Data) return Boolean is
     (L.Level < R.Level or else
      (L.Level = R.Level and then L.Text < R.Text));

   overriding
   procedure Finalize (This : in out Ongoing);

   function Build_Status_Line return String;

   procedure Clear_Status_Line;

end Simple_Logging;
