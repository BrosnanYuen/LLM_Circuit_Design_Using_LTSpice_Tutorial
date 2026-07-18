# Why the ltspice_mcp_execute Tool Calls Fails

The root cause was the `string` attribute on the `<parameter>` XML tag used in tool calls.

## Failed Calls

In the early calls, the `inputs` parameter was provided with `string="true"`:

```xml
<parameter name="inputs" string="true">{"new_object_name": "bp_net", "netlist_file": "/path/to/circuit.net"}</parameter>
```

This caused the JSON object value to be **serialized as a JSON string** before being sent to the MCP server. The MCP server then received `inputs` as the string `'{"new_object_name": "bp_net", ...}'` instead of a proper dict/object. Hence the error:

```
Input should be a valid dictionary [type=dict_type, input_value='{"...":"..."}', input_type=str]
```

## Working Calls

The latter calls correctly used `string="false"` for `inputs`:

```xml
<parameter name="inputs" string="false">{"netlist_file":"...","new_object_name":"bp_sim"}</parameter>
```

With `string="false"`, the value is passed as its **native JSON type** (an object/dict) instead of being stringified. The MCP server receives it as a proper dictionary matching the `type: object` schema definition, and the call succeeds.

## Summary

| Parameter Type | `string` Attribute | What Happens |
|:-|:-|:-|
| `string` (like `api_name`) | `string="true"` | Passed as string — correct |
| `object` (like `inputs`) | `string="true"` | Passed as JSON string — WRONG |
| `object` (like `inputs`) | `string="false"` | Passed as native dict/object — correct |
