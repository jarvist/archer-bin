#!/bin/sh

# Jarv's May 2023 recreation of an rsync-from-HPC backup script

# regen this everytime to keep things consistent
cat > .exclude.tmp << EOF
# HPC / package cruft
- miniconda3/
- .julia/
- .config/
- .cache/
- .local/
- .vscode/
- julia*/
- .nv/
- NOTBACKEDUP/
- spack/
- .spack/

# Exclude Core Dump Files
core
core.*
EOF

rsync --exclude-from .exclude.tmp -av archer2:/home/e05/e05/jarvist/ ./archer2-e05-home-jarvist
rsync --exclude-from .exclude.tmp -av archer2:/work/e05/e05/jarvist/ ./archer2-e05-work-jarvist


