defprotocol Extractable do
  @fallback_to_any true

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

      iex> {:ok, {elem, result}} = Extractable.extract(200..100)
      iex> elem
      200
      iex> result
      199..100

  """

  @spec extract(Extractable.t()) :: {:ok, {item :: any, Extractable.t()}} | :error
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
  def extract(map) do
    case Map.keys(map) do
      [] ->
        {:error, :empty}

      [key | _rest_keys] ->
        {value, rest} = Map.pop(map, key)
        element = {key, value}
        {:ok, {element, rest}}
    end
  end
end

defimpl Extractable, for: MapSet do
  @doc """
  Extracts the element corresponding to the first key according to the Erlang term of ordering.
  """
  def extract(map_set) do
    case Enum.fetch(map_set, 0) do
      :error ->
        {:error, :empty}

      {:ok, element} ->
        rest = MapSet.delete(map_set, element)
        {:ok, {element, rest}}
    end
  end
end

defimpl Extractable, for: Range do
  @doc """
  Extracts the element corresponding to the first key according to the Erlang term of ordering.
  """
  def extract(first..first) do
    {:ok, {first, nil}}
  end

  def extract(first..last) when first <= last do
    {:ok, {first, (first + 1)..last}}
  end

  def extract(first..last) when first > last do
    {:ok, {first, (first - 1)..last}}
  end
end

defimpl Extractable, for: Any do
  @doc """
  Extracts the first element to the Erlang term of ordering.
  """
  def extract(enumerable) do
    case Enum.fetch(enumerable, 0) do
      :error ->
        {:error, :empty}

      {:ok, element} ->
        rest = Enum.drop(enumerable, 1)
        {:ok, {element, rest}}
    end
  end
end
