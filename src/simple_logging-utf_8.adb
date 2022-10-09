with Ada.Wide_Wide_Text_IO;

package body Simple_Logging.UTF_8 is

   ------------
   -- Enable --
   ------------

   procedure Enable is
   begin
      Simple_Logging.Put      := Ada.Wide_Wide_Text_Io.Put'Access;
      Simple_Logging.Put_Line := Ada.Wide_Wide_Text_Io.Put_Line'Access;
   end Enable;

end Simple_Logging.UTF_8;
