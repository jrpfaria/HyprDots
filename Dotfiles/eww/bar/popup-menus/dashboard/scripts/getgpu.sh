#!/usr/bin/env sh
amdgpu_top -gm | grep -m1 "average_gfx_activity" | awk -F': ' '{print $2}' | tr -d ','