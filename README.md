# Extractable

[![hex.pm version](https://img.shields.io/hexpm/v/extractable.svg)](https://hex.pm/packages/extractable)
[![Build Status](https://travis-ci.org/Qqwy/elixir-extractable.svg?branch=master)](https://travis-ci.org/Qqwy/elixir-extractable)

A lightweight reusable Extractable protocol, allowing extracting elements one-at-a-time from a collection.

## Description

Extractable is a simple protocol that allows for the extraction of elements from a collection,
one element at a time.

This is the major difference with the Enumerable protocol:
Enumerable only works with whole collections at a time,
so extracting a few items and then returning the rest of the unconsumed collection is impossible.

This is exactly what Extractable _does_ allow.
Extractable is however slower if used repeatedly,
because the wrapping/unwrapping of certain structures has to happen once per extracted element,
rather than once per collection.

Extractable.extract/2 returns `{:ok, {item, collection}}` if it was possible to extract an item from the collection.
`:error` is returned when the `collection` is for instance (currently) empty.

What item is extracted depends on the collection: For collections where it matters, the most logical or efficient approach is taken.
Some examples:

- For Lists, the _head_ of the list is returned as item.
- For Maps, an arbitrary `{key, value}` is returned as item.
- For MapSets, an arbitrary value is returned as item.

## Examples

```elixir
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
```




## Installation

The package can be installed
by adding `extractable` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:extractable, "~> 0.1.0"}]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/extractable](https://hexdocs.pm/extractable).

## Changelog

- 0.2.1 - Fixing incorrect typespec on `extract/1` callback. Thank you, @brandonhamilton!
- 0.2.0 - Cleaner documentation.
- 0.1.0 - Initial release.
