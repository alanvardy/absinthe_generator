defmodule AbsintheGenerator.Schema do
  alias AbsintheGenerator.Definitions

  @definition [
    app_name: Definitions.app_name(),
    moduledoc: Definitions.moduledoc(),

    queries: [
      type: {:list, :string},
      default: [],
      doc: "List of query namespaces"
    ],

    mutations: [
      type: {:list, :string},
      default: [],
      doc: "List of mutation namespaces"
    ],

    subscriptions: [
      type: {:list, :string},
      default: [],
      doc: "List of subscription namespaces"
    ],

    types: [
      type: {:list, :string},
      default: [],
      doc: "List of types"
    ],

    data_sources: [
      type: {:list, :keyword_list},
      default: [],
      doc: "List of %`AbsintheGenerator.Schema.DataSource`{}"
    ],

    pre_middleware: [
      type: {:list, :keyword_list},
      default: [],
      doc: "List of %`AbsintheGenerator.Schema.Middleware`{}"
    ],

    post_middleware: [
      type: {:list, :keyword_list},
      default: [],
      doc: "List of %`AbsintheGenerator.Schema.Middleware`{}"
    ]
  ]

  @moduledoc """
  We can utilize this module to generate resolver files which
  are then used in the mutations/queries/subscriptions

  ### Definitions
  #{NimbleOptions.docs(@definition)}
  """

  @enforce_keys [:app_name]
  defstruct [
    :app_name,
    :moduledoc,
    pre_middleware: [],
    post_middleware: [],
    queries: [],
    mutations: [],
    subscriptions: [],
    data_sources: [],
    types: []
  ]

  defmodule DataSource do
    @enforce_keys [:source, :query]
    defstruct @enforce_keys

    @type t :: %AbsintheGenerator.Schema.DataSource{
      source: String.t,
      query: String.t
    }
  end

  defmodule Middleware do
    @enforce_keys [:module, :types]
    defstruct @enforce_keys

    @type t :: %AbsintheGenerator.Schema.Middleware{
      module: String.t,
      types: :all | list(:mutation | :query | :subscription)
    }
  end

  @type t :: %__MODULE__{
    app_name: String.t,
    pre_middleware: list(String.t),
    post_middleware: list(String.t),
    queries: list(String.t),
    mutations: list(String.t),
    subscriptions: list(String.t),
    types: list(String.t),
    data_sources: list(DataSource.t),
  }

  def run(%AbsintheGenerator.Schema{
    data_sources: data_sources,
    pre_middleware: pre_middleware,
    post_middleware: post_middleware,
  } = schema_struct) do
    AbsintheGenerator.ensure_list_of_structs(data_sources, AbsintheGenerator.Schema.DataSource, "data sources")
    AbsintheGenerator.ensure_list_of_structs(pre_middleware, AbsintheGenerator.Schema.Middleware, "pre middleware")
    AbsintheGenerator.ensure_list_of_structs(post_middleware, AbsintheGenerator.Schema.Middleware, "post middleware")

    schema_struct
      |> AbsintheGenerator.serialize_struct_to_config
      |> NimbleOptions.validate!(@definition)

    assigns = schema_struct
      |> Map.from_struct
      |> Map.put(:middleware, serialize_middleware_assigns(pre_middleware, post_middleware))
      |> Map.to_list

    "absinthe_schema"
      |> AbsintheGenerator.template_path
      |> AbsintheGenerator.evaluate_template(assigns)
  end

  defp serialize_middleware_assigns(_pre_middleware, _post_middleware) do
    %{
      everything: [],
      subscription: [],
      mutation: [],
      query: []
    }
  end
end
