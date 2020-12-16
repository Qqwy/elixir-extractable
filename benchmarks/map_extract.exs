
defmodule MapList do
  @doc "Original implementation"
  def extract(map) when map_size(map) == 0, do: {:error, :empty}
  def extract(map) do
    [elem | rest_list] = :maps.to_list(map)
    rest = :maps.from_list(rest_list)
    {:ok, {elem, rest}}
  end
end

defmodule MapKeys do
  @doc "Implementation based on Map.keys"
  def extract(map) do
    case Map.keys(map) do
      [] -> {:error, :empty}
      [key | _rest] ->
        {value, rest} = Map.pop(map, key)
        element = {key, value}
        {:ok, {element, rest}}
    end
  end
end

defmodule MapKeysSize do
  @doc "Implementation based on Map.keys with extra `map_size` short-circuit"
  def extract(map) when map_size(map) == 0, do: {:error, :empty}
  def extract(map) do
    [key | _] = Map.keys(map)
    {value, rest} = Map.pop(map, key)
    element = {key, value}
    {:ok, {element, rest}}
  end
end

defmodule MapIterator do
  @doc "Implementation based on `:maps.iterator`/`:maps.next`"
  def extract(map) do
    case map |> :maps.iterator() |> :maps.next() do
      :none ->
        {:error, :empty}
      {key, value, rest_iter} ->
        element = {key, value}
        rest = :maps.map(fn _key, val -> val end, rest_iter)
        {:ok, {element, rest}}
    end
  end
end

map_with_size = fn size ->
  0..size
  |> Enum.into(%{}, fn x -> {x, x} end)
end

Benchee.run(
  %{
    "MapKeys" => &MapKeys.extract/1,
    "MapKeysSize" => &MapKeysSize.extract/1,
    "MapList" => &MapList.extract/1,
    "MapIterator" => &MapIterator.extract/1,
  },
  inputs: %{
    "empty" => %{},
    "10" => map_with_size.(10),
    "100" => map_with_size.(100),
    # "1000" => map_with_size.(1000),
    # "10000" => map_with_size.(10000),
  },
  time: 1,
  memory_time: 1
)
