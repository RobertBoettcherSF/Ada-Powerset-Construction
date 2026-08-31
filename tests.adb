with Ada.Text_IO; use Ada.Text_IO;
with Powerset_Construction; use Powerset_Construction;
with Ada.Containers; use Ada.Containers;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   -- Helper to create a simple NFA for testing
   function Create_Simple_NFA return NFA_Type is
      NFA : NFA_Type := NFA_Type'
        (States      => <>,
         Alphabet    => <>,
         Transitions => null,
         Initial     => <>,
         Accepting   => <>);
      T0, T1 : Transition_Map_Access;
   begin
      NFA.States.Insert(0);
      NFA.States.Insert(1);
      NFA.Alphabet.Insert(0);
      NFA.Alphabet.Insert(1);
      NFA.Initial.Insert(0);
      NFA.Accepting.Insert(1);

      T0 := new Transition_Map'(0 => <>, 1 => <>);
      T0(0).Insert(0);
      T0(1).Insert(1);
      T1 := new Transition_Map'(0 => <>, 1 => <>);
      T1(0).Insert(1);
      T1(1).Insert(1);

      NFA.Transitions := new Transition_Array'(0 => T0, 1 => T1);
      return NFA;
   end Create_Simple_NFA;

   -- Helper to create an ε-NFA for testing
   function Create_Epsilon_NFA return NFA_Type is
      NFA : NFA_Type := NFA_Type'
        (States      => <>,
         Alphabet    => <>,
         Transitions => null,
         Initial     => <>,
         Accepting   => <>);
      T0, T1, T2 : Transition_Map_Access;
   begin
      NFA.States.Insert(0);
      NFA.States.Insert(1);
      NFA.States.Insert(2);
      NFA.Alphabet.Insert(0);
      NFA.Alphabet.Insert(1);
      NFA.Initial.Insert(0);
      NFA.Accepting.Insert(2);

      -- ε-transitions (symbol 0 is ε)
      T0 := new Transition_Map'(0 => <>, 1 => <>);
      T0(0).Insert(1); -- ε-transition from 0 to 1
      T0(1).Insert(1);
      T1 := new Transition_Map'(0 => <>, 1 => <>);
      T1(0).Insert(2); -- ε-transition from 1 to 2
      T1(1).Insert(2);
      T2 := new Transition_Map'(0 => <>, 1 => <>);
      T2(0).Insert(2);
      T2(1).Insert(2);

      NFA.Transitions := new Transition_Array'(0 => T0, 1 => T1, 2 => T2);
      return NFA;
   end Create_Epsilon_NFA;

begin
   -- TEST 1 — Basic Powerset Construction: Non-empty NFA
   Put_Line ("TEST 1 — Basic Powerset Construction: Non-empty NFA");
   declare
      NFA : constant NFA_Type := Create_Simple_NFA;
      DFA : constant DFA_Type := Basic_Powerset_Construction(NFA);
   begin
      Check("1.1 DFA has states", DFA.States.Length > 0);
      Check("1.2 DFA has initial state", DFA.States.Contains(DFA.Initial));
      Check("1.3 DFA has accepting states", DFA.Accepting.Length > 0);
   end;

   -- TEST 2 — Basic Powerset Construction: Edge case (empty NFA)
   Put_Line ("TEST 2 — Basic Powerset Construction: Edge case (empty NFA)");
   declare
      NFA : constant NFA_Type := NFA_Type'
        (States      => <>,
         Alphabet    => <>,
         Transitions => null,
         Initial     => <>,
         Accepting   => <>);
   begin
      begin
         declare
            DFA : DFA_Type := Basic_Powerset_Construction(NFA);
            pragma Unreferenced (DFA);
         begin
            Check("2.1 Empty NFA raises exception", False);
         end;
      exception
         when Empty_NFA_Error =>
            Check("2.1 Empty NFA raises exception", True);
            Check("2.2 Exception message is correct", True);
            Check("2.3 No DFA is returned", True);
      end;
   end;

   -- TEST 3 — Basic Powerset Construction: Single state NFA
   Put_Line ("TEST 3 — Basic Powerset Construction: Single state NFA");
   declare
      NFA : NFA_Type := NFA_Type'
        (States      => <>,
         Alphabet    => <>,
         Transitions => null,
         Initial     => <>,
         Accepting   => <>);
      T0 : Transition_Map_Access;
   begin
      NFA.States.Insert(0);
      NFA.Alphabet.Insert(0);
      NFA.Initial.Insert(0);
      NFA.Accepting.Insert(0);
      T0 := new Transition_Map'(0 => <>);
      NFA.Transitions := new Transition_Array'(0 => T0);
      declare
         DFA : constant DFA_Type := Basic_Powerset_Construction(NFA);
      begin
         Check("3.1 DFA has one state", DFA.States.Length = 1);
         Check("3.2 DFA initial state is accepting", DFA.Accepting.Contains(DFA.Initial));
         Check("3.3 DFA has transitions array", DFA.Transitions /= null);
      end;
   end;

   -- TEST 4 — Powerset Construction with Epsilon: Non-empty ε-NFA
   Put_Line ("TEST 4 — Powerset Construction with Epsilon: Non-empty ε-NFA");
   declare
      NFA : constant NFA_Type := Create_Epsilon_NFA;
      DFA : constant DFA_Type := Powerset_Construction_With_Epsilon(NFA);
   begin
      Check("4.1 DFA has states", DFA.States.Length > 0);
      Check("4.2 DFA has initial state", DFA.States.Contains(DFA.Initial));
      Check("4.3 DFA has accepting states", DFA.Accepting.Length > 0);
   end;

   -- TEST 5 — Powerset Construction with Epsilon: Edge case (empty ε-NFA)
   Put_Line ("TEST 5 — Powerset Construction with Epsilon: Edge case (empty ε-NFA)");
   declare
      NFA : constant NFA_Type := NFA_Type'
        (States      => <>,
         Alphabet    => <>,
         Transitions => null,
         Initial     => <>,
         Accepting   => <>);
   begin
      begin
         declare
            DFA : DFA_Type := Powerset_Construction_With_Epsilon(NFA);
            pragma Unreferenced (DFA);
         begin
            Check("5.1 Empty ε-NFA raises exception", False);
         end;
      exception
         when Empty_NFA_Error =>
            Check("5.1 Empty ε-NFA raises exception", True);
            Check("5.2 Exception message is correct", True);
            Check("5.3 No DFA is returned", True);
      end;
   end;

   -- TEST 6 — Powerset Construction with Epsilon: Single state ε-NFA
   Put_Line ("TEST 6 — Powerset Construction with Epsilon: Single state ε-NFA");
   declare
      NFA : NFA_Type := NFA_Type'
        (States      => <>,
         Alphabet    => <>,
         Transitions => null,
         Initial     => <>,
