FROM ubuntu:26.04

ARG DEBIAN_FRONTEND=noninteractive
ARG KICAD_PPA=ppa:kicad/kicad-10.0-releases
ARG WINEHQ_KEY=https://dl.winehq.org/wine-builds/winehq.key
ARG WINEHQ_SOURCES=https://dl.winehq.org/wine-builds/ubuntu/dists/resolute/winehq-resolute.sources
ARG LTSPICE_URL=https://ltspice.analog.com/download/latest/LTspice64.msi
ARG SYMBOLIC_MATH_MCP_REPO=https://github.com/BrosnanYuen/symbolic_math_mcp.git
ARG SYMBOLIC_MATH_MCP_REF=main
ARG BLTSPICE_MCP_REPO=https://github.com/BrosnanYuen/bltspice_mcp.git
ARG BLTSPICE_MCP_REF=main

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    MCP_HOME=/opt/mcp \
    SYMBOLIC_MATH_MCP_DIR=/opt/mcp/symbolic_math_mcp \
    BLTSPICE_MCP_DIR=/opt/mcp/bltspice_mcp \
    SYMBOLIC_MATH_MCP_PORT=8753 \
    BLTSPICE_MCP_PORT=7543 \
    MCP_BIND_HOST=0.0.0.0 \
    WINEPREFIX=/opt/wineprefix \
    WINEARCH=win64 \
    WINEDEBUG=-all \
    WINEDLLOVERRIDES=mscoree,mshtml= \
    WINEFOLDER=/opt/wineprefix \
    WINEEXECUTABLE=wine \
    LTSPICEFOLDER=/opt/wineprefix/drive_c/ADI/LTspice \
    LTSPICEEXECUTABLE=LTspice.exe \
    KICAD_SHARE=/usr/share/kicad/ \
    PATH=/opt/mcp/symbolic_math_mcp/.venv/bin:/opt/mcp/bltspice_mcp/.venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      gnupg \
      git \
      software-properties-common \
      xvfb \
      xauth \
      python3 \
      python3-venv \
      python3-pip \
 && rm -rf /var/lib/apt/lists/*

RUN add-apt-repository -y "$KICAD_PPA" \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      kicad \
      kicad-symbols \
      kicad-footprints \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -pm755 /etc/apt/keyrings \
 && curl -fsSL "$WINEHQ_KEY" | gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key \
 && curl -fsSL -o /etc/apt/sources.list.d/winehq-resolute.sources "$WINEHQ_SOURCES" \
 && apt-get update \
 && apt-get install -y --install-recommends winehq-stable \
 && rm -rf /var/lib/apt/lists/*

COPY install-ltspice.sh /opt/mcp/install-ltspice.sh
RUN chmod +x /opt/mcp/install-ltspice.sh \
 && /opt/mcp/install-ltspice.sh "$LTSPICE_URL"

RUN git clone --depth 1 --branch "$SYMBOLIC_MATH_MCP_REF" "$SYMBOLIC_MATH_MCP_REPO" "$SYMBOLIC_MATH_MCP_DIR" \
 && python3 -m venv "$SYMBOLIC_MATH_MCP_DIR/.venv" \
 && "$SYMBOLIC_MATH_MCP_DIR/.venv/bin/pip" install --upgrade pip \
 && "$SYMBOLIC_MATH_MCP_DIR/.venv/bin/pip" install -e "$SYMBOLIC_MATH_MCP_DIR"

RUN git clone --depth 1 --branch "$BLTSPICE_MCP_REF" "$BLTSPICE_MCP_REPO" "$BLTSPICE_MCP_DIR" \
 && python3 -m venv "$BLTSPICE_MCP_DIR/.venv" \
 && "$BLTSPICE_MCP_DIR/.venv/bin/pip" install --upgrade pip \
 && "$BLTSPICE_MCP_DIR/.venv/bin/pip" install \
      "PyLTSpice>=6.0.1" \
      "fastmcp==2.14.7" \
      "psutil>=7.2.2" \
      "numba>=0.67.0" \
      "networkx>=3.6.1" \
      "numpy>=2.5.3" \
      "Pillow>=12.3.0" \
      "kicad-tools>=0.20.0" \
 && "$BLTSPICE_MCP_DIR/.venv/bin/pip" install --no-deps "electronics-design>=0.2.3" \
 && "$BLTSPICE_MCP_DIR/.venv/bin/pip" install --no-deps -e "$BLTSPICE_MCP_DIR"

RUN apt-get update \
 && apt-get install -y --no-install-recommends python3-tk \
 && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /opt/mcp/entrypoint.sh
RUN chmod +x /opt/mcp/entrypoint.sh \
 && printf '#!/bin/sh\nexec /opt/mcp/entrypoint.sh symbolic-math-mcp "$@"\n' > /usr/local/bin/symbolic-math-mcp \
 && printf '#!/bin/sh\nexec /opt/mcp/entrypoint.sh bltspice-mcp "$@"\n' > /usr/local/bin/bltspice-mcp \
 && printf '#!/bin/sh\nexec /opt/mcp/entrypoint.sh serve "$@"\n' > /usr/local/bin/mcp-serve \
 && chmod +x /usr/local/bin/symbolic-math-mcp /usr/local/bin/bltspice-mcp /usr/local/bin/mcp-serve

EXPOSE 8753 7543

WORKDIR /opt/mcp

ENTRYPOINT ["/opt/mcp/entrypoint.sh"]
CMD ["serve"]
