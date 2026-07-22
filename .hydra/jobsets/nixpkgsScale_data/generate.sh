#!/usr/bin/env bash
nix eval --file ./expr.nix --json --inputs-from ../../.. > data.json
