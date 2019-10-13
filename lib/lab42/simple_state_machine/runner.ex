defmodule Lab42.SimpleStateMachine.Runner do

  use Lab42.SimpleStateMachine.Types
  
  @moduledoc false

  @spec run( state_t(), list(), any(), map()) :: any()
  def run(state, input, data, states)
  def run(_state, [], data, states), do: _end_state(states, data)
  def run(:halt, _, data, _), do: data.data
  def run(:end, _, data, states), do: _end_state(states, data)
  def run(state, [input|rest], data, states) do
    case Map.fetch(states, state) do
      {:ok, transitions} ->
        case Enum.find_value(transitions, &_find_transition(input, &1, state)) do
          {transition, matched} -> _execute_transition(transition, matched, input, rest, data, states)
          _                     -> raise "No transition found in state #{inspect state}, on input #{inspect input}"
        end
       _                 -> raise "No transitions defined for state #{inspect state}"
    end
  end


  @spec _end_state( map(), any() ) :: any()
  defp _end_state(states, data) do
    case Map.get(states, :end) do
      nil -> data.data
      fun -> fun.(data)
    end
  end

  @spec _execute_transition( transition_t(), any(), any(), list(), any(), map() ) :: any()
  defp _execute_transition(transition, matched, input, rest, data, states)
  defp _execute_transition({_, nil, new_state}, _matched, _input, rest, data, states) do
    run(new_state, rest, data, states) 
  end
  defp _execute_transition({_, transition_fn, new_state}, matched, input, rest, data, states) do
    new_data = transition_fn.(%{data | matched: matched, input: input})
    run(new_state, rest, %{data | data: new_data}, states) 
  end

  @spec _find_transition( any(), transition_t(), state_t() ) :: maybe({complete_transition_t(), any()})
  defp _find_transition(input, transition, current_state)
  defp _find_transition(input, {trigger}, current_state) do
    _find_transition(input, {trigger, nil, current_state}, current_state)
  end
  defp _find_transition(input, {trigger, transition_fn}, current_state) do
    _find_transition(input, {trigger, transition_fn, current_state}, current_state)
  end
  defp _find_transition(input, {trigger, _fun, _ns}=transition, _) do 
    case _match_transition(trigger, input) do
      nil ->  nil
      false -> nil
      matched -> {transition, matched}
    end
  end

  @spec _match_transition( trigger_t(), any() ) :: any()
  defp _match_transition(trigger, input)
  defp _match_transition(true,_), do: true
  defp _match_transition(trigger_fn, input) when is_function(trigger_fn) do
    trigger_fn.(input)
  end
  defp _match_transition(trigger_fn, input) do
    Regex.run(trigger_fn, input)
  end
end
