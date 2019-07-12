with Ada.Characters.Handling;
with Ada.Containers.Indefinite_Ordered_Sets;
with Ada.Exceptions;
with Ada.Strings.Fixed;

with GNAT.IO;

with Simple_Logging.Decorators;

package body Simple_Logging.Filtering is

   package String_Sets is new Ada.Containers.Indefinite_Ordered_Sets (String);

   Substrings : String_Sets.Set;

   Exceptions : String_Sets.Set;

   --------------
   -- Contains --
   --------------

   function Contains (Text, Substring : String) return Boolean is
     (Ada.Strings.Fixed.Index
        (Ada.Characters.Handling.To_Lower (Text), Substring) > 0);
   --  patterns are lowercased on agregation.


   --------------------
   -- Default_Filter --
   --------------------

   function Default_Filter (Message  : String;
                            Level    : Levels;
                            Entity   : String;
                            Location : String) return Boolean
   is
      pragma Unreferenced (Message, Level);
      Found  : Boolean := False;
      Except : Boolean := False;
   begin
      for Str of Substrings loop
         if Contains (Entity, Str) or else Contains (Location, Str) then
            Found := True;
            exit;
         end if;
      end loop;

      if Found then
         for Str of Exceptions loop
            if Contains (Entity, Str) or else Contains (Location, Str) then
               Except := True;
               exit;
            end if;
         end loop;
      end if;

      return
        (Mode = Blacklist and then (not Found or else Except)) or else
        (Mode = Whitelist and then (Found and then not Except));
   end Default_Filter;

   -------------------
   -- Add_Substring --
   -------------------

   procedure Add_Substring (Str : String) is
   begin
      Substrings.Include (Ada.Characters.Handling.To_Lower (Str));
   end Add_Substring;

   -------------------
   -- Add_Exception --
   -------------------

   procedure Add_Exception (Str : String) is
   begin
      Exceptions.Include (Ada.Characters.Handling.To_Lower (Str));
   end Add_Exception;

   ---------------------
   -- Add_From_String --
   ---------------------

   function Add_From_String (Str : String;
                             Say : Boolean := False) return Boolean is

      Bad_Syntax : exception;

      ----------------
      -- Add_Scopes --
      ----------------

      procedure Add_Scopes (Debug_Arg : String) is
         --  Receives as-is the --debug/-d[ARG] argument. This is a list of
         --  optionally comma-separated, plus/minus prefixed substrings that will
         --  be used for filtering against the enclosing entity/source location.
         --  Example whitelisting argument: +commands,-search
         --  Example blacklisting argument: -commands,+search
         --  The first sign puts the filter in (-) blacklist / (+) whitelist mode.
         --  In whitelist mode, only the given substrings are logged, unless later
         --  added as exception. E.g., in the "+commands,-search" example, only
         --  commands traces would be logged (because of whitelist mode), except
         --  the ones for the search command (because given as an exception).
         --  In the "-commands,+search" example for blacklist mode, everything but
         --  command traces would be logged, but search command traces would be
         --  logged because that's the exception.

         --  Once scopes are used, we activate logging of enclosing entity and
         --  location to provide full logging information.

         Pos : Integer := Debug_Arg'First;
         --  Points to the beginning of the next scope in Debug_Arg

         --------------------
         -- Next_With_Sign --
         --------------------

         function Next_With_Sign return String is
            --  Look from Debug_Arg (Pos) onwards to find a comma, sign, or end.
            --  Returns "" when no more scopes. Otherwise, returns a single scope
            --  with its sign (e.g., "+commands")
            Old_Pos : constant Integer := Pos;
         begin
            if Pos >= Debug_Arg'Last then
               return "";
            end if;

            for I in Pos + 1 .. Debug_Arg'Last loop
               if Debug_Arg (I) in ',' | '+' | '-' then
                  if Pos = I - 1 then -- Means consecutive separators, i.e. no-no
                     raise Bad_Syntax with "Invalid logging scope separator: " & Debug_Arg;
                  end if;

                  Pos := I;
                  if Debug_Arg (Pos) = ',' then
                     Pos := Pos + 1;
                  end if;
                  return Debug_Arg (Old_Pos .. I - 1);
               end if;
            end loop;

            --  We reached the end:
            Pos := Debug_Arg'Last + 1;
            return Debug_Arg (Old_Pos .. Debug_Arg'Last);
         end Next_With_Sign;

      begin
         if Str = "" then
            return;
         end if;

         --  Activate scope logging:
         Decorators.Location_Decorator :=
           Decorators.Simple_Location_Decorator'Access;

         case Debug_Arg (Str'First) is
            when '+' =>
               Simple_Logging.Filtering.Mode := Whitelist;
            when '-' =>
               Simple_Logging.Filtering.Mode := Blacklist;
            when others =>
               raise Bad_Syntax
                 with "Debug filters must be prefixed with + or -.";
         end case;

         --  Output how we are going to filter:
         if Say then
            GNAT.IO.Put_Line ("Filtering mode: "
                              & Simple_Logging.Filtering.Mode'Img);
         end if;

         --  Process scopes according to mode and sign
         loop
            declare
               Scope_With_Sign : constant String := Next_With_Sign;
            begin
               --  Nothing more to process
               if Scope_With_Sign = "" then
                  return;
               end if;

               --  Add a single scope
               declare
                  Sign  : constant Character :=
                            Scope_With_Sign (Scope_With_Sign'First);
                  Scope : constant String :=
                            Scope_With_Sign (Scope_With_Sign'First + 1 ..
                                                       Scope_With_Sign'Last);
               begin
                  if Sign not in '-' | '+' then
                     raise Bad_Syntax with
                       "ERROR: Missing +/- before filter: " & Scope_With_Sign;
                  end if;

                  if (Filtering.Mode = Filtering.Blacklist and then Sign = '-') or
                    (Filtering.Mode = Filtering.Whitelist and then Sign = '+')
                  then
                     if Say then
                        GNAT.IO.Put_Line ("Filtering substring: " & Scope);
                     end if;
                     Filtering.Add_Substring (Scope);
                  else
                     if Say then
                        GNAT.IO.Put_Line ("Filtering exception: " & Scope);
                     end if;
                     Filtering.Add_Exception (Scope);
                  end if;
               end;
            end;
         end loop;
      end Add_Scopes;

   begin
      Add_Scopes (Str);
      return True;
   exception
      when E : Bad_Syntax =>
         Mode := Blacklist;
         Substrings.Clear;
         Exceptions.Clear;
         if Say then
            GNAT.IO.Put_Line (Ada.Exceptions.Exception_Message (E));
         end if;
         return False;
   end Add_From_String;

end Simple_Logging.Filtering;
