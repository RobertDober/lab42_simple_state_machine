defmodule Lab42.SimpleStateMachine.Runner do
  
  @moduledoc false

  def run(state, input, data, states)
  def run(state, [], data, states), do: _end_state(states, data)
  def run(:halt, _, data, _), do: data
  def run(:end, _, data, states), do: _end_state(states, data)
  def run(state, [input|rest], data, states) do
    case Map.fetch(states, state) do
      {:ok, transitions} ->
        case Enum.find_value(transitions, &_find_transition(input, &1, state)) |> IO.inspect do
          {transition, matched} -> _execute_transition(transition, matched, input, rest, data, states)
          _                     -> raise "No transition found in state #{inspect state}, on input #{inspect input}"
        end
       _                 -> raise "No transitions defined for state #{inspect state}"
    end
  end


  defp _end_state(states, data) do
    case Map.get(states, :end) do
      fun -> fun.(data)
      _   -> data
    end
  end

  defp _execute_transition({_, transition_fn, new_state}, matched, input, rest, data, states) do
    new_data = transition_fn.(%{data | matched: matched, input: input}) |> IO.inspect
    run(new_state, rest, %{data | data: new_data}, states) 
  end

  defp _find_transition(input, transition, current_state)
  defp _find_transition(input, {trigger, transition_fn}, current_state) do
    _find_transition(input, {trigger, transition_fn, current_state}, current_state)
  end
  defp _find_transition(input, {trigger, fun, ns}=transition, _) do 
    IO.inspect {:match, trigger, fun, ns}
    case _match_transition(trigger, input) do
      nil ->  false
      false -> false
      matched -> {transition, matched}
    end
  end

  defp _match_transition(trigger, input)
  defp _match_transition(true,_), do: true
  defp _match_transition(trigger_fn, input) when is_function(trigger_fn) do
    trigger_fn.(input)
  end
  defp _match_transition(trigger_fn, input) do
    Regex.run(trigger_fn, input)
  end
end
