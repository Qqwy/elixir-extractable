defprotocol Extractable do
  @moduledoc """
  Extractable is a simple protocol that allows for the extraction of elements from a collection,
  one element at a time.

  This is the major difference with the Enumerable protocol:
  Enumerable only works with whole collections at a time,
  so extracting a few items and then returning the rest of the unconsumed collection is impossible.

  This is exactly what Extractable _does_ allow.
  Extractable is however slower if used repeatedly,
  because the wrapping/unwrapping of certain structures has to happen once per extracted element,
  rather than once per collection.

  """

  @doc """
  Extractable.extract/2 returns `{:ok, {item, collection}}` if it was possible to extract an item from the collection.
  `:error` is returned when the `collection` is for instance (currently) empty.

  What item is extracted depends on the collection: For collections where it matters, the most logical or efficient approach is taken.
  Some examples:

  - For Lists, the _head_ of the list is returned as item.
  - For Maps, an arbitrary `{key, value}` is returned as item.
  - For MapSets, an arbitrary value is returned as item.

  ## Examples

      iex> Extractable.extract([])
      :error

      iex> Extractable.extract([])
      :error

      iex> Extractable.extract([1, 2, 3])
      {:ok, {1, [2, 3]}}

      iex> Extractable.extract(%{a: 1, b: 2, c: 3})
      {:ok, {{:a, 1}, %{b: 2, c: 3}}}

      iex> Extractable.extract(MapSet.new())
      :error

      iex> Extractable.extract(MapSet.new([1, 2, 3]))
      {:ok, {1, #MapSet<[2, 3]>}}

  """

  @spec extract(Extractable.t) :: {:ok, {item :: any, Extractable.t}} | :error
  def extract(collection)
end

defimpl Extractable, for: List do
  def extract([]), do: :error
  def extract([elem | rest]), do: {:ok, {elem, rest}}
end

defimpl Extractable, for: Map do
  @doc """
  The Map implementation is unfortunately not very performant,
  because Erlang does not expose a way to get an arbitrary `{key, value}`
  from the Map, so the whole map needs to be converted to a list and back again.
  """
  def extract(map) when map_size(map) == 0, do: :error
  def extract(map) do
    [elem | rest_list] = :maps.to_list(map)
    rest = :maps.from_list(rest_list)
    {:ok, {elem, rest}}
  end
end

defimpl Extractable, for: MapSet do
  @doc """
  The MapSet implementation is unfortunately not very performant,
  because Erlang does not expose a way to get an arbitrary `{key, value}`
  from the MapSet, so the whole map needs to be converted to a list and back again.
  """
  def extract(map_set) do
    if MapSet.equal?(map_set, MapSet.new()) do
      :error
    else
      [elem | rest_list] = MapSet.to_list(map_set)
      rest = MapSet.new(rest_list)
      {:ok, {elem, rest}}
    end
  end
end

# TODO: Decide if it is a good or bad idea to add a Tuple-implementation
# defimpl Extractable, for: Tuple do
#   def extract({}), do: :error
#   def extract(tuple) do
#     elem = elem(tuple, 0)
#     rest = Tuple.delete_at(tuple, 0)
#     {:ok, {elem, rest}}
#   end
# end
