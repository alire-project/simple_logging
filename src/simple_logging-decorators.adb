with Simple_Logging.Support;

package body Simple_Logging.Decorators is

   ------------
   -- Prefix --
   ------------

   function Prefix (Level : Levels) return String is
     (case Level is
         when Always  => "",
         when Error   => "ERROR: ",
         when WARNING => "Warning: ",
         when Info    => "",
         when Detail  => "-> ",
         when Debug   => "-->> ");

   -----------------------------
   -- Default_Level_Decorator --
   -----------------------------

   function Default_Level_Decorator (Level   : Levels;
                                     Message : String)
                                     return String is
     (Prefix (Level) & Message);

   --------------------------------
   -- Default_Location_Decorator --
   --------------------------------

   function No_Location_Decorator (Entity,
                                   Location,
                                   Message : String) return String is
      pragma Unreferenced (Location, Entity);
   begin
      return Message;
   end No_Location_Decorator;

   -------------------------------
   -- Simple_Location_Decorator --
   -------------------------------

   function Simple_Location_Decorator (Entity,
                                       Location,
                                       Message : String) return String is
     ("[" & Support.Rpad ((if Entity'Length <= Entity_Width
                   then Entity
                   else Support.Elide (Entity, Entity_Width)), Entity_Width) & "]"
      & " (" & Support.Rpad ((if Location'Length <= Location_Width
                   then Location
                   else Support.Elide (Location, Location_Width)), Location_Width) & ")"
      & " " & Message);

end Simple_Logging.Decorators;
