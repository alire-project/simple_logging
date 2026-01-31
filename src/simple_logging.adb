with Ada.Containers.Indefinite_Ordered_Multisets;

with GNAT.IO;

with Simple_Logging.C;
with Simple_Logging.Decorators;
with Simple_Logging.Filtering;
with Simple_Logging.Spinners;
with Simple_Logging.Support;

pragma Warnings (Off);
--  This is compiler-internal unit. We only use the Clock, which is highly
--  unlikely to change its specification.
with System.OS_Primitives;
pragma Warnings (On);

package body Simple_Logging is

   ---------
   -- Log --
   ---------

   procedure Log (Message  : String;
                  Level    : Levels := Info;
                  Entity   : String := Gnat.Source_Info.Enclosing_Entity;
                  Location : String := Gnat.Source_Info.Source_Location) is
   begin
      if Level <= Simple_Logging.Level and then
        Filtering.Accept_Message (Message, Level, Entity, Location)
      then
         Clear_Status_Line;

         declare
            Line : constant String :=
                     Decorators.Location_Decorator
                       (Entity,
                        Location,
                        Decorators.Level_Decorator
                          (Level,
                           Message));
         begin
            if Level < Stdout_Level and then
              (Level /= Always or else Treat_Always_As_Error)
            then
               GNAT.IO.Put_Line (GNAT.IO.Standard_Error, Line);
            else
               GNAT.IO.Put_Line (GNAT.IO.Standard_Output, Line);
            end if;
         end;
      end if;
   end Log;

   ------------
   -- Always --
   ------------

   procedure Always  (Msg      : String;
                      Entity   : String := Gnat.Source_Info.Enclosing_Entity;
                      Location : String := Gnat.Source_Info.Source_Location) is
   begin
      Log (Msg, Always, Entity, Location);
   end Always;

   -----------
   -- Error --
   -----------

   procedure Error   (Msg      : String;
                      Entity   : String := Gnat.Source_Info.Enclosing_Entity;
                      Location : String := Gnat.Source_Info.Source_Location) is
   begin
      Log (Msg, Error, Entity, Location);
   end Error;

   -------------
   -- Warning --
   -------------

   procedure Warning (Msg : String;
                      Entity   : String := Gnat.Source_Info.Enclosing_Entity;
                      Location : String := Gnat.Source_Info.Source_Location) is
   begin
      Log (Msg, Warning, Entity, Location);
   end Warning;

   ----------
   -- Info --
   ----------

   procedure Info    (Msg      : String;
                      Entity   : String := Gnat.Source_Info.Enclosing_Entity;
                      Location : String := Gnat.Source_Info.Source_Location) is
   begin
      Log (Msg, Info, Entity, Location);
   end Info;

   ------------
   -- Detail --
   ------------

   procedure Detail  (Msg      : String;
                      Entity   : String := Gnat.Source_Info.Enclosing_Entity;
                      Location : String := Gnat.Source_Info.Source_Location) is
   begin
      Log (Msg, Detail, Entity, Location);
   end Detail;

   -----------
   -- Debug --
   -----------

   procedure Debug   (Msg      : String;
                      Entity   : String := Gnat.Source_Info.Enclosing_Entity;
                      Location : String := Gnat.Source_Info.Source_Location) is
   begin
      Log (Msg, Debug, Entity, Location);
   end Debug;

   -----------------
   -- STATUS LINE --
   -----------------

   package Status_Sets is new Ada.Containers.Indefinite_Ordered_Multisets
     (Ongoing_Data);

   function Internal_Clock return Duration renames System.OS_Primitives.Clock;
   --  We need a preelaborable source of time with sub-second granularity,
   --  which discards GNAT.OS_Lib date functions.

   Statuses  : Status_Sets.Set;

   Last_Status_Line : Unbounded_String; -- Used for cleanup
   Last_Spin        : Duration := 0.0;

   --------------
   -- Activity --
   --------------

   function Activity (Text              : String;
                      Autocomplete_Text : String := "";
                      Spinner           : Any_Spinner := Default_Spinner;
                      Level             : Levels := Info)
                      return Ongoing
   is
   begin
      return This : Ongoing :=
        (Ada.Finalization.Limited_Controlled with
            Data => (Level => Level,
                     Start => Internal_Clock,
                     Text  => To_Unbounded_String (Text)),
            Text_Autocomplete =>
                     To_Unbounded_String (Autocomplete_Text),
            Spinner => Spinner_Holders.To_Holder
              (if Spinner = Default_Spinner
               then (if ASCII_Only then Spinners.Classic else Spinners.Braille_8)
               else Spinner),
            Spinner_Pos => <>)
      do
         Debug ("Status start: " & To_String (This.Data.Text));
         Statuses.Insert (This.Data);
         This.Step;
      end return;
   end Activity;

   -----------------------
   -- Build_Status_Line --
   -----------------------

   function Build_Status_Line (This : in out Ongoing) return String is
      Line : Unbounded_String;
      Pred : Unbounded_String;
      --  Status of the precedent scope, to eliminate duplicates
   begin
      if Internal_Clock - Last_Spin > Spinner_Period then
         This.Spinner_Pos := This.Spinner_Pos + 1;
         Last_Spin := Internal_Clock;

         if This.Spinner_Pos not in This.Spinner.Reference.Element'Range then
            This.Spinner_Pos := This.Spinner.Reference.Element'First;
         end if;
      end if;

      for Status of Statuses loop
         if Status.Level <= Simple_Logging.Level
           and then Pred /= Status.Text
           and then Status.Text /= ""
         then
            Pred := Status.Text;
            Append (Line, Status.Text & "... ");
         end if;
      end loop;

      if Length (Line) > 0 then
         Line :=
           U ("" & This.Spinner.Reference.Element (This.Spinner_Pos))
           & " " & Line;
      end if;

      return To_String (Line);
   end Build_Status_Line;

   -----------------------
   -- Clear_Status_Line --
   -----------------------

   procedure Clear_Status_Line (Old_Status : String := "") is
      Line : constant String :=
               (if Old_Status /= ""
                then Old_Status
                else To_String (Last_Status_Line));
   begin
      if Is_TTY and then Visible_Length (Line) > 0 then
         GNAT.IO.Put
           (ASCII.CR & (1 .. Visible_Length (Line) => ' ') & ASCII.CR);
      end if;
   end Clear_Status_Line;

   --------------
   -- Finalize --
   --------------

   overriding
   procedure Finalize (This : in out Ongoing) is
   begin
      Debug ("Status ended: " & To_String (This.Data.Text));
      if this.Text_Autocomplete /= "" then
         this.New_Line (To_String (This.Text_Autocomplete));
      else
         Clear_Status_Line;
         Statuses.Difference (Status_Sets.To_Set (This.Data));
         This.Step;
      end if;
   end Finalize;

   --------------
   -- New_Line --
   --------------

   procedure New_Line (This : in out Ongoing;
                       Text : String)
   is
      Old_Line : constant String := This.Build_Status_Line;
   begin
      --  Remove current status (unsure if this is needed)
      Statuses.Exclude (This.Data);

      --  Print checkmark + Text and clear remainder of line
      declare
         Done_Line : constant String  :=
            (if ASCII_Only
             then "Done: " & Text
             else U ("✔ ") & Text);
         New_Len  : constant Natural := Visible_Length (Done_Line);
         Old_Len  : constant Natural := Visible_Length (Old_Line);
      begin
         if Is_TTY and then New_Len > 0 then
            GNAT.IO.Put_Line
              (ASCII.CR
               & Done_Line
               & (1 .. Old_Len - Natural'Min (New_Len, Old_Len) => ' '));
         else
            Clear_Status_Line (Old_Line);
            GNAT.IO.Put_Line ("");
         end if;
         C.Flush_Stdout;
      end;
   end New_Line;

   ----------
   -- Step --
   ----------

   procedure Step (This     : in out Ongoing;
                   New_Text : String := "";
                   Clear    : Boolean := False) is
      Old_Line : constant String := This.Build_Status_Line;
   begin
      --  Update status if needed
      if New_Text /= "" or else Clear then
         Statuses.Exclude (This.Data);
         This.Data.Text := To_Unbounded_String (New_Text);
         Statuses.Insert (This.Data);
      end if;

      declare
         New_Line : constant String  := This.Build_Status_Line;
         New_Len  : constant Natural := Visible_Length (New_Line);
         Old_Len  : constant Natural := Visible_Length (Old_Line);
      begin
         --  Store for future reference
         Last_Status_Line := To_Unbounded_String (New_Line);

         if Is_TTY and then New_Len > 0 then
            GNAT.IO.Put (ASCII.CR
                         & New_Line
                         & (1 .. Old_Len - Natural'Min (New_Len, Old_Len) => ' '));
            C.Flush_Stdout;
         else
            Clear_Status_Line (Old_Line);
         end if;
      end;
   end Step;

   ------------------
   -- UTF_8_Length --
   ------------------

   function UTF_8_Length (S : String) return Natural
   is (if ANSI_Aware
       then D (Support.ANSI_Scrub (S))'Length
       else D (S)'Length);

end Simple_Logging;
