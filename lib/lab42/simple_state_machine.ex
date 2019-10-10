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

  Can only have one `transition_fn` which is invoked at the end of the input list, **only** if the `current_state`
  does not have an `:end` trigger as explained above.

  **N.B.** if no `:end` state or trigger is present the machine returns its `Match` struct's `data:` field.

  #### Reserved States
  
  * `:halt` state

  No transition definitions for this state will ever be read. If the `current_state` of the machine becomes
  the `:halt` state, it stops and returns the `Match` struct's `data:` field.
  No `:end` state or trigger treatment is performed.

  * `:error` state and states starting with `:_`

  Reserved for future use.

  ### Some Detailed Examples
  
  Let's start with a single state machine.

        iex(0)> parse_and_add = fn(string, %{sum: sum}=data) -> 
        ...(0)>   {n, _} = Integer.parse(string)
        ...(0)>   %{data|sum: data.sum + n} end
        ...(0)> add_error = fn(%{input: input, data: %{errors: errors}=data}) ->
        ...(0)>   %{data|errors: [input|data.errors]} end
        ...(0)> states = %{
        ...(0)>   start: [
        ...(0)>     {~r(\d+), fn %{matched: [d], data: data} -> parse_and_add.(d, data) end},
        ...(0)>     {true,    add_error},
        ...(0)>     {:end, fn %{data: %{errors: errors, sum: sum}} -> {sum, Enum.reverse(errors)} end}
        ...(0)>   ]}
        ...(0)> run(~w{12 error 30 incorrect}, %{sum: 0, errors: []}, states)
        {42, ~w(error incorrect)}

  """
end
