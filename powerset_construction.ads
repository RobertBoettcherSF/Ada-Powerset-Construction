--  Powerset Construction Algorithm Specification
--  Converts an NFA (including ε-NFA) to an equivalent DFA.

with Ada.Containers.Vectors;
with Ada.Containers.Hashed_Sets;
with Ada.Containers.Doubly_Linked_Lists;

package Powerset_Construction is
   pragma Pure;

   -- Custom types for the algorithm domain
   type State_Type is range 0 .. Integer'Last;
   type Symbol_Type is range 0 .. Integer'Last;

   -- For sets of states (DFA states are sets of NFA states)
   function State_Hash (S : State_Type) return Ada.Containers.Hash_Type;
   package State_Sets is new Ada.Containers.Hashed_Sets
     (Element_Type        => State_Type,
      Hash                => State_Hash,
      Equivalent_Elements => "=");
   subtype State_Set is State_Sets.Set;

   -- For sets of symbols (alphabet)
   function Symbol_Hash (S : Symbol_Type) return Ada.Containers.Hash_Type;
   package Symbol_Sets is new Ada.Containers.Hashed_Sets
     (Element_Type        => Symbol_Type,
      Hash                => Symbol_Hash,
      Equivalent_Elements => "=");
   subtype Symbol_Set is Symbol_Sets.Set;

   -- Transition type: from (state, symbol) to set of states
   type Transition_Maps is array (Symbol_Type range <>) of State_Set;
   type Transition_Map_Access is access Transition_Maps;

   -- NFA and DFA types
   type NFA_Type is record
      States      : State_Set;
      Alphabet    : Symbol_Set;
      Transitions : array (State_Type range <>) of Transition_Map_Access;
      Initial     : State_Set;
      Accepting   : State_Set;
   end record;

   type DFA_Type is record
      States      : State_Set;
      Alphabet    : Symbol_Set;
      Transitions : array (State_Type range <>) of Transition_Map_Access;
      Initial     : State_Type;
      Accepting   : State_Set;
   end record;

   -- Exceptions
   Empty_NFA_Error : exception;
   Invalid_Transition_Error : exception;

   -- Basic powerset construction (no ε-moves)
   function Basic_Powerset_Construction (NFA : NFA_Type) return DFA_Type
     with Pre => NFA.States.Length > 0,
          Post => Basic_Powerset_Construction'Result.States.Length > 0;

   -- Powerset construction with ε-closure (for ε-NFA)
   function Powerset_Construction_With_Epsilon (NFA : NFA_Type) return DFA_Type
     with Pre => NFA.States.Length > 0,
          Post => Powerset_Construction_With_Epsilon'Result.States.Length > 0;

   -- Helper: Compute ε-closure for a set of states
   function Epsilon_Closure (NFA : NFA_Type; States : State_Set) return State_Set;

private
   -- Hash functions for State_Type and Symbol_Type
   function State_Hash (S : State_Type) return Ada.Containers.Hash_Type is
     (Ada.Containers.Hash_Type(S));

   function Symbol_Hash (S : Symbol_Type) return Ada.Containers.Hash_Type is
     (Ada.Containers.Hash_Type(S));

end Powerset_Construction;
