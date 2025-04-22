package Simple_Logging.C with Preelaborate is

   procedure Flush_Stdout with
      Import,
      Convention => C,
      External_Name => "sl_flush_stdout";

end Simple_Logging.C;