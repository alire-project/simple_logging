[![build](https://github.com/alire-project/simple_logging/workflows/Build/badge.svg)](https://github.com/alire-project/simple_logging/actions)

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

Alternatively, you can not use the package and do it like this:

```ada
with Simple_Logging;

procedure Hello_World is
   package Log renames Simple_Logging;
begin
   Log.Info ("Hello, world!");                      
   Log.Warning ("Bye!"); -- Warning level
   Log.Debug ("That took 3 mins to write"); 
   
   Simple_Logging.Level := Debug;           
   
   Log.Debug ("Checking...");
   Log.Error ("Something failed");
end Hello_World;
```
With the possible benefit that you cannot forget the logging level.
