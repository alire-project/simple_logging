with Ada.Containers.Indefinite_Ordered_Multisets;

with GNAT.IO;

with Simple_Logging.C;
with Simple_Logging.Decorators;
with Simple_Logging.Filtering;

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

   subtype Indicator_Range is Positive range 1 .. 4;
   Indicator_Nice : constant array (Indicator_Range) of Wide_Wide_Character :=
                      ('◴',
                       '◷',
                       '◶',
                       '◵');
   Indicator_Basic : constant array (Indicator_Range) of String (1 .. 1) :=
                       ("/",
                        "-",
                        "\",
                        "|");

   Ind_Pos         : Positive := 1;
   Last_Step       : Duration := 0.0;

   function Indicator return String is
     (if Is_TTY and then not ASCII_Only
      then U ("" & Indicator_Nice (Ind_Pos))
      else Indicator_Basic (Ind_Pos));

   --------------
   -- Activity --
   --------------

   function Activity (Text  : String;
                      Level : Levels := Info) return Ongoing is
   begin
      return This : Ongoing := (Ada.Finalization.Limited_Controlled with
                                Data => (Level => Level,
                                         Start => Internal_Clock,
                                         Text  => To_Unbounded_String (Text)))
      do
         Debug ("Status start: " & To_String (This.Data.Text));
         Statuses.Insert (This.Data);
         This.Step;
      end return;
   end Activity;

   -----------------------
   -- Build_Status_Line --
   -----------------------

   function Build_Status_Line return String is
      Line : Unbounded_String;
      Pred : Unbounded_String;
      --  Status of the precedent scope, to eliminate duplicates
   begin
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
         Line := Indicator & " " & Line;
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
                else Build_Status_Line);
   begin
      if Is_TTY and then Line'Length > 0 then
         GNAT.IO.Put
           (ASCII.CR & (1 .. Line'Length => ' ') & ASCII.CR);
      end if;
   end Clear_Status_Line;

   --------------
   -- Finalize --
   --------------

   overriding
   procedure Finalize (This : in out Ongoing) is
   begin
      Debug ("Status ended: " & To_String (This.Data.Text));
      Clear_Status_Line;
      Statuses.Difference (Status_Sets.To_Set (This.Data));
      This.Step;
   end Finalize;

   ----------
   -- Step --
   ----------

   procedure Step (This     : in out Ongoing;
                   New_Text : String := "";
                   Clear    : Boolean := False) is
      Old_Line : constant String := Build_Status_Line;
   begin
      --  Update status if needed
      if New_Text /= "" or else Clear then
         Statuses.Delete (This.Data);
         This.Data.Text := To_Unbounded_String (New_Text);
         Statuses.Insert (This.Data);
      end if;

      declare
         New_Line : constant String := Build_Status_Line;
      begin
         if Is_TTY and then New_Line'Length > 0 then
            GNAT.IO.Put (ASCII.CR
                         & New_Line
                         & (1 .. Old_Line'Length - New_Line'Length => ' '));
            C.Flush_Stdout;

            --  Advance the spinner

            if Last_Step = 0.0 or else
               Internal_Clock - Last_Step >= Spinner_Period
            then
               Last_Step := Internal_Clock;
               Ind_Pos   := Ind_Pos + 1;
               if Ind_Pos > Indicator_Range'Last then
                  Ind_Pos := Indicator_Range'First;
               end if;
            end if;
         else
            Clear_Status_Line (Old_Line);
         end if;
      end;
   end Step;

end Simple_Logging;
