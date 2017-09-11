#!/bin/bash

CARGO_CMD=$(which cargo)
RUSTC_CMD=$(which rustc)
CARGO_SOURCE_LINE='source $HOME/.cargo/env'

command_exists() {
  type "$1" &> /dev/null ;
}

build() {
  echo ""
  echo "cargo: $CARGO_CMD"
  echo "rustc: $RUSTC_CMD"
  echo ""

  if ! command_exists $RUSTC_CMD
  then
    echo "Rust is not installed..."
    exit 1
  fi

  $CARGO_CMD build --release
}

ensure_cargo_sourced() {
  FILE=~/.bash_profile
  grep -q "$CARGO_SOURCE_LINE" "$FILE" || echo "$CARGO_SOURCE_LINE" >> "$FILE"
}

if ! type $RUSTC_CMD > /dev/null; then
  echo "rustc is missing. rustup will be installed to provide rustc..."

  curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain nightly -y

  ensure_cargo_sourced
else
  echo "rustc exists..."
fi

build
