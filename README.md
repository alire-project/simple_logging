# simple_logging

Easy-to-use logging facilities for output to console in Ada programs.
Preelaborable package.

For example:

```ada
with Simple_Logging; use Simple_Logging;

procedure Hello_World is
begin
   Log ("Hello, world!");                      -- Info level (default)
   Log ("Bye!",                      Warning); -- Warning level
   Log ("That took 3 mins to write", Debug);   -- Won't show with default log level.
   
   Simple_Logging.Level := Debug;              -- Lower the threshold for output
   
   Log ("Checking...",      Debug);            -- Now it will show.
   Log ("Something failed", Error);            -- Error!
end Hello_World;

```

The corresponding output will be:

```
Hello, world!
Warning: Bye!
-->> Checking...
ERROR: Something failed
```
