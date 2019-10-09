defmodule Lab42.StateMachine do
  
  use Lab42.StateMachine.Types

  @moduledoc """
  # Lab42.StateMachine

  ## Synopsis
  
  A simple State Machine operating on a list of input values, a map of transition definitions
  and an accumulator.

  ## What is the _Transition Definitions Map_?

  It maps each `state` to a list of `transitions`. Each `transition` is of the following format, as
  defined by type `transition_t`

  ```elixir
  {trigger, transformer, updater, new_state}

  ```

  ## State, did you say state?
  
  Yes I did, and what I mean by it is that the State Machine keeps track of its state (very surprising)
  and some data, passed into by the user.

  ## How do these _Transitions_ transform the input?

  The State Machine processes its input in a loop in which, depending on the current input element, designated
  as `input` and the current state, designated as `current_state` a transition is triggered.

  Data is passed in like an accumulator in `Enum.reduce` it is designated as `data`.

  The triggered transition will define the `current_state` of the next loop, if any, and perform actions defining what
  goes to the output and how `data` changes.

  As one might guess these actions are performed by the `transformer` and the `updater` of the triggered transition.


  ## So what is the contract?
  
  ### Starting the whole thing.
  
  Create the _Transition Defintions Map_, knowing that the State Machine will start with `current_state` equal to `:start`,
  yes I konw, naming is difficult ;).

  Then run the whole thing like that:

  ```elixir
    Lab42.StateMachine.run(input, my_data, %{})
  ```

  The empty map passed in will cause havoc though

        iex(0)> input = ~w(alpha)
        ...(0)> my_data = %{n: 42}
        ...(0)> Lab42.StateMachine.run(input, my_data, %{})
        {:error, "No transitions found for current state", :start}  

  A minimal example might be a line counter

        iex(1)> input = ~w{alpha beta}
        ...(1)> count = 0
        ...(1)> states = %{
        ...(1)>   start: [ {true, fn {_, line} -> line end, fn count, _ -> count + 1 end, :start} ]
        ...(1)> } 
        ...(1)> run(input, count, states)
        {:start, ~w{alpha beta}, 2}

  N.B. That the `true` trigger alwyas matches, all other triggers are passed into `Regex.match(trigger, input_line)`

  One could argue that a default behavior of copying the current input to the output might be convenient, but that might
  lead to difficulties in debugging state machines. (Maybe in later versions with an option for `run`?)

  On the same token some StateMachines, like the counter above collect the output without needing it, although we will
  learn below how to avoid this, a global option to not collect will make the _Transitions Map_ more concise.

  Therefore the following will happen

        iex(2)> input = ~w{alpha beta}
        ...(2)> states = %{
        ...(2)>   start: []
        ...(2)> } 
        ...(2)> run(input, nil, states)
        {:error, "No trigger matched the current input \\"alpha\\"", :start}

  Let us return to the correctly working example, let us simplify that rather expressive transition

        iex(3)> input = ~w{alpha beta}
        ...(3)> states = %{
        ...(3)>   start: [ {true, :id, fn count, _ -> count + 1 end, :start} ]
        ...(3)> }
        ...(3)> run(input, 0, states)
        {:start, ~w(alpha beta), 2}

  So we can use a shortcut for copying the input to the output, that is better already, but still, why
  create the output that is not needed, let us use the atom form of the transformer function

        iex(4)> input = ~w{alpha beta}
        ...(4)> states = %{
        ...(4)>   start: [ {true, fn _ -> :ignore end, fn count, _ -> count + 1 end, :start} ]
        ...(4)> }
        ...(4)> run(input, 0, states)
        {:start, ~w(), 2}

  As there is a shortcut for `:id` so there is one for `:ignore`

        iex(5)> input = ~w{alpha beta}
        ...(5)> states = %{
        ...(5)>   start: [ {true, :ignore, fn count, _ -> count + 1 end, :start} ]
        ...(5)> }
        ...(5)> run(input, 0, states)
        {:start, ~w(), 2}

  But what if we want to have `:ignore` in the output? Let us assume that we want to replace all `"alphas"` with
  `:ignore`. We can use the tuple form of the transformer in this case.

  This example also demonstrates that we do not need to specify the updater and the new state if these do
  not change and that even pushing the input to the output can be omitted, therefore the transitions `{true, :id}` and
  `{true}` have the same semantics.

  And a third simplifaction is that we can omit to pass nil as data, but note that it will present in the result.

        iex(6)> input = ~w{alpha beta alpha}
        ...(6)> states = %{
        ...(6)>   start: [ 
        ...(6)>     {~r{alpha}, fn _ -> {:push, :ignore} end},
        ...(6)>     {true}] }
        ...(6)> run(input, states)
        {:start, [:ignore, "beta", :ignore], nil}



  """

  @spec run( list(), transition_map_t() ) :: result_t()
  def run(input, states), do: run(input, nil, states)

  @spec run( list(), any(), transition_map_t ) :: result_t() 
  def run(input, data, states) do
    Lab42.StateMachine.Runner.run(:start, input, [], data, states)
  end
end
