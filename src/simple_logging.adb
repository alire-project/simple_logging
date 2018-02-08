with GNAT.IO;

package body Simple_Logging is

   function Prefix (Level : Levels) return String is
     (case Level is
         when Always  => "",
         when Error   => "ERROR: ",
         when WARNING => "Warning: ",
         when Info    => "",
         when Detail  => "-> ",
         when Debug   => "-->> ");

   ---------
   -- Log --
   ---------

   procedure Log (S : String; Level : Levels := Info) is
   begin
      if Level <= Simple_Logging.Level then
         GNAT.IO.Put_Line (Prefix (Level) & S);
      end if;
   end Log;

   ------------
   -- Always --
   ------------

   procedure Always  (Msg : String) is
   begin
      Log (Msg, Always);
   end Always;

   -----------
   -- Error --
   -----------

   procedure Error   (Msg : String) is
   begin
      Log (Msg, Error);
   end Error;

   -------------
   -- Warning --
   -------------

   procedure Warning (Msg : String) is
   begin
      Log (Msg, Warning);
   end Warning;

   ----------
   -- Info --
   ----------

   procedure Info    (Msg : String) is
   begin
      Log (Msg, Info);
   end Info;

   ------------
   -- Detail --
   ------------

   procedure Detail  (Msg : String) is
   begin
      Log (Msg, Detail);
   end Detail;

   -----------
   -- Debug --
   -----------

   procedure Debug   (Msg : String) is
   begin
      Log (Msg, Debug);
   end Debug;

end Simple_Logging;
