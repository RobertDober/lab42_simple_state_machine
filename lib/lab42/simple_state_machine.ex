defmodule Lab42.SimpleStateMachine do
  
  @moduledoc """
  ## A simple state machine.

  `SimpleStateMachine` is a minimalistic approach to write _State Machines_ which operate on a list of inputs.

  The machine is defined by a map, mapping, transitions to each state, called `transition_map`.

          %{ start: [ transition, ... ],
              some_state: [transition, ...] }


  ### Format of a Transition
  
  `{trigger, transition_fn, new_state}` or, if the state is not supposed to change, `{trigger, transition_fn}`

  For each input in the list of inputs the machine will try to match the input with the `trigger` from the transition. 

  If such a match is found the `transition_fn` is called with a `%SimpleStateMachine.Match` struct which will give access
  to the following fields:

          %SimpleStateMachine.Match{
             input: "The element from the input list",
             data:  "Injected value when the state machine is run, like an accumulator in Enum.reduce",
             matched: "A value depending on what kind of trigger was used"}

  The return value of the `transition_fn` will be injected into the `Match` struct's `data:` field for the next
  loop.

  #### Types of triggers

  * Function triggers

  ...are the most versatile triggers, when a function trigger triggers on an input it returns an unfalsy
  value that is passed into the `Match` struct's `matched:` field.

  * Regex triggers

  ...can, obviously, only be used with `String` inputs. The result of `Regex.run(trigger, input)` is passed into
  the `Match` struct's `matched:` field.

  * `true` trigger

  ... matches always, `true` is passed into the `matched:` field.


  * `:end` trigger

  ... does never match, however its associated `transaction_fn` is called, and its result will bet the result
  of the machine's run. See also the `end:` state below.

  #### Special States
  
  Two states are special in the sense that their names are fixed.

  * `:start`  state

  Is defined like any other state but is the machine's initial `current_state`. It is **obviously** necessarily
  present in the `transition_map`. 

  * `:end` state

  Can only have one `transition_fn` which is invoked at the end of the input list.


  #### Reserved States
  
  * `:halt` state

  No transition definitions for this state will ever be read. If the `current_state` of the machine becomes
  the `:halt` state, it stops and returns the `Match` struct's `data:` field.
  No `:end` state or trigger treatment is performed.

  * `:error` state and states starting with `:_`

  Reserved for future use.

  ### Some Detailed Examples
  
  Let's start with a single state machine.

        iex(0)> parse_and_add = fn(string, data) -> 
        ...(0)>   {n, _} = Integer.parse(string)
        ...(0)>   %{data|sum: data.sum + n} end
        ...(0)> add_error = fn(%{input: input, data: data}) ->
        ...(0)>   %{data|errors: [input|data.errors]} end
        ...(0)> states = %{
        ...(0)>   start: [
        ...(0)>     {~r(\\d+), fn %{matched: [d], data: data} -> parse_and_add.(d, data) end},
        ...(0)>     {true,    add_error},
        ...(0)>   ],
        ...(0)>   end: fn %{data: %{errors: errors, sum: sum}} -> {sum, Enum.reverse(errors)} end }
        ...(0)> run(~w{12 error 30 incorrect}, %{sum: 0, errors: []}, states)
        {42, ~w(error incorrect)}

  If the data is initially nil it needs not be passed into `run` and if the `transaction_fn` is a nop, it can be designated
  by `nil`.

        iex(1)> states = %{
        ...(1)>   start: [
        ...(1)>     { ~r{(\\d+)}, fn %{matched: [_, d]} -> d end, :halt },
        ...(1)>     { true, nil } ]}
        ...(1)> run(~w{ hello 42 84 }, states)
        "42"

  The difference between `:halt` and `:end` can be demonstrated with these slighly modified machines

        iex(2)> sm1 = %{
        ...(2)>   start: [
        ...(2)>     { ~r{(\\d+)}, fn %{matched: [_, d]} -> d end, :halt },
        ...(2)>     { true, nil } ],
        ...(2)>   end: fn %{data: x} -> {n, _} = Integer.parse(x); n end }
        ...(2)> sm2 = %{
        ...(2)>   start: [
        ...(2)>     { ~r{(\\d+)}, fn %{matched: [_, d]} -> d end, :end },
        ...(2)>     { true, nil } ],
        ...(2)>   end: fn %{data: x} -> {n, _} = Integer.parse(x); n end }
        ...(2)> { run(~w{ hello 42 84 }, sm1), run(~w{ hello 42 84 }, sm2) }
        {"42", 42}

  So far we have only seen `Regex` and `true` triggers, the next example uses function triggers

        iex(3)> odd? = &(rem(&1, 2) == 1)
        ...(3)> states = %{ 
        ...(3)>   start: [
        ...(3)>     {odd?, fn %{input: n, data: sum} -> sum + n end},
        ...(3)>     {true} ] }
        ...(3)> run(1..6|>Enum.into([]), 0, states)
        9

  Some might suggest that the `{true}` transition should be a default, but we prefer to raise an error
  if no transition matches

        iex(4)> odd? = &(rem(&1, 2) == 1)
        ...(4)> states = %{ 
        ...(4)>   start: [
        ...(4)>     {odd?, fn %{input: n, data: sum} -> sum + n end} ]}
        ...(4)> run(1..6|>Enum.into([]), 0, states)
        ** (RuntimeError) No transition found in state :start, on input 2

  An even more obvious exception is raised if a state has no transitions defined, that holds for the predefined
  `:start` state as for any other state.

        iex(5)> states=%{}
        ...(5)> run(~w[alpha beta], states)
        ** (RuntimeError) No transitions defined for state :start

        iex(6)> states=%{
        ...(6)>   start: [
        ...(6)>     {true, nil, :second} ]}
        ...(6)> run(~w[alpha beta], states)
        ** (RuntimeError) No transitions defined for state :second
  """

  import Lab42.SimpleStateMachine.Data
  import Lab42.SimpleStateMachine.Runner

  def run(input, data_or_states, states_or_nil \\ nil)
  def run(input, states, nil), do: run(:start, input, from_data(nil) , states)
  def run(input, data, states),do: run(:start, input, from_data(data), states)
end
