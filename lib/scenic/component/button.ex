defmodule Scenic.Component.Button do
  @moduledoc """
  Add a button to a graph

  A button is a small scene that is pretty much just some text drawn over a
  rounded rectangle. The button scene contains logic to detect when the button
  is pressed, tracks it as the pointer moves around, and when it is released.

  ## Data

  `title`

  * `title` - a bitstring describing the text to show in the button

  ## Messages

  If a button press is successful, it sends an event message to the host scene
  in the form of:

      {:click, id}

  These messages can be received and handled in your scene via
  `Scenic.Scene.handle_event/3`. For example:

  ```
  ...

  @impl Scenic.Scene
  def init(_, _opts) do
    graph =
      Graph.build()
      |> Scenic.Components.button("Sample Button", id: :sample_btn_id, t: {10, 10})

    state = %{}

    {:ok, state, push: graph}
  end

  @impl Scenic.Scene
  def handle_event({:click, :sample_btn_id}, _from, state) do
    IO.puts("Sample button was clicked!")
    {:cont, event, state}
  end
  ```

  ## Styles

  Buttons honor the following standard styles

  * `:hidden` - If `false` the component is rendered. If `true`, it is skipped.
  The default is `false`.
  * `:theme` - The color set used to draw. See below. The default is `:primary`

  ## Additional Styles

  Buttons honor the following list of additional styles.

  * `:width` - :auto (default) or pass in a number to set the width of the button
  * `:height` - :auto (default) or pass in a number to set the height of the button.
  * `:radius` - pass in a number to set the radius of the button's rounded
  rectangle.
  * `:alignment` - set the alignment of the text inside the button. Can be one
  of `:left, :right, :center`. The default is `:center`.
  * `:button_font_size` - the size of the font in the button

  Buttons do not use the inherited `:font_size` style as they should look
  consistent regardless of what size the surrounding text is.

  ## Theme

  Buttons work well with the following predefined themes:
  `:primary`, `:secondary`, `:success`, `:danger`, `:warning`, `:info`,
  `:text`, `:light`, `:dark`

  To pass in a custom theme, supply a map with at least the following entries:

  * `:text` - the color of the text in the button
  * `:background` - the normal background of the button
  * `:border` - the border of the button
  * `:active` - the background while the button is pressed

  ## Usage

  You should add/modify components via the helper functions in
  [`Scenic.Components`](Scenic.Components.html#button/3)

  ### Examples

  The following example creates a simple button and positions it on the screen.

      graph
      |> button("Example", id: :button_id, translate: {20, 20})

  The next example makes the same button as before, but colors it as a warning
  button. See the options list above for more details.

      graph
      |> button("Example", id: :button_id, translate: {20, 20}, theme: :warning)
  """
  use Scenic.Component, has_children: false

  alias Scenic.Graph
  alias Scenic.Scene
  alias Scenic.Primitive.Style.Theme
  alias Scenic.Assets.Static

  import Scenic.Primitives, only: [{:rrect, 3}, {:text, 3}, {:update_opts, 2}]

  # import IEx

  @default_radius 3

  @default_font :roboto
  @default_font_size 20
  @default_alignment :center

  @impl Scenic.Component
  def validate(text) when is_bitstring(text) do
    {:ok, text}
  end

  def validate(data) do
    {
      :error,
      """
      #{IO.ANSI.red()}Invalid Button specification
      Received: #{inspect(data)}
      #{IO.ANSI.yellow()}
      The data for a button is just the text string to be displayed in the button.#{IO.ANSI.default_color()}
      """
    }
  end

  # --------------------------------------------------------
  @doc false
  @impl Scenic.Scene
  def init(scene, text, opts) when is_bitstring(text) and is_list(opts) do
    id = opts[:id]

    # theme is passed in as an inherited style
    theme =
      (opts[:theme] || Theme.preset(:primary))
      |> Theme.normalize()

    # font related info
    font = @default_font
    {:ok, {Static.Font, fm}} = Static.fetch(font)
    font_size = opts[:button_font_size] || @default_font_size

    ascent = FontMetrics.ascent(font_size, fm)
    descent = FontMetrics.descent(font_size, fm)
    fm_width = FontMetrics.width(text, font_size, fm)

    width =
      case opts[:width] || opts[:w] do
        nil -> fm_width + ascent + ascent
        :auto -> fm_width + ascent + ascent
        width when is_number(width) and width > 0 -> width
      end

    height =
      case opts[:height] || opts[:h] do
        nil -> font_size + ascent
        :auto -> font_size + ascent
        height when is_number(height) and height > 0 -> height
      end

    radius = opts[:radius] || @default_radius
    alignment = opts[:alignment] || @default_alignment

    vpos = height / 2 + ascent / 2 + descent / 3

    # build the graph
    graph =
      Graph.build(font: font, font_size: font_size)
      |> rrect({width, height, radius}, fill: theme.background, id: :btn, input: true)
      |> do_aligned_text(alignment, text, theme.text, width, vpos)
      # special case the dark and light themes to show an outline
      |> do_special_theme_outline(theme, theme.border)

    scene =
      scene
      |> assign(
        vpos: vpos,
        graph: graph,
        theme: theme,
        pressed: false,
        id: id
      )
      |> push_graph(graph)

    {:ok, scene}
  end

  defp do_aligned_text(graph, :center, text, fill, width, vpos) do
    text(graph, text,
      fill: fill,
      translate: {width / 2, vpos},
      text_align: :center,
      id: :title
    )
  end

  defp do_aligned_text(graph, :left, text, fill, _width, vpos) do
    text(graph, text,
      fill: fill,
      translate: {8, vpos},
      text_align: :left,
      id: :title
    )
  end

  defp do_aligned_text(graph, :right, text, fill, width, vpos) do
    text(graph, text,
      fill: fill,
      translate: {width - 8, vpos},
      text_align: :right,
      id: :title
    )
  end

  defp do_special_theme_outline(graph, :dark, border) do
    Graph.modify(graph, :btn, &update_opts(&1, stroke: {1, border}))
  end

  defp do_special_theme_outline(graph, :light, border) do
    Graph.modify(graph, :btn, &update_opts(&1, stroke: {1, border}))
  end

  defp do_special_theme_outline(graph, _, _border) do
    graph
  end

  # --------------------------------------------------------
  # pressed in the button
  @impl Scenic.Scene
  def handle_input({:cursor_button, {0, :press, _, _}}, :btn, scene) do
    :ok = capture_input(scene, :cursor_button)

    scene =
      scene
      |> update_color(true, true)
      |> assign(pressed: true)

    {:noreply, scene}
  end

  # --------------------------------------------------------
  # pressed outside the button
  # only happens when input is captured
  # could happen when reconnecting to a driver...
  def handle_input(
        {:cursor_button, {0, :press, _, _}},
        _id,
        scene
      ) do
    :ok = release_input(scene)

    scene =
      scene
      |> update_color(false, false)
      |> assign(pressed: false)

    {:noreply, scene}
  end

  # --------------------------------------------------------
  # released inside the button
  def handle_input(
        {:cursor_button, {0, :release, _, _}},
        :btn,
        %Scene{assigns: %{pressed: true, id: id}} = scene
      ) do
    :ok = release_input(scene)
    :ok = send_parent_event(scene, {:click, id})

    scene =
      scene
      |> update_color(false, true)
      |> assign(pressed: false)

    {:noreply, scene}
  end

  # --------------------------------------------------------
  # released outside the button
  # only happens when input is captured
  def handle_input(
        {:cursor_button, {0, :release, _, _}},
        _id,
        scene
      ) do
    :ok = release_input(scene)

    scene =
      scene
      |> update_color(false, true)
      |> assign(pressed: false)

    {:noreply, scene}
  end

  # ignore other button press events
  def handle_input({:cursor_button, {_, _, _, _}}, _id, scene) do
    {:noreply, scene}
  end

  # ============================================================================
  # internal utilities

  defp update_color(%Scene{assigns: %{graph: graph, theme: theme}} = scene, true, true) do
    graph = Graph.modify(graph, :btn, &update_opts(&1, fill: theme.active))
    push_graph(scene, graph)
  end

  defp update_color(%Scene{assigns: %{graph: graph, theme: theme}} = scene, _, _) do
    graph = Graph.modify(graph, :btn, &update_opts(&1, fill: theme.background))
    push_graph(scene, graph)
  end
end
