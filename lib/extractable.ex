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
  `{:error, reason}` is returned when no element can be extracted.

  The following error reasons are standardized:

  - `:empty`: the `collection` is empty, and an element needs to be inserted first before extracting would work.

  Other reasons might be used if it makes sense for your collection.

  ### Extraction Order

  What item is extracted depends on the collection: For collections where it matters, the most logical or efficient approach is taken.
  Some examples:

  - For Lists, the _head_ of the list is returned as item.
  - For Maps, an arbitrary `{key, value}` is returned as item.
  - For MapSets, an arbitrary value is returned as item.
  - For Ranges the first item of the range is returned.

  ## Examples

      iex> Extractable.extract([])
      {:error, :empty}

      iex> Extractable.extract([1, 2, 3])
      {:ok, {1, [2, 3]}}

      iex> Extractable.extract(%{a: 1, b: 2, c: 3})
      {:ok, {{:a, 1}, %{b: 2, c: 3}}}

      iex> Extractable.extract(MapSet.new())
      {:error, :empty}

      iex> {:ok, {elem, result}} = Extractable.extract(MapSet.new([1, 2, 3]))
      iex> elem
      1
      iex> result
      #MapSet<[2, 3]>

      iex> Extractable.extract(200..100)
      {:ok, {200, 199..100}}

      iex> Extractable.extract(42..42)
      {:ok, {42, :empty}}

  """


  @spec extract(Extractable.t()) :: {:ok, {item :: any(), Extractable.t()}} | {:error, reason :: any()}

  def extract(collection)
end

defimpl Extractable, for: List do
  def extract([]), do: {:error, :empty}
  def extract([elem | rest]), do: {:ok, {elem, rest}}
end

defimpl Extractable, for: Map do
  @doc """
  Extracts the element corresponding to the first key according to the Erlang term of ordering.
  """

  def extract(map) when map_size(map) > 0 do
    [key | _] = Map.keys(map)
    {value, rest} = Map.pop(map, key)
    {:ok, {{key, value}, rest}}
  end

  def extract(_map) do
    {:error, :empty}
  end
end

defimpl Extractable, for: MapSet do
  @doc """
  Extracts the element corresponding to the first key according to the Erlang term of ordering.
  """
  def extract(map_set) do
    case Enum.fetch(map_set, 0) do
      {:ok, element} ->
        rest = MapSet.delete(map_set, element)
        {:ok, {element, rest}}

      :error ->
        {:error, :empty}
    end
  end
end

defimpl Extractable, for: Range do
  @doc """
  Extracts the first element of the range.

  Contrary to other implementations, when it extracts the element of a range of size one,
  it returns `{integer, :empty}` where integer is the element, and `:empty` an atom.

  ## Example

      iex> Extractable.extract(1..10)
      {1, 2..10}

      iex> Extractable.extract(42..42)
      {42, :empty}

  """
  def extract(first..first) do
    {:ok, {first, :empty}}
  end

  def extract(first..last) when first <= last do
    {:ok, {first, (first + 1)..last}}
  end

  def extract(first..last) when first > last do
    {:ok, {first, (first - 1)..last}}
  end
end
