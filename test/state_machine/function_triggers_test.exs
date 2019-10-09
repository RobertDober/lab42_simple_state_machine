defmodule StateMachine.FunctionTriggersTest do
  use ExUnit.Case

  import Lab42.StateMachine
  
  setup do
    {:ok, machine: make_state_machine(%{sum: 0}, states())}
  end
  describe "function triggers" do 
    test "halt immediately" do
      assert run([9], %{sum: 0}, states()) == {:start, [], %{sum: 0}}
    end
    test "halt immediately with make_machine", %{machine: machine} do
      assert machine.([9]) == {:start, [], %{sum: 0}}
    end

    test "all 10", %{machine: machine} do
      input = 1..10|>Enum.into([])
      expected = {:even, [1, :even, 3], :more_evens}

      assert machine.(input) == expected
    end
  end

  defp summer(data, {_, input}), do: %{data|sum: data.sum + input}
  defp states do
    %{ 
      start: [
        {&(&1>8), :halt},
        {&(&1<1), fn {_, input} -> {:halt, input} end, constant(:negative)},
        {&(rem(&1,2)==0), push_constant(:even), &summer/2, :even},
        {true} ],
      even: [
        {&(rem(&1,2)==0), :halt, constant(:more_evens)},
        {true, :id, &summer/2 }
      ]}
  end
        # state_machine = make_state_machine(%{sum: 0}, states)
        # [
        #    state_machine.(1..10|>Enum.into([])),
        #    state_machine.([1, 2, 3]),
        #    state_machine.([1, 9]),
        #    state_machine.([1, -1]),
        #    state_machine.([1, 3, 5]) ]
        # [ {:even, [1, :even, 3], :more_evens},
        #   {:even, [1, :even, 3], %{sum: 5}},
        #   {:start, [1], %{sum: 0}},
        #   {:start, [1, -1], :negative},
        #   {:start, [1, 3, 5], %{sum: 0}} ]
end
