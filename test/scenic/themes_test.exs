defmodule Scenic.ThemesTest do
  use ExUnit.Case, async: true
  doctest Scenic.Themes

  alias Scenic.Themes
  alias Scenic.Color

  # we expect errors to be logged in this set of tests. This happens when we purposefully
  # attempted to load an asset that has been tampered with. So turn off the logging to
  # keep the tests clean.
  @moduletag :capture_log

  @theme_light %{
    text: :black,
    background: :white,
    border: :dark_grey,
    active: {215, 215, 215},
    thumb: :cornflower_blue,
    focus: :blue,
    highlight: :saddle_brown
  }

  @theme_dark %{
    text: :white,
    background: :black,
    border: :light_grey,
    active: {40, 40, 40},
    thumb: :cornflower_blue,
    focus: :cornflower_blue,
    highlight: :sandy_brown
  }

  @primary Map.merge(@theme_dark, %{background: {72, 122, 252}, active: {58, 94, 201}})
  @secondary Map.merge(@theme_dark, %{background: {111, 117, 125}, active: {86, 90, 95}})
  @success Map.merge(@theme_dark, %{background: {99, 163, 74}, active: {74, 123, 56}})
  @danger Map.merge(@theme_dark, %{background: {191, 72, 71}, active: {164, 54, 51}})
  @warning Map.merge(@theme_light, %{background: {239, 196, 42}, active: {197, 160, 31}})
  @info Map.merge(@theme_dark, %{background: {94, 159, 183}, active: {70, 119, 138}})
  @text Map.merge(@theme_dark, %{text: {72, 122, 252}, background: :clear, active: :clear})

  @themes %{
    light: @theme_light,
    dark: @theme_dark,
    primary: @primary,
    secondary: @secondary,
    success: @success,
    danger: @danger,
    warning: @warning,
    info: @info,
    text: @text
  }

  @schema [:background, :text, :thumb, :focus, :highlight]

  @properly_configured_module [
    name: :scenic,
    themes: @themes,
    palette: Scenic.Palette.get()
  ]

  # import IEx

  test "module returns the module" do
    assert Themes.module() == Scenic.Test.Themes
  end

  test "load returns the properly configured themes" do
    assert Themes.load() == @properly_configured_module
  end

  test "normalize returns the correct theme" do
    assert Themes.normalize({:scenic, :dark}) == @theme_dark
  end

  test "normalize returns default scenic theme when an atom is passed" do
    assert Themes.normalize(:dark) == @theme_dark
  end

  test "custom validate method accepts custom named themes" do
    assert Themes.validate({:custom_scenic, :custom_dark}) == {:ok, {:custom_scenic, :custom_dark}}
    assert Themes.validate({:custom_scenic, :custom_light}) == {:ok, {:custom_scenic, :custom_light}}
    assert Themes.validate({:custom_scenic, :custom_primary}) == {:ok, {:custom_scenic, :custom_primary}}
    assert Themes.validate({:custom_scenic, :custom_secondary}) == {:ok, {:custom_scenic, :custom_secondary}}
    assert Themes.validate({:custom_scenic, :custom_success}) == {:ok, {:custom_scenic, :custom_success}}
    assert Themes.validate({:custom_scenic, :custom_danger}) == {:ok, {:custom_scenic, :custom_danger}}
    assert Themes.validate({:custom_scenic, :custom_warning}) == {:ok, {:custom_scenic, :custom_warning}}
    assert Themes.validate({:custom_scenic, :custom_info}) == {:ok, {:custom_scenic, :custom_info}}
    assert Themes.validate({:custom_scenic, :custom_text}) == {:ok, {:custom_scenic, :custom_text}}
  end

  test "custom validate method rejects map without custom standard color" do
    {:error, msg} = Themes.validate({:custom_scenic, :custom_invalid})
    assert msg =~ "Invalid theme specification"
    assert msg =~ "Map entry: :surface"
  end

  test "validate accepts the named themes" do
    assert Themes.validate({:scenic, :dark}) == {:ok, {:scenic, :dark}}
    assert Themes.validate({:scenic, :light}) == {:ok, {:scenic, :light}}
    assert Themes.validate({:scenic, :primary}) == {:ok, {:scenic, :primary}}
    assert Themes.validate({:scenic, :secondary}) == {:ok, {:scenic, :secondary}}
    assert Themes.validate({:scenic, :success}) == {:ok, {:scenic, :success}}
    assert Themes.validate({:scenic, :danger}) == {:ok, {:scenic, :danger}}
    assert Themes.validate({:scenic, :warning}) == {:ok, {:scenic, :warning}}
    assert Themes.validate({:scenic, :info}) == {:ok, {:scenic, :info}}
    assert Themes.validate({:scenic, :text}) == {:ok, {:scenic, :text}}
  end

  test "validate rejects invalid theme names" do
    {:error, msg} = Themes.validate(:invalid)
    assert msg =~ "The theme could not be found in library"
  end

  test "validate defaults to the scenic library when an atom is passed" do
    assert Themes.validate(:primary) == {:ok, :primary}
  end

  test "validate accepts maps of colors" do
    color_map = %{
      text: :red,
      background: :green,
      border: :blue,
      active: :magenta,
      thumb: :cyan,
      focus: :yellow,
      my_color: :black
    }

    assert Themes.validate(color_map) == {:ok, color_map}
  end

  test "validate rejects maps with invalid colors" do
    color_map = %{
      text: :red,
      background: :green,
      border: :invalid,
      active: :magenta,
      thumb: :cyan,
      focus: :yellow,
      my_color: :black
    }

    {:error, msg} = Themes.validate(color_map)
    assert msg =~ "Map entry: :border"
    assert msg =~ "Invalid Color specification: :invalid"
  end

  test "validate accepts a theme against a schema passed in" do
    assert Themes.validate({:scenic, :primary}, @schema)
  end

  test "validate rejects maps without the standard colors" do
    color_map = %{some_name: :red}
    {:error, msg} = Themes.validate(color_map)
    assert msg =~ "didn't include all the required color"
  end

  test "validate rejects invalid values" do
    {:error, _msg} = Themes.validate("totally wrong")
  end

  @default_schema [:text, :background, :border, :active, :thumb, :focus]

  test "get_schema returns the correct schema" do
    assert Themes.get_schema(:scenic) == @default_schema
  end

  test "custom color can be retrieved" do
   assert Color.to_rgb(:yellow_1) == {:color_rgb, {255, 246, 0}}
  end
end
