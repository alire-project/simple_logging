--  Proper use of UTF-8 requires non-preelaborable packages (due to Text_IO).
--  Hence this must be enabled separately here.

package Simple_Logging.UTF_8 is

   procedure Enable;
   --  After this call, strings using UTF-8 encoding will be properly printed.
   --  Before that, only Latin1 will be properly displayed.

end Simple_Logging.UTF_8;
