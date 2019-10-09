defmodule Lab42.StateMachine.Runner do

  use Lab42.StateMachine.Types

  @moduledoc """
  Runs the state machine by finding and executing transitions
  """

  @doc false
  @spec run( state_t(), list(), list(), any(), transition_map_t() ) :: result_t() 
  def run(current_state, input, result, data, state_definitions)
  def run(current_state, [], result, data, _), do: {current_state, Enum.reverse(result), data}
  def run(current_state, input, result, data, states) do
#    insp {:run, current_state, input, result, data}
    case Map.get(states, current_state) do
      nil         -> {:error, "No transitions found for current state", current_state}
      transitions -> _run_transitions(current_state, transitions, input, result, data, states)
    end
  end

  @doc """
  Convenience transformer function to stop the state machine, can be used with the atom `:halt`
  """
  def halt_transfo(_), do: :halt

  @doc """
  Convenience function to push an input to the output without changing it, can be used with the atom `:id` in
  the transformer position of a transition, e.g. `{~r{alpha}, :id, fn count, _ -> count + 1 end}`
  """
  def ident_transfo({_, line}), do: line

  @doc """
  Convenience function to not change the data. It can be used with the atom `:id` in
  the updater position of a transition, e.g. `{~r{alpha}, fn {_, line} -> String.reverse(line), :id}`
  """
  def ident_updater(data, _), do: data

  @doc """
  Convenience function to ignore an input, it can be used with the atom `:ignore` in
  the transformer position of a transition, e.g. `{~r{alpha}, :ignore, fn count, _ -> count + 1 end}`
  """
  def ignore_input(_), do: :ignore


  defp _execute_transition(transition, matches, input, data)
  defp _execute_transition({_, transformer, updater, new_state}, matches, input, data) do
    transformed = transformer.({matches, input})
    updated     = updater.(data, {matches, input})
    {new_state, transformed, updated}
  end

  defp _match_trigger(trigger, input)
  defp _match_trigger(true, _), do: []
  defp _match_trigger(fn_trigger, input) when is_function(fn_trigger), do: fn_trigger.(input)
  defp _match_trigger(rgx_trigger, input), do: Regex.run(rgx_trigger, input)

  defp _normalize_transition(transition, current_state)
  defp _normalize_transition({trigger}, current_state), do: {trigger, &ident_transfo/1, &ident_updater/2, current_state}
  defp _normalize_transition({trigger, f1}, current_state), do: _replace_symbolic_fns({trigger, f1, &ident_updater/2, current_state})
  defp _normalize_transition({trigger, f1, f2}, current_state), do: _replace_symbolic_fns({trigger, f1, f2, current_state})
  defp _normalize_transition(already_normalized, _current_state), do: _replace_symbolic_fns(already_normalized)

  @predefined_transformers %{
    halt: &__MODULE__.halt_transfo/1,
    id: &__MODULE__.ident_transfo/1,
    ignore: &__MODULE__.ignore_input/1,
  }
  @predefined_updaters %{
    id: &__MODULE__.ident_updater/2
  }
  defp _replace_symbolic_fns(transition)
  defp _replace_symbolic_fns({trigger, f1, f2, state}) when is_atom(f1) do
    _replace_symbolic_fns({trigger, Map.fetch!(@predefined_transformers, f1), f2, state})
  end
  defp _replace_symbolic_fns({trigger, f1, f2, state}) when is_atom(f2) do
    _replace_symbolic_fns({trigger, f1, Map.fetch!(@predefined_updaters, f2), state})
  end
  defp _replace_symbolic_fns(really_ok_now), do: really_ok_now

  defp _run_normalized_transitions(current_state, transitions, input, result, data, states)
  defp _run_normalized_transitions(current_state, [{trigger,_,_,_}=tran|trans], [input|rest], result, data, states) do
#    insp {:run_norm, current_state, tran, input, result, data}
    if matches = _match_trigger(trigger, input) do
      _execute_transition(tran, matches, input, data) |>
      _loop(rest, result, states)
    else
      _run_transitions(current_state, trans, [input|rest], result, data, states)
    end
  end

  defp _run_transitions(current_state, transitions, input, result, data, states)
  defp _run_transitions(current_state, [], [input|_], _result, _data, _states) do
    # It is preferable to not allow this, so that an explicit `true` trigger needs to be
    # defined. One might later add an option `default_copy: true` to shorten the transition
    # definitions if so is wished.
    {:error, "No trigger matched the current input #{inspect input}", current_state}
  end
  defp _run_transitions(current_state, [tran|trans], input, result, data, states) do
#    insp {:run_tr, current_state, tran, input, result, data}
    _run_normalized_transitions(current_state, [_normalize_transition(tran, current_state)|trans], input, result, data, states)
  end

  defp _loop(new_data_triple, rest, result, states)
  defp _loop({new_state, :halt, updated}, _rest, result, _states) do
    # Trigger halt with empty input
    run(new_state, [], result, updated, nil)
  end
  defp _loop({new_state, {:halt, value}, updated}, _rest, result, _states) do
    # Trigger halt with empty input
    run(new_state, [], [value|result], updated, nil)
  end
  defp _loop({new_state, :ignore, updated}, rest, result, states) do
    run(new_state, rest, result, updated, states)
  end
  defp _loop({new_state, {:push, transformed}, updated}, rest, result, states) do
    run(new_state, rest, [transformed|result], updated, states)
  end
  defp _loop({new_state, transformed, updated}, rest, result, states) do
    run(new_state, rest, [transformed|result], updated, states)
  end


  # TODO: Remove for release
  # defp insp(data) do
  #   if System.get_env("DEBUG") do
  #     IO.inspect data
  #   end
  # end

end
