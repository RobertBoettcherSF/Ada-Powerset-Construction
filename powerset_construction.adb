--  Powerset Construction Algorithm Implementation

with Ada.Containers.Doubly_Linked_Lists;
with Ada.Containers.Hashed_Maps;

package body Powerset_Construction is

   use State_Sets;

   -- Instantiate a list of State_Type for stack operations
   package State_List_Pkg is new Ada.Containers.Doubly_Linked_Lists(State_Type);
   use State_List_Pkg;

   -- Instantiate a list of State_Set for BFS queue
   package State_Set_List_Pkg is new Ada.Containers.Doubly_Linked_Lists(State_Set);

   -- Hash function for State_Set
   function Hash_State_Set (S : State_Set) return Hash_Type is
      Result : Hash_Type := 0;
   begin
      for Item of S loop
         Result := Result + State_Hash(Item);
      end loop;
      return Result;
   end Hash_State_Set;

   -- Instantiate Hashed_Maps for State_Set -> State_Type mapping
   package State_Set_Maps is new Ada.Containers.Hashed_Maps
     (Key_Type        => State_Set,
      Element_Type    => State_Type,
      Hash            => Hash_State_Set,
      Equivalent_Keys => State_Sets."=");

   -- Helper: Compute ε-closure for a single state
   function Epsilon_Closure_For_State
     (NFA : NFA_Type; State : State_Type) return State_Set
   is
      Result : State_Set;
      Stack  : State_List_Pkg.List;
      Visited : array (State_Type'Range) of Boolean := (others => False);
   begin
      Stack.Append(State);
      Visited(State) := True;

      while not Stack.Is_Empty loop
         declare
            Current : constant State_Type := Stack.First_Element;
         begin
            Stack.Delete_First;
            Result.Insert(Current);

            if NFA.Transitions /= null and then
               Current in NFA.Transitions.all'Range and then
               NFA.Transitions(Current) /= null and then
               NFA.Transitions(Current).all'Length > 0 then
               -- Assume symbol 0 is ε (for simplicity; in practice, use a dedicated ε symbol)
               for S of NFA.Transitions(Current)(0) loop
                  if not Visited(S) then
                     Visited(S) := True;
                     Stack.Append(S);
                  end if;
               end loop;
            end if;
         end;
      end loop;

      return Result;
   end Epsilon_Closure_For_State;

   -- Helper: Compute ε-closure for a set of states
   function Epsilon_Closure (NFA : NFA_Type; States : State_Set) return State_Set is
      Result : State_Set;
   begin
      for S of States loop
         Result.Union(Epsilon_Closure_For_State(NFA, S));
      end loop;
      return Result;
   end Epsilon_Closure;

   -- Helper: Compute the next state set for a given state set and symbol
   function Next_State_Set
     (NFA : NFA_Type; Current : State_Set; Symbol : Symbol_Type) return State_Set
   is
      Result : State_Set;
   begin
      for S of Current loop
         if NFA.Transitions /= null and then
            S in NFA.Transitions.all'Range and then
            NFA.Transitions(S) /= null and then
            Symbol in NFA.Transitions(S).all'Range and then
            NFA.Transitions(S)(Symbol).Length > 0 then
            Result.Union(NFA.Transitions(S)(Symbol));
         end if;
      end loop;
      return Result;
   end Next_State_Set;

   -- Basic powerset construction (no ε-moves)
   function Basic_Powerset_Construction (NFA : NFA_Type) return DFA_Type is
      -- Map from State_Set to State_Type (DFA state)
      State_To_Index : State_Set_Maps.Map;

      -- Current DFA state index
      Next_State_Index : State_Type := 0;

      -- Initialize DFA states with ε-closure of NFA initial state
      Initial_Set : State_Set := NFA.Initial;
      DFA_Initial : State_Type;

      -- Queue for BFS traversal
      Queue_Sets : State_Set_List_Pkg.List;

   begin
      if NFA.States.Length = 0 then
         raise Empty_NFA_Error with "NFA has no states";
      end if;

      -- Compute initial DFA state
      Initial_Set := Epsilon_Closure(NFA, Initial_Set);
      State_To_Index.Insert(Initial_Set, Next_State_Index);
      DFA_Initial := Next_State_Index;
      Next_State_Index := Next_State_Index + 1;
      Queue_Sets.Append(Initial_Set);

      -- Process each DFA state using BFS
      while not Queue_Sets.Is_Empty loop
         declare
            Current_Set : State_Set := Queue_Sets.First_Element;
         begin
            Queue_Sets.Delete_First;

            -- For each symbol in the alphabet
            for Sym of NFA.Alphabet loop
               declare
                  Next_Set : State_Set := Next_State_Set(NFA, Current_Set, Sym);
               begin
                  if Next_Set.Length > 0 then
                     Next_Set := Epsilon_Closure(NFA, Next_Set);
                     -- Check if this set is already a DFA state
                     if not State_To_Index.Contains(Next_Set) then
                        State_To_Index.Insert(Next_Set, Next_State_Index);
                        Queue_Sets.Append(Next_Set);
                        Next_State_Index := Next_State_Index + 1;
                     end if;
                  end if;
               end;
            end loop;
         end;
      end loop;

      -- Build DFA
      declare
         DFA : DFA_Type;
         DFA_Transitions_Array : Transition_Array_Access :=
           new Transition_Array'(0 .. Next_State_Index - 1 => null);
      begin
         -- Populate DFA.States from State_To_Index values
         for Key Of State_To_Index loop
            DFA.States.Insert(State_To_Index.Element(Key));
         end loop;

         DFA.Alphabet := NFA.Alphabet;
         DFA.Initial := DFA_Initial;
         DFA.Transitions := DFA_Transitions_Array;

         -- Build DFA transitions
         for Key Of State_To_Index loop
            declare
               Current_Set : State_Set := Key;
               Current_Index : State_Type := State_To_Index.Element(Key);
               Trans_Map : Transition_Map_Access :=
                 new Transition_Map'(0 .. Symbol_Type(NFA.Alphabet.Length - 1) => <>);
            begin
               DFA.Transitions(Current_Index) := Trans_Map;
               for Sym of NFA.Alphabet loop
                  declare
                     Next_Set : State_Set := Next_State_Set(NFA, Current_Set, Sym);
                     Next_Index : State_Type;
                  begin
                     if Next_Set.Length > 0 then
                        Next_Set := Epsilon_Closure(NFA, Next_Set);
                        if State_To_Index.Contains(Next_Set) then
                           Next_Index := State_To_Index.Element(Next_Set);
                           DFA.Transitions(Current_Index)(Sym).Insert(Next_Index);
                        end if;
                     end if;
                  end;
               end loop;
            end;
         end loop;

         -- Build DFA accepting states
         for Key Of State_To_Index loop
            for A of NFA.Accepting loop
               if Key.Contains(A) then
                  DFA.Accepting.Insert(State_To_Index.Element(Key));
                  exit;
               end if;
            end loop;
         end loop;

         return DFA;
      end;
   end Basic_Powerset_Construction;

   -- Powerset construction with ε-closure (for ε-NFA)
   function Powerset_Construction_With_Epsilon (NFA : NFA_Type) return DFA_Type is
   begin
      -- For ε-NFA, the basic powerset construction already handles ε-closure
      return Basic_Powerset_Construction(NFA);
   end Powerset_Construction_With_Epsilon;

end Powerset_Construction;
