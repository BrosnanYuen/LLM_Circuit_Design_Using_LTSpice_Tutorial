# EDAsyth

Ubuntu 26.04 container with KiCad, Wine, LTspice and two MCP servers for
electronics design workflows:

- `symbolic_math_mcp` — symbolic math proof verification (`check_symbolic_math`, `check_symbolic_math_parallel`)
- `bltspice_mcp` — LTspice simulation and schematic conversion (`execute`, `execute_status`, `runtime_info`, `stop_reset`)

Everything is installed from official channels:

| Component | Source |
| --- | --- |
| KiCad 10 | official KiCad PPA (`ppa:kicad/kicad-10.0-releases`) |
| Wine 11 | official WineHQ repository (`dl.winehq.org/wine-builds`) |
| LTspice 24 | official Analog Devices MSI (`ltspice.analog.com/download/latest/LTspice64.msi`) |
| Python 3.14 | Ubuntu archive |

The MCP servers are cloned at build time from
`github.com/BrosnanYuen/symbolic_math_mcp` and `github.com/BrosnanYuen/bltspice_mcp`
and installed into isolated virtualenvs under `/opt/mcp`.

## Build

```bash
docker build -t edasyth .
```

Build arguments (optional): `SYMBOLIC_MATH_MCP_REPO`, `SYMBOLIC_MATH_MCP_REF`,
`BLTSPICE_MCP_REPO`, `BLTSPICE_MCP_REF`, `LTSPICE_URL`, `KICAD_PPA`,
`WINEHQ_KEY`, `WINEHQ_SOURCES`.

## Run

Shared HTTP server (recommended for harnesses that connect over HTTP):

```bash
docker run -d --name edasyth --restart unless-stopped \
  -p 8753:8753 -p 7543:7543 \
  -v /path/to/workspace:/path/to/workspace \
  edasyth
```

Endpoints:

- `symbolic_math_mcp`: `http://localhost:8753/mcp`
- `bltspice_mcp`: `http://localhost:7543/`

Stdio servers (harness spawns the container per session):

```bash
docker run -i --rm -v /path/to/workspace:/path/to/workspace edasyth symbolic-math-mcp
docker run -i --rm -v /path/to/workspace:/path/to/workspace edasyth bltspice-mcp
```

Mount the workspace at the same path so the agent can pass host file paths
(netlists, `.yaml`, `.kicad_sch`) to the tools.

## Ports

Defaults are `8753` (symbolic math) and `7543` (bltspice). Override with:

```bash
-e SYMBOLIC_MATH_MCP_PORT=18753 -e BLTSPICE_MCP_PORT=17543
```

and map the same ports with `-p`. The entrypoint fails fast if a port is
already in use instead of silently picking another one.

## Configuration

At container start the entrypoint renders configs for both servers from
environment variables:

| Variable | Default |
| --- | --- |
| `SYMBOLIC_MATH_MCP_PORT` | `8753` |
| `BLTSPICE_MCP_PORT` | `7543` |
| `MCP_BIND_HOST` | `0.0.0.0` |
| `SYMBOLIC_MATH_MCP_MAX_REQUESTS` | `24` |
| `SYMBOLIC_MATH_MCP_TOTAL_TIMEOUT` | `6000` |
| `BLTSPICE_TIMEOUT` | `600` |
| `WINEPREFIX` | `/opt/wineprefix` |
| `LTSPICEFOLDER` | `$WINEPREFIX/drive_c/ADI/LTspice` |
| `KICAD_SHARE` | `/usr/share/kicad/` |

Rendered files: `/opt/mcp/symbolic_math_mcp/config.{http,stdio}.json` and
`/opt/mcp/bltspice_mcp/config.{http,stdio}.json`.

## opencode

Global config (`~/.config/opencode/opencode.json`):

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "symbolic_math_mcp": {
      "type": "remote",
      "url": "http://localhost:8753/mcp",
      "timeout": 3600000,
      "enabled": true
    },
    "bltspice_mcp": {
      "type": "remote",
      "url": "http://localhost:7543/",
      "timeout": 3600000,
      "enabled": true
    }
  }
}
```

Restart opencode after changing config. Other harnesses (Claude Code, Codex,
etc.) use the same URLs or the stdio commands above.

## Layout

```
Dockerfile           image definition
entrypoint.sh        renders configs, starts Xvfb and the servers
install-ltspice.sh   silent LTspice MSI install plus probe simulation
```

## Notes

- LTspice runs under Wine with a virtual X display (`Xvfb`) started by the entrypoint.
- LTspice user libraries are extracted to
  `$WINEPREFIX/drive_c/users/root/AppData/Local/LTspice/lib` during the build.
- `electronics-design` is installed without its declared `kicad-tools[all]`
  extra (which pulls CUDA/torch); only the dependencies actually used by the
  exposed conversion APIs are installed.
