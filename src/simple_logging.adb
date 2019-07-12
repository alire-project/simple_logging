with GNAT.IO;

with Simple_Logging.Decorators;
with Simple_Logging.Filtering;

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
         GNAT.IO.Put_Line
           (Decorators.Location_Decorator
              (Entity,
               Location,
               Decorators.Level_Decorator
                 (Level,
                  Message)));
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

end Simple_Logging;
